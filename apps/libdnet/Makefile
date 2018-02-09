SRCDIR = libdnet-master

target = dnet
exec_target = libdnet.manifest

level = ../../
include ../../Makefile

confflags = --prefix=$(abspath .)/install
 
master.zip:
	wget https://github.com/jncornett/libdnet/archive/master.zip

$(SRCDIR)/configure: master.zip
	unzip -u master.zip
	
libdnet.so: $(SRCDIR)/configure
	cd $(SRCDIR) && ./configure $(confflags)
	cd $(SRCDIR) && make -j 8 install
	cp -a install/lib/$@* ./

dnet: libdnet.so
	cp install/sbin/$@ ./

distclean: clean
	rm -rf $(SRCDIR) libdnet.manifest.sgx master.zip libdnet.so* dnet install
