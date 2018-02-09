#!/bin/bash

### Vanilla Snort build
### (TODO: LibDAQ refuses to build with manual installation of libpcap, so we work-around by installing from Ubuntu repo and ln real libpcap)

# dependencies for LibDAQ
sudo apt install flex
sudo apt install bison
sudo apt install libpcap-dev

# dependencies for hwloc
sudo apt install autoconf
sudo apt install libtool

# get libpcap dependency for LibDAQ
git clone https://github.com/the-tcpdump-group/libpcap.git
cd libpcap
./configure --prefix=$HOME/code/libpcap/install
make -j 8 install
cd install/lib/
ln -s libpcap.so.1 libpcap.so.0.8  # TODO: workaround for Ubuntu-related libpcap bug

# get LibDAQ dependency
wget -qO- https://www.snort.org/downloads/snortplus/daq-2.2.1.tar.gz | tar xvz
cd daq-2.2.1/
./configure --prefix=$HOME/code/daq-2.2.1/install
## FOR OUR daq-2.2.1 add: --with-dpdk-includes=$RTE_SDK/x86_64-native-linuxapp-gcc/include --with-dpdk-libraries=$RTE_SDK/x86_64-native-linuxapp-gcc/lib
make install

# get libdnet dependency (NOTE: original link to dugsong contains bug, see https://github.com/snortadmin/snort3/issues/7)
git clone https://github.com/jncornett/libdnet.git
cd libdnet
./configure --prefix=$HOME/code/libdnet/install
make -j 8 install

# get hwloc dependency (NOTE: cannot change default install path)
git clone https://github.com/open-mpi/hwloc.git
cd hwloc
./autogen.sh
./configure
sudo make -j 8 install

# get LuaJIT dependency
git clone http://luajit.org/git/luajit-2.0.git
cd luajit-2.0
make -j 8 install PREFIX=$HOME/code/luajit-2.0/install

# get OpenSSL dependency
git clone https://github.com/openssl/openssl.git
cd openssl
./config --prefix=$HOME/code/openssl/install --openssldir=$HOME/code/openssl/install
make -j 8 test
make install

# get PCRE dependency
wget -qO- https://ftp.pcre.org/pub/pcre/pcre-8.41.tar.gz | tar xvz
cd pcre-8.41
./configure --prefix=$HOME/code/pcre-8.41/install
make -j 8 install

# get zlib dependency (NOTE: cannot change default install path)
wget -qO- http://zlib.net/zlib-1.2.11.tar.gz | tar xvz
cd zlib-1.2.11
./configure
make -j 8 
sudo make install

# build Snort3
git clone https://github.com/snortadmin/snort3.git
cd snort3
export my_path=$HOME/code/snort3/install
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/code/libpcap/install/lib:$HOME/code/daq-2.2.1/install/lib:$HOME/code/libdnet/install/lib:$HOME/code/luajit-2.0/install/lib:$HOME/code/pcre-8.41/install/lib:$HOME/code/openssl/install/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/code/hwloc/hwloc/.libs:$HOME/code/zlib-1.2.11
PATH=$PATH:$HOME/code/daq-2.2.1/install/bin:$HOME/code/libdnet/install/bin:$HOME/code/luajit-2.0/install/bin:$HOME/code/libpcap/install/bin \
    OPENSSL_ROOT_DIR=$HOME/code/openssl/install \
    ./configure_cmake.sh \
    --prefix=$my_path \
    --with-pcap-includes=$HOME/code/libpcap/install/include --with-pcap-libraries=$HOME/code/libpcap/install/lib \
    --with-daq-includes=$HOME/code/daq-2.2.1/install/include --with-daq-libraries=$HOME/code/daq-2.2.1/install/lib \
    --with-dnet-includes=$HOME/code/libdnet/install/include  --with-dnet-libraries=$HOME/code/libdnet/install/lib \
    --with-luajit-includes=$HOME/code/luajit-2.0/install/include/luajit-2.0 --with-luajit-libraries=$HOME/code/luajit-2.0/install/lib \
    --with-openssl=$HOME/code/openssl/install \
    --with-pcre-includes=$HOME/code/pcre-8.41/install/include --with-pcre-libraries=$HOME/code/pcre-8.41/install/lib \
    --enable-debug-msgs --enable-debug --enable-gdb
cd build
make -j 8 install

# build plugins (in extra/)
cd ../extra
export PKG_CONFIG_PATH=$my_path/lib/pkgconfig
./configure_cmake.sh --prefix=$my_path
cd build
make -j 8 install

# try our fresh build
export LUA_PATH=$my_path/include/snort/lua/\?.lua\;\;
export SNORT_LUA_PATH=$my_path/etc/snort/
$my_path/bin/snort --help  # this should output smth meaningful
$my_path/bin/snort -r ~/pcaps/messenger.pcap  # get this file from wireshark's samples first

# get some stats while snort is working
$my_path/bin/snort -r ~/pcaps/maccdc2012_00000.pcap -c /home/dimakuv/code/snort3/install/etc/snort/snort.lua -R /home/dimakuv/code/snort3/install/etc/snort/sample.rules &
cat /proc/`pgrep snort`/status | less

# read all PCAP files from ~/pcaps/ using two worker threads
$my_path/bin/snort --pcap-dir ~/pcaps/ -c $my_path/etc/snort/snort.lua -R $my_path/etc/snort/sample.rules -z 2

# read all PCAP files from ~/pcaps/ using two worker threads and outputting alerts using C++ alert_ex plugin
$my_path/bin/snort --pcap-dir ~/pcaps/ -c $my_path/etc/snort/snort.lua -R $my_path/etc/snort/sample.rules -z 2 --script-path $my_path/lib/snort_extra -A alert_ex

# full-throttle: strace while snort reads all PCAP files from ~/pcaps/ using two worker threads and outputting alerts using lualert plugin and stopping after 10 packets
strace -f $my_path/bin/snort --pcap-dir ~/pcaps/ -c $my_path/etc/snort/snort.lua -R $my_path/etc/snort/sample.rules --script-path $my_path/lib/snort_extra -A lualert -n 10 -z 2 2>&1 | tee strace.log

# tapping on network interfaces
# NOTE: we need to start as sudo to init eno1 in promisceous mode but then lower priviliges to non-root user dimakuv
#       also, -E preserve envvars like Lua paths but sanitizes LD_LIBRARY_PATH, so we explicitly add it
sudo -E LD_LIBRARY_PATH=$LD_LIBRARY_PATH $my_path/bin/snort -u dimakuv -c $my_path/etc/snort/snort.lua -i eno1

# the same as above, but with better output (separate files for threads and ignoring uninteresting syscalls)
sudo -E LD_LIBRARY_PATH=$LD_LIBRARY_PATH strace -ff -o strace -e 'trace=!mprotect,nanosleep' $my_path/bin/snort -u dimakuv -c $my_path/etc/snort/snort.lua -i eno1

# use ltrace instead of strace; only output libcalls to libpcap
sudo -E LD_LIBRARY_PATH=$LD_LIBRARY_PATH ltrace -f -o ltrace.log -l libpcap.so.1 $my_path/bin/snort -u dimakuv -c $my_path/etc/snort/snort.lua -i eno1
