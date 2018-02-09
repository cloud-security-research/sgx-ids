#!/bin/bash

THREADS=2         # at least two threads, one for DPDK, one for Snort
SLEEPDURATION=30
CONFIGFILE=
RULESFILE=
ALERT=

LOGFILE=/tmp/snort.log
SNORTVERSION="sgx"  # or "vanilla"

for i in "$@"; do
    case $i in
        -z=*|--zthreads=*)
            THREADS="${i#*=}"
            shift
            ;;
        -s=*|--sleep=*)
            SLEEPDURATION="${i#*=}"
            shift
            ;;
        -c=*|--config=*)
            CONFIGFILE="${i#*=}"
            shift
            ;;
        -R=*|--rules=*)
            RULESFILE="${i#*=}"
            shift
            ;;
        -A=*|--alert=*)
            ALERT="${i#*=}"
            shift
            ;;
        -l=*|--logfile=*)
            LOGFILE="${i#*=}"
            shift
            ;;
        -v=*|--version=*)
            SNORTVERSION="${i#*=}"
            shift
            ;;
        *)
            # unknown option
            ;;
    esac
done

SNORTCMD="-z $THREADS"
if [[ ! -z $CONFIGFILE ]]; then
    SNORTCMD="$SNORTCMD -c install/etc/snort/$CONFIGFILE"
fi
if [[ ! -z $RULESFILE ]]; then
    SNORTCMD="$SNORTCMD -R install/etc/snort/$RULESFILE"
fi
if [[ ! -z $ALERT ]]; then
    SNORTCMD="$SNORTCMD -A $ALERT"
fi

EXECRUN="-E LD_LIBRARY_PATH=../libdaq/install_untrusted/lib/ ./snort3.manifest.sgx"
EXECKILL="pal-Linux-SGX"
if [ "$SNORTVERSION" == "vanilla" ]; then
    EXECRUN="-E LD_LIBRARY_PATH=install_vanilla/deps install_vanilla/bin/snort"
    EXECKILL="snort"
fi

# prep phase, for sanity
sudo killall -q -9 pal-Linux-SGX || true
sudo killall -q -9 snort || true
sudo rm -f /var/run/.snrt_config || true

export LUA_PATH="`pwd`/install_vanilla/include/snort/lua/?.lua;"
export SNORT_LUA_PATH="install_vanilla/etc/snort/"

while true ; do
    sudo $EXECRUN --daq dpdk -i dpdk0 --daq-var dpdk_queues=1 --daq-var dpdk_args="-n 2 -l 1 -m 4096 --file-prefix snrt -b 0000:01:00.1 -b 0000:01:00.2 -b 0000:01:00.3" $SNORTCMD >$LOGFILE 2>&1 &
    sleep $SLEEPDURATION
    sudo killall -q $EXECKILL
    sleep 5

    if grep -q -e 'assert' -e 'Assertion' -e 'FATAL' -e 'Segmentation' -e 'segmentation' -e 'segfault' $LOGFILE; then  # sometimes Graphene/Snort break, retry
        sudo killall -q -9 $EXECKILL || true
        sudo rm -f /var/run/.snrt_config || true
        sleep 5
        continue
    fi

    for job in `jobs -p`; do
        wait $job
    done
    break
done  #infinite loop
