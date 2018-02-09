SRCDIR = daq-2.2.1

target = dummy2
exec_target = libdaq.manifest

level = ../../
include ../../Makefile

dpdkflags = --with-dpdk-includes=$(RTE_SDK)/x86_64-native-linuxapp-gcc/include --with-dpdk-libraries=$(RTE_SDK)/x86_64-native-linuxapp-gcc/lib
confflags = CFLAGS="-DIN_ENCLAVE -O3 -g" --prefix=$(abspath .)/install $(dpdkflags)
sedprepared=$(subst /,\/,$(abspath .))\/..\/libdaqdpdk-dummy

dummy2:
# get napatech LibDAQ dependency
	rm -rf $(SRCDIR) daq_dpdk_multiqueue
	git clone https://github.com/napatech/daq_dpdk_multiqueue.git
	git --git-dir=daq_dpdk_multiqueue/.git --work-tree=daq_dpdk_multiqueue/ reset --hard 7c40e02b2b98e6b0974daf13935b1bd71172b2b1
	mv daq_dpdk_multiqueue/$(SRCDIR) . && rm -rf daq_dpdk_multiqueue
	cd $(SRCDIR) && patch -p1 < ../daq-2.2.1_graphene_dpdk.patch && ./configure $(confflags)
	cd $(SRCDIR) && make install
	cd $(SRCDIR) && make distclean
	sed -i 's/-lpthread/-lpthread -L$(sedprepared) -ldaqdpdk/' install/bin/daq-modules-config
	touch dummy2

distclean: clean
	cd $(SRCDIR) && make distclean || true
	rm -rf libdaq.manifest.sgx dummy2 install daq-2.2.1/autom4te.cache
	rm -rf $(SRCDIR)
