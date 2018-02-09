#!/bin/bash

USER=root
SERVER=10.23.152.158
PKTGENPATH=/$USER/pktgen-3.4.0  # NOTE: version 3.4.2 doesn't work correctly with ssh!
PCAPSPATH=/$USER/pcaps
CONFIGFILE=test_start.lua  # dummy default
PCAPFILE=
KILL=

for i in "$@"; do
    case $i in
        -k=*|--kill=*)
            KILL="${i#*=}"
            shift
            ;;
        -u=*|--user=*)
            USER="${i#*=}"
            shift
            ;;
        -s=*|--server=*)
            SERVER="${i#*=}"
            shift
            ;;
        -p=*|--pcap=*)
            PCAPFILE="${i#*=}"
            shift
            ;;
        -c=*|--config=*)
            CONFIGFILE="${i#*=}"
            shift
            ;;
        *)
            # unknown option
            ;;
    esac
done

if [[ ! -z $KILL ]]; then
    ssh -tq $USER@$SERVER "sudo killall -q pktgen"
    exit 0
fi

PKTGENCMD="sudo app/x86_64-native-linuxapp-gcc/pktgen -l 0-1 -n 2 --proc-type auto --log-level 7 -m 4096 --file-prefix pktgen -b 0000:01:00.1 -- -T -P -m 1.0 -f test/$CONFIGFILE"
if [[ ! -z $PCAPFILE ]]; then
    PKTGENCMD="$PKTGENCMD -s 0:$PCAPSPATH/$PCAPFILE"
fi

ssh -nf $USER@$SERVER "sh -c 'cd $PKTGENPATH; nohup $PKTGENCMD > /dev/null 2>&1 &'"
