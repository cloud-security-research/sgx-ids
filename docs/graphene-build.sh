#!/bin/bash

### Graphene-SGX build, based on https://github.com/oscarlab/graphene/wiki/SGX-Quick-Start

# dependencies
### NOTE: also clone and install linux-sgx-driver and linux-sgx beforehand!
sudo apt install python-protobuf python-crypto

# allow 0 address in Linux; required for running Graphene-SGX enclaves
sudo sysctl vm.mmap_min_addr=0

# build Graphene-SGX in parts (w/o modified Linux kernel and ignoring Reference Monitor)
git clone https://github.com/oscarlab/graphene.git
cd graphene
export my_path=`pwd`

git pull origin pull/58/head  # pull request for compatibility with new linux-sgx-driver
### NOTE: alternatively, we can apply a patch internally:
#           wget https://github.com/oscarlab/graphene/pull/58.patch
#           git apply --directory=graphene-snort 58.patch

cd $my_path/Pal/src/host/Linux-SGX/signer
openssl genrsa -3 -out enclave-key.pem 3072

cd $my_path/Pal/src
make SGX=1 DEBUG=1

cd $my_path/Pal/src/host/Linux-SGX/sgx-driver
make  # when prompted for Intel sgx driver directory, enter full path, e.g. "/home/dimakuv/01org/linux-sgx-driver"
sudo ./load.sh
ps -aux | grep aesmd  # double-check that aesmd is working
ls /dev/*sgx          # double-check that both Intel driver (isgx) and Graphene driver (gsgx) are working
dmesg | tail          # double-check drivers do not output any errors/warnings

cd $my_path/LibOS
make DEBUG=1  # NOTE: gawk and gcc spit out many warnings, ignore them all

# try our fresh build: HelloWorld example
cd $my_path/LibOS/shim/test/native
make SGX=1 DEBUG=1
make SGX_RUN=1
./pal_loader SGX helloworld          # should print smth meaningful
PERF=1 ./pal_loader SGX helloworld   # can do perf-stat for kicks
GDB=1 ./pal_loader SGX helloworld    # can GDB like crazy

# try our fresh build: Syscall microbenches
cd $my_path/LibOS/shim/test/apps/lmbench
make SGX=1 DEBUG=1  # NOTE: will give error because cannot find random files
cd lmbench-2.5/bin/linux/
head -c 64K < /dev/urandom > random.64K
head -c 256K < /dev/urandom > random.256K
head -c 1M < /dev/urandom > random.1M
head -c 4M < /dev/urandom > random.4M
head -c 16M < /dev/urandom > random.16M
cd ../../../
make SGX=1 DEBUG=1  # NOTE: now make is happy
make SGX_RUN=1
cd lmbench-2.5/bin/linux/
./pal_loader SGX lat_syscall null  # check pure Graphene-SGX framework overhead
./pal_loader SGX lat_syscall open  # check overhead of open() syscall
./pal_loader SGX lat_proc fork     # check overhead of fork() syscall (note `lat_proc`)

