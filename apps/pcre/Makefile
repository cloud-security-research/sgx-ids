SRCDIR = pcre-8.41

target = pcretest
exec_target = pcre.manifest

level = ../../
include ../../Makefile

confflags = --prefix=$(abspath .)/install
 
$(SRCDIR)/configure:
	wget -qO- https://ftp.pcre.org/pub/pcre/$(SRCDIR).tar.gz | tar xvz
	
libpcre.so: $(SRCDIR)/configure
	cd $(SRCDIR) && ./configure $(confflags)
	cd $(SRCDIR) && make -j 8 install
	cp -a ./install/lib/$@* ./

libpcreposix.so: libpcre.so
	cp -a ./install/lib/$@* ./

pcretest: libpcre.so libpcreposix.so
	cp ./install/bin/$@ ./

distclean: clean
	rm -rf $(SRCDIR) pcre.manifest.sgx libpcre.so* libpcreposix.so* pcretest install
