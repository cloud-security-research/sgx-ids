#!/bin/bash

SNORTVERSION="sgx"  # or "vanilla"
for i in "$@"; do
    case $i in
        -v=*|--version=*)
            SNORTVERSION="${i#*=}"
            shift
            ;;
        *)
            # unknown option
            ;;
    esac
done

declare -a times=(1 2 3)
declare -a zthreads=(2 3)
declare -a sleeps=(120)  # best values are 60-180

# config and pcap files for PktGen go together
declare -a pktgenconfigs=("snort_1024B/test_1024B_256F.lua" "snort_1024B/test_1024B_1KF.lua" "snort_1024B/test_1024B_4KF.lua" "snort_1024B/test_1024B_8KF.lua" "snort_1024B/test_1024B_16KF.lua" "snort_1024B/test_1024B_32KF.lua")
declare -a   pktgenpcaps=("" "" "" "" "" "")

# config, rules, and alers for Snort go together
declare -a snortconfigs=("snort.lua"              "snort.lua")
declare -a   snortrules=("community_3462.rules"   "community_3462.rules")
declare -a  snortalerts=(""                       "fast")

# prep phase, for sanity
./run_pktgen.sh -k="killpktgen" || true
sleep 5

logfile="exp-cpu-${SNORTVERSION}-`date --rfc-3339=date`.log"
echo "===== snort $logfile =====" | tee $logfile
echo "" | tee -a $logfile

total=$((${#times[@]} * ${#sleeps[@]} * ${#zthreads[@]} * ${#pktgenconfigs[@]} * ${#snortconfigs[@]}))
current=0

for time in "${times[@]}"; do
    for sl in "${sleeps[@]}"; do
        for zthread in "${zthreads[@]}"; do
            for pktgenidx in ${!pktgenconfigs[@]}; do
                for snortidx in ${!snortconfigs[@]}; do
                    current=$((current+1))
                    pktgenconfig=${pktgenconfigs[$pktgenidx]}
                    pktgenpcap=${pktgenpcaps[$pktgenidx]}

                    snortconfig=${snortconfigs[$snortidx]}
                    snortrule=${snortrules[$snortidx]}
                    snortalert=${snortalerts[$snortidx]}

                    settings="TIME=$time SLEEP=$sl ZTHREAD=$zthread PKTGENCONFIG=$pktgenconfig PKTGENPCAP=$pktgenpcap SNORTCONFIG=$snortconfig SNORTRULE=$snortrule SNORTALERT=$snortalert"
                    echo "EXPERIMENT_START $settings   ($current/$total)" | tee -a $logfile

                    ./run_pktgen.sh -c=$pktgenconfig -p=$pktgenpcap
                    sleep 10
                    top -bn1000 -p $(pgrep ksgxswapd) >> $logfile 2>&1 &
                    ./run_snort.sh -v=$SNORTVERSION -z=$zthread -s=$sl -c=$snortconfig -R=$snortrule -A=$snortalert -l=/tmp/snort.log
                    killall top
                    sleep 3
                    ./run_pktgen.sh -k="killpktgen"
                    sleep 3

                    echo "EXPERIMENT_END   $settings" | tee -a $logfile
                    echo "" | tee -a $logfile
                done  #snort
            done  #pktgen
        done  #zthreads
    done  #sleeps
done  #times

echo "DONE!"
