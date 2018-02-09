# NOTE: Build system of Snort3 thinks it needs hwloc even though we patch code
#       to remove any dependency; thus, be sure to install hwloc system-wide
#       and do not be surprised when the build mentions hwloc

# "master" for up-to-date version
SNORTVERSION =BUILD_239
SRCDIR = snort3-$(SNORTVERSION)

target = snort
exec_target = snort3.manifest

level = ../../
include ../../Makefile

INSTALLDIR=$(abspath .)/install
DEPDIR=$(abspath .)/..
pcapdir   =$(DEPDIR)/libpcap/install
daqdir    =$(DEPDIR)/libdaq/install
dnetdir   =$(DEPDIR)/libdnet/install
luajitdir =$(DEPDIR)/luajit/install
pcredir   =$(DEPDIR)/pcre/install
openssldir=$(DEPDIR)/openssl/install
libnumadir=$(DEPDIR)/libnuma-dummy
daqdpdkdir=$(DEPDIR)/libdaqdpdk-dummy

deplibs = $(addsuffix /lib, $(pcapdir) $(daqdir) $(dnetdir) $(luajitdir) $(pcredir) $(openssldir)) $(DEPDIR)/zlib $(libnumadir) $(daqdpdkdir)

confflags = --with-pcap-includes=$(pcapdir)/include  --with-pcap-libraries=$(pcapdir)/lib \
	--with-daq-includes=$(daqdir)/include  --with-daq-libraries=$(daqdir)/lib \
	--with-dnet-includes=$(dnetdir)/include  --with-dnet-libraries=$(dnetdir)/lib \
	--with-luajit-includes=$(luajitdir)/include/luajit-2.0  --with-luajit-libraries=$(luajitdir)/lib \
	--with-pcre-includes=$(pcredir)/include  --with-pcre-libraries=$(pcredir)/lib \
	--with-openssl=$(openssldir)

addpath = $(daqdir)/bin:$(dnetdir)/bin:$(luajitdir)/bin:$(pcapdir)/bin:$(PATH)
ldlibrarypath = $(pcapdir)/lib:$(daqdir)/lib:$(dnetdir)/lib:$(luajitdir)/lib:$(pcredir)/lib:$(openssldir)/lib:$(daqdpdkdir):$(LD_LIBRARY_PATH)
pkgconfigpath =$(INSTALLDIR)/lib/pkgconfig

$(SRCDIR)/configure_cmake.sh:
	wget -nc https://github.com/snortadmin/snort3/archive/$(SNORTVERSION).zip
	
$(INSTALLDIR)/lib: $(SRCDIR)/configure_cmake.sh
	unzip -u $(SNORTVERSION).zip
	cd $(SRCDIR) && patch -s -t -N -r - -p1 < ../snort3-nohwloc.patch | true
	cd $(SRCDIR) && PATH=$(addpath) ./configure_cmake.sh --prefix=$(INSTALLDIR) $(confflags)
	cd $(SRCDIR)/build && PATH=$(addpath) LD_LIBRARY_PATH=$(ldlibrarypath) make install

$(INSTALLDIR)/lib/snort_extra: $(INSTALLDIR)/lib
	cd $(SRCDIR)/extra && PATH=$(addpath) PKG_CONFIG_PATH=$(pkgconfigpath) ./configure_cmake.sh --prefix=$(INSTALLDIR)
	cd $(SRCDIR)/extra/build && PATH=$(addpath) LD_LIBRARY_PATH=$(ldlibrarypath) make install

snort: $(INSTALLDIR)/lib/snort_extra
	cp -a $(INSTALLDIR)/bin/$@ ./
	cp -a rules/*.rules $(INSTALLDIR)/etc/snort
	mkdir -p $(INSTALLDIR)/deps
	for deplib in $(deplibs) ; do \
        	cp -a $$deplib/*.so* $(INSTALLDIR)/deps ; \
    	done
	cd $(INSTALLDIR)/deps && ln -sf libpcap.so.1 libpcap.so.0.8 # TODO: workaround for Ubuntu-related libpcap bug

distclean: clean
	rm -rf $(SRCDIR) $(INSTALLDIR) snort3.manifest.sgx snort $(SNORTVERSION).zip*
