SRCDIR = zlib-1.2.11

target = examplesh
exec_target = zlib.manifest

level = ../../
include ../../Makefile

$(SRCDIR)/configure:
	wget -qO- http://zlib.net/$(SRCDIR).tar.gz | tar xvz
	
libz.so: $(SRCDIR)/configure
	cd $(SRCDIR) && ./configure
	cd $(SRCDIR) && make -j 8
	cp -a $(SRCDIR)/$@* ./

examplesh: libz.so
	cp $(SRCDIR)/$@ ./

distclean: clean
	rm -rf $(SRCDIR) zlib.manifest.sgx libz.so* examplesh foo.gz
