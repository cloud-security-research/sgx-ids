# top-level Makefile to build all dependencies of snort3 and then snort3 itself

SUBDIRS = libdaq libdnet libpcap luajit openssl pcre zlib libdaqdpdk-dummy libnuma-dummy snort3

all:
	for dir in $(SUBDIRS) ; do \
		make -C $$dir SGX=1 ; \
		make -C $$dir SGX_RUN=1 ; \
	done
	make -C snort3 -f Makefile.vanilla
deps:
	sudo apt-get install flex bison libpcap-dev autoconf libtool hwloc

clean:
	for dir in $(SUBDIRS) ; do \
		make -C $$dir distclean ; \
	done
	make -C snort3 -f Makefile.vanilla distclean

distclean: clean
