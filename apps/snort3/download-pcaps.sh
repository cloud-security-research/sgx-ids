#!/bin/bash

# downloading three pcaps from http://tcpreplay.appneta.com/wiki/captures.html

wget -nc https://s3.amazonaws.com/tcpreplay-pcap-files/test.pcap
wget -nc https://s3.amazonaws.com/tcpreplay-pcap-files/bigFlows.pcap
wget -nc https://s3.amazonaws.com/tcpreplay-pcap-files/smallFlows.pcap
mv *.pcap pcaps/ | true
