libdaqdpdk.so.1: libdaqdpdk.c
	gcc -fPIC -shared -Wl,-soname,libdaqdpdk.so.1 -o $@ $^
	ln -s libdaqdpdk.so.1 libdaqdpdk.so

clean:
	rm -rf libdaqdpdk.so*

distclean: clean
