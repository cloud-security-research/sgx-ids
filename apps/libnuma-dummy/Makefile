libnuma.so.1: libnuma.c
	gcc -fPIC -shared -Wl,-soname,libnuma.so.1 -o $@ $^
	ln -s libnuma.so.1 libnuma.so

clean:
	rm -rf libnuma.so*

distclean: clean
