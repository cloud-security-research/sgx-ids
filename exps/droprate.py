import sys

filename = ''
if len(sys.argv) > 1:
    filename = sys.argv[1]
else:
    sys.exit('Please specify full log filename as first argument!')

s = open(filename).readlines()
formatted = ''
prev_total   = 0
prev_dropped = 0
curr_total   = 0
curr_dropped = 0
seconds      = 0
for i, line in enumerate(s):
    if 'dpdk stats' in line:
        if 'rx_total_packets'     in line:
            curr_total = int(line.split(':')[-1])
        if 'rx_priority0_dropped' in line:
            curr_dropped = int(line.split(':')[-1])
            formatted += str(seconds) + ': ' + str(curr_dropped-prev_dropped) + '/' + str(curr_total-prev_total) + '  =  ' + "{0:.2f}".format((curr_dropped-prev_dropped)*100.0/(curr_total-prev_total)) + '%\n'
            prev_total   = curr_total
            prev_dropped = curr_dropped
            seconds += 1
      
print(formatted)
