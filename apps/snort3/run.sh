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

declare -a times=(3)
declare -a zthreads=(2 3)
declare -a sleeps=(120)  # best values are 60-180

# config and pcap files for PktGen go together
declare -a pktgenconfigs=("snort_64B/test_64B_256F.lua" "snort_64B/test_64B_1KF.lua" "snort_64B/test_64B_4KF.lua" "snort_64B/test_64B_8KF.lua" "snort_64B/test_64B_16KF.lua" "snort_64B/test_64B_32KF.lua" \
    "snort_128B/test_128B_256F.lua" "snort_128B/test_128B_1KF.lua" "snort_128B/test_128B_4KF.lua" "snort_128B/test_128B_8KF.lua" "snort_128B/test_128B_16KF.lua" "snort_128B/test_128B_32KF.lua" \
    "snort_256B/test_256B_256F.lua" "snort_256B/test_256B_1KF.lua" "snort_256B/test_256B_4KF.lua" "snort_256B/test_256B_8KF.lua" "snort_256B/test_256B_16KF.lua" "snort_256B/test_256B_32KF.lua" \
    "snort_512B/test_512B_256F.lua" "snort_512B/test_512B_1KF.lua" "snort_512B/test_512B_4KF.lua" "snort_512B/test_512B_8KF.lua" "snort_512B/test_512B_16KF.lua" "snort_512B/test_512B_32KF.lua" \
    "snort_1024B/test_1024B_256F.lua" "snort_1024B/test_1024B_1KF.lua" "snort_1024B/test_1024B_4KF.lua" "snort_1024B/test_1024B_8KF.lua" "snort_1024B/test_1024B_16KF.lua" "snort_1024B/test_1024B_32KF.lua" \
    "test_start.lua" "test_start.lua" "test_start.lua")
declare -a   pktgenpcaps=("" "" "" "" "" "" \
    "" "" "" "" "" "" \
    "" "" "" "" "" "" \
    "" "" "" "" "" "" \
    "" "" "" "" "" "" \
    "test.pcap" "smallFlows.pcap" "bigFlows.pcap")

# config, rules, and alers for Snort go together
declare -a snortconfigs=("" "snort.lua" "snort.lua"         "snort.lua"          "snort.lua"           "snort.lua"            "snort.lua"              "snort.lua")
declare -a   snortrules=("" ""          "community_1.rules" "community_10.rules" "community_100.rules" "community_1000.rules" "community_3462.rules"   "community_3462.rules")
declare -a  snortalerts=("" ""          ""                  ""                   ""                    ""                     ""                       "fast")

# prep phase, for sanity
./run_pktgen.sh -k="killpktgen" || true
sleep 5

logfile="exp-${SNORTVERSION}-`date --rfc-3339=date`.log"
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
                    ./run_snort.sh -v=$SNORTVERSION -z=$zthread -s=$sl -c=$snortconfig -R=$snortrule -A=$snortalert -l=/tmp/snort.log
                    sleep 3
                    ./run_pktgen.sh -k="killpktgen"
                    sleep 3

                    sed -i '/^trusted:/d' /tmp/snort.log
                    sed -i '/^allowed:/d' /tmp/snort.log
                    sed -i '/^EAL:/d' /tmp/snort.log
                    sed -i '/^adding pages to enclave:/d' /tmp/snort.log
                    sed -i '/^manifest file:/d' /tmp/snort.log
                    sed -i '/^enclave created:/d' /tmp/snort.log
                    sed -i '/^    base:/d' /tmp/snort.log
                    sed -i '/^    size:/d' /tmp/snort.log
                    sed -i '/^    attr:/d' /tmp/snort.log
                    sed -i '/^    xfrm:/d' /tmp/snort.log
                    sed -i '/^    ssaframesize:/d' /tmp/snort.log
                    sed -i '/^    isvprodid:/d' /tmp/snort.log
                    sed -i '/^    isvsvn:/d' /tmp/snort.log
                    sed -i '/^enclave initializing:/d' /tmp/snort.log
                    sed -i '/^    enclave id:/d' /tmp/snort.log
                    sed -i '/^    enclave hash:/d' /tmp/snort.log
                    sed -i '/^Get sealing key:/d' /tmp/snort.log
                    sed -i '/^enclave (software) key hash:/d' /tmp/snort.log
                    sed -i '/^file:/d' /tmp/snort.log
                    sed -i '/^PMD:/d' /tmp/snort.log
                    sed -i '/dpdk stats/! {/\[\*\*\]/d}' /tmp/snort.log  # rm `-A fast` output
                    cat /tmp/snort.log >> $logfile

                    echo "EXPERIMENT_END   $settings" | tee -a $logfile
                    echo "" | tee -a $logfile
                done  #snort
            done  #pktgen
        done  #zthreads
    done  #sleeps
done  #times

echo "DONE!"
