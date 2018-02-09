SRCDIR = openssl-master

target = openssl
exec_target = openssl.manifest

level = ../../
include ../../Makefile

confflags = --prefix=$(abspath .)/install --openssldir=$(abspath .)/install
 
master.zip:
	wget https://github.com/openssl/openssl/archive/master.zip

$(SRCDIR)/config: master.zip
	unzip -u master.zip

libcrypto.so: $(SRCDIR)/config
	cd $(SRCDIR) && ./config $(confflags)
	cd $(SRCDIR) && make -j 8
	cd $(SRCDIR) && make install
	cp -a ./install/lib/$@* ./

libssl.so: libcrypto.so
	cp -a ./install/lib/$@* ./

openssl: libcrypto.so libssl.so
	cp ./install/bin/$@ ./

distclean: clean
	rm -rf $(SRCDIR) openssl.manifest.sgx master.zip libcrypto.so* libssl.so* openssl install
