SRCDIR = libpcap-master

target = filtertest
exec_target = libpcap.manifest

level = ../../
include ../../Makefile

confflags = --prefix=$(abspath .)/install
 
master.zip:
	wget https://github.com/the-tcpdump-group/libpcap/archive/master.zip

$(SRCDIR)/configure: master.zip
	unzip -u master.zip
	
libpcap.so: $(SRCDIR)/configure
	cd $(SRCDIR) && ./configure $(confflags)
	cd $(SRCDIR) && make -j 8 install
	cd $(SRCDIR) && make -j 8 tests
	cp -a install/lib/$@* ./

filtertest: libpcap.so
	cp $(SRCDIR)/$@ ./

distclean: clean
	rm -rf $(SRCDIR) libpcap.manifest.sgx master.zip libpcap.so* filtertest install

run:
	./libpcap.manifest.sgx -F example.txt 0
