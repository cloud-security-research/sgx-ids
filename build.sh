#!/usr/bin/env bash

set -x
set -e

apt-get update -y

apt-get install -y --no-install-recommends make gcc build-essential ocaml automake autoconf libtool wget python libssl-dev libcurl4-openssl-dev protobuf-compiler libprotobuf-dev libnuma-dev  python-protobuf python-crypto flex bison libpcap-dev unzip cmake hwloc libhwloc-dev pkg-config git linux-tools-common linux-tools-`uname -r` linux-headers-generic

if [ ! -d /opt/intel/sgxsdk ] ; then
    wget https://download.01.org/intel-sgx/linux-2.0/sgx_linux_ubuntu16.04.1_x64_sdk_2.0.100.40950.bin
    printf 'no\n/opt/intel\n' | bash ./sgx_linux_ubuntu16.04.1_x64_sdk_2.0.100.40950.bin
fi

if [ ! -d /opt/intel/sgxpsw ] ; then
    wget https://download.01.org/intel-sgx/linux-2.0/sgx_linux_ubuntu16.04.1_x64_psw_2.0.100.40950.bin
    # The patch is necessary to allow the script to execute in a
    # container. The patch allows the script to run to completion
    # and install the necessary .so libraries.
    patch -p0 sgx_linux_ubuntu16.04.1_x64_psw_2.0.100.40950.bin <<EOF
43c43
<             exit 4
---
>             #exit 4
EOF
    yes no /opt/intel | bash ./sgx_linux_ubuntu16.04.1_x64_psw_2.0.100.40950.bin
fi

if [ ! -d dpdk ] ; then
    wget -qO- https://fast.dpdk.org/rel/dpdk-17.08.tar.gz | tar zxv
    mv dpdk-17.08 dpdk
    pushd dpdk
    make install T=x86_64-native-linuxapp-gcc DESTDIR=install EXTRA_CFLAGS="-fPIC"
    export RTE_SDK=$(readlink -f .)
    export RTE_TARGET=x86_64-native-linuxapp-gcc
    # cd tools && sudo ./dpdk-setup.sh  # choose "[17] Insert VFIO module"; then "[23] Bind Ethernet/Crypto device to VFIO module" for all required network interfaces; then "[24] Setup VFIO permissions"
    popd
fi

### 1. Install linux-sgx-driver
if [ ! -d linux-sgx-driver ] ; then
	git clone https://github.com/01org/linux-sgx-driver && pushd linux-sgx-driver
	make
	sudo mkdir -p "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"          # the following commands are from linux-sgx-driver README
	sudo cp isgx.ko "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"
	sudo sh -c "cat /etc/modules | grep -Fxq isgx || echo isgx >> /etc/modules"
	sudo /sbin/depmod
	sudo service aesmd stop
	lsmod | grep graphene_sgx &&  rmmod graphene_sgx
	sudo /sbin/modprobe -r isgx
	sudo /sbin/modprobe isgx
	sudo service aesmd start 
	popd
fi
	

# How to handle timing thread? It's an ugly and brittle hack. Some untrusted time interface bypassing the Library OS restrictions (i.e. shared memory?)


if [ ! -d graphene ] ; then
    git clone --recursive https://github.com/oscarlab/graphene.git
    pushd graphene
    git reset --hard 4d8eacdd44029af28887247ebeb11b3d3ac1f6df
    patch -p1 < ../misc/graphene-pull-request-58.patch || exit 1
    pushd Pal/src/host/Linux-SGX/sgx-driver/
    make
    ./load.sh
    popd
    patch -p2 < ../misc/graphene-01-mmap-map32bit.diff || exit 1
    patch -p2 < ../misc/graphene-02-unmap-tcs.diff || exit 1
    patch -p2 < ../misc/graphene-03-trustedclock-dpdkocalls.diff || exit 1
    sed -i -r 's/CPUFREQ [0-9]+\.[0-9]+/CPUFREQ 3785.0/' Pal/src/host/Linux-SGX/enclave_ocalls.c # Adjust CPUFREQ here based on CPU frequency
    openssl genrsa -3 -out Pal/src/host/Linux-SGX/signer/enclave-key.pem 3072
    export RTE_SDK=$(readlink -f ../dpdk)
    export RTE_TARGET=x86_64-native-linuxapp-gcc
    cp -a ../apps/* LibOS/shim/test/apps/
    make -C LibOS/shim/test/apps/libdaq -f Makefile.untrusted
    make clean && make SGX=1 
    make -C LibOS/shim/test/apps
fi

