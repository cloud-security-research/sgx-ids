package.path = package.path ..";?.lua;test/?.lua;app/?.lua;"

pktgen.range.dst_mac("0", "start", "3c:fd:fe:9c:5c:b8");
pktgen.range.src_mac("0", "start", "3c:fd:fe:9c:5c:d8");

-- modify only dst IP to have different TCP flows
pktgen.range.dst_ip("0", "start", "127.0.0.0");
pktgen.range.dst_ip("0", "inc", "0.0.0.1");
pktgen.range.dst_ip("0", "min", "127.0.0.0");
pktgen.range.dst_ip("0", "max", "127.0.63.255");

pktgen.range.src_ip("0", "start", "192.168.0.1");
pktgen.range.src_ip("0", "inc", "0.0.0.0");
pktgen.range.src_ip("0", "min", "192.168.0.1");
pktgen.range.src_ip("0", "max", "192.168.0.1");

pktgen.range.dst_port("0", "start", 2000);
pktgen.range.dst_port("0", "inc", 0);
pktgen.range.dst_port("0", "min", 2000);
pktgen.range.dst_port("0", "max", 2000);

pktgen.range.src_port("0", "start", 5000);
pktgen.range.src_port("0", "inc", 0);
pktgen.range.src_port("0", "min", 5000);
pktgen.range.src_port("0", "max", 5000);

pktgen.range.pkt_size("0", "start", 128);
pktgen.range.pkt_size("0", "inc", 0);
pktgen.range.pkt_size("0", "min", 64);
pktgen.range.pkt_size("0", "max", 32768);

pktgen.set_proto("all", "tcp");
pktgen.set_range("all", "on");

pktgen.start("all");
