import sys

filename = ''
if len(sys.argv) > 1:
    filename = sys.argv[1]
else:
    sys.exit('Please specify full log filename as first argument!')

variant = 'sgx'
if 'vanilla' in filename:
    variant = 'vanilla'

s = open(filename).readlines()
outfile= ['variant,time,sleep,zthread,pktgenconfig,pktgenpcap,snortconfig,snortrule,snortalert,rx_total_packets,rx_total_bytes,rx_priority0_dropped,daq_received,daq_analyzed,daq_allow,timing_seconds,timing_pps,pkt_size,num_flows,num_rules,variant_zthread']
formatted = ''
expdesc   = ''
for i, line in enumerate(s):
    if line.startswith('EXPERIMENT_START'):
        expdesc = line
        formatted  = variant + ','
        formatted += line.replace('EXPERIMENT_START', '').replace('TIME=','').replace('SLEEP=',',').replace('ZTHREAD=',',') \
            .replace('PKTGENCONFIG=',',').replace('PKTGENPCAP=',',').replace('SNORTCONFIG=',',').replace('SNORTRULE=',',') \
            .replace('SNORTALERT=',',').split('(')[0]
        continue

    if 'dpdk stats' in line:
        if 'rx_total_packets'     in line:   formatted += ',' + line.split(':')[-1]
        if 'rx_total_bytes'       in line:   formatted += ',' + line.split(':')[-1]
        if 'rx_priority0_dropped' in line:   formatted += ',' + line.split(':')[-1]
       
    if line.strip() == 'daq':
        assert 'received' in s[i+1] and 'analyzed' in s[i+2] and 'allow' in s[i+4]
        formatted += ',' + s[i+1].split(':')[-1] + ',' + s[i+2].split(':')[-1] + ',' + s[i+4].split(':')[-1]
    
    if line.strip() == 'timing':
        assert('seconds' in s[i+2] and 'pkts/sec' in s[i+4])
        formatted += ',' + s[i+2].split(':')[-1] + ',' + s[i+4].split(':')[-1]

    if line.startswith('EXPERIMENT_END'):
	# packet size and flows
        pkt_size = 0; num_flows = 0
	if formatted.split(',')[5].strip() == '':
	    pkt_size  = int( formatted.split(',')[4].split('/')[0].replace('snort_','').replace('B','') )
	    num_flows = formatted.split(',')[4].split('B_')[1].replace('F.lua','')
            if "K" in num_flows:
                num_flows = int( num_flows.replace('K','') ) * 1000
            else:
                num_flows = int (num_flows )
        elif formatted.split(',')[5].strip() == 'bigFlows.pcap':
	    pkt_size = 449; num_flows = 40686
        elif formatted.split(',')[5].strip() == 'smallFlows.pcap':
	    pkt_size = 646; num_flows = 1209
        elif formatted.split(',')[5].strip() == 'test.pcap':
	    pkt_size = 445; num_flows = 37

        # number of rules
        num_rules = 0
	if formatted.split(',')[7].strip() != '':
	    num_rules = int( formatted.split(',')[7].split('_')[1].split('.')[0] )

        # concatenate variable and zthread (for legend on barplot)
        varzthread = formatted.split(',')[0] + '-' + formatted.split(',')[3]

	formatted += ',' + str(pkt_size) + ',' + str(num_flows) + ',' + str(num_rules) + ',' + varzthread

        if outfile[0].count(',') != formatted.count(','):
            print(expdesc)
            sys.exit('Wrong number of statistics collected!')

        outfile.append(formatted.replace('\n','').replace(' ',''))
        continue

open(filename + '.csv', 'w').writelines(["%s\n" % item for item in outfile])
