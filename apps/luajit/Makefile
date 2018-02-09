SRCDIR = LuaJIT-master

target = luajit
exec_target = libluajit.manifest

level = ../../
include ../../Makefile

confflags = PREFIX=$(abspath .)/install
 
master.zip:
	wget https://github.com/LuaJIT/LuaJIT/archive/master.zip

$(SRCDIR)/README: master.zip
	unzip -u master.zip
	
libluajit-5.1.so: $(SRCDIR)/README
	cd $(SRCDIR) && make -j 8 install $(confflags)
	cp -a install/lib/$@* ./

luajit: libluajit-5.1.so
	cp install/bin/$@ ./

distclean: clean
	rm -rf $(SRCDIR) libluajit.manifest.sgx master.zip libluajit-5.1.so* luajit install
