# Snort Intrusion Detection System with Intel Software Guard Extension (Intel SGX)

> :warning: **DISCONTINUATION OF PROJECT** - *This project will no longer be maintained by Intel.  This project has been identified as having known security escapes.  Intel has ceased development and contributions including, but not limited to, maintenance, bug fixes, new releases, or updates, to this project.* **Intel no longer accepts patches to this project.**


This software is a research proof of concept and not intended for production use

Network Function Virtualization (NFV) promises the benefits of reduced infrastructure, personnel, and management costs by outsourcing network middleboxes to the public or private cloud. Unfortunately, running network functions in the cloud entails security challenges, especially for complex stateful services. , SEC-IDS is an research attempt to harden the king of middleboxes - Intrusion Detection Systems (IDS) - using Intel Software Guard Extensions (Intel SGX) technology. SEC-IDS, is an unmodified Snort 3 with a DPDK network layer that achieves line rate throughput. SEC-IDS achieves computational integrity by running all Snort code inside an Intel SGX enclave. At the same time, SEC-IDS achieves near-native performance, with throughput close to 100 percent of vanilla Snort 3, by retaining network I/O outside of the enclave. Our experiments indicate that performance is only constrained by the limited amount of  Enclave physical memory available on current Intel SGX Skylake based E3 Xeon platforms. Finally, we kept the porting effort minimal by using the Graphene-SGX library OS. Only 27 Lines of Code (LoC) were modified in Snort and 178 LoC in Graphene-SGX itself.


## How to run build and run SEC-IDS
	prerequsites : Intel SGX Enabled server platform with a DPDK compatible 10Gbps network controller

### Prepare the system first

Install Ubuntu 16.04 x86_64 on a SGX Enabled machine. Ensure Hyperthreading and Power state management is disabled in BIOS


Install dependencies and set appropriate kernel parameters for best performance

```
	sudo apt update && sudo apt upgrade
	sudo apt install make gcc build-essential ocaml automake autoconf libtool wget python libssl-dev libcurl4-openssl-dev protobuf-compiler libprotobuf-dev libnuma-dev  python-protobuf python-crypto flex bison libpcap-dev unzip cmake hwloc libhwloc-dev pkg-config
	sudo apt install htop linux-tools-common linux-tools-`uname -r`
	sudo systemctl enable ssh  # to persist ssh daemon across reboots
	sudo vim /etc/default/grub # change GRUB_CMDLINE_LINUX to GRUB_CMDLINE_LINUX="default_hugepagesz=1GB hugepagesz=1G hugepages=16 iommu=pt intel_iommu=on intel_idle.max_cstate=0 intel_pstate=disable"
sudo update-grub

```

Add the following line in /etc/security/limits.conf to permanently change available locked memory

```
	*                hard    memlock         20971520" and "*                soft    memlock         20971520"
```

Reboot the machine!

Once the machine comes up execute the following commands. Note: These commands need to be executed on every boot

```
	mkdir /mnt/huge
	mount -t hugetlbfs nodev /mnt/huge
	ulimit -l unlimited  # in case limits.conf doesn't help
	sudo sysctl vm.mmap_min_addr=0
```

Optionally, to set the correct date/time on the system, execute the following command

```
	sudo date -s "$(wget -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f5-8)Z"  # for correct datetime
```


The build.sh script will automatically build and configure all necessary components automatically. 
Make changes in the script as required. The complete build process may take upto 15 minutes

NOTE: provide the absolute path of linux sgx driver when prompted. That would be absolute path of ./linux-sgx-driver

```
	./build.sh
```

NOTE !!! The following steps below the line are for reference only. The ./build.sh script will perform all steps below

------------------------------------------------------------------------------------------------------------------------------

Install linux-sgx-driver

```
	mkdir ~/01org && cd ~/01org
	git clone https://github.com/01org/linux-sgx-driver && cd linux-sgx-driver
	make
	sudo mkdir -p "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"          # the following commands are from linux-sgx-driver README
	sudo cp isgx.ko "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"
	sudo sh -c "cat /etc/modules | grep -Fxq isgx || echo isgx >> /etc/modules"
	sudo /sbin/depmod
	sudo /sbin/modprobe isgx
```


Install Linux SGX SDK

```
	git clone https://github.com/01org/linux-sgx.git && cd linux-sgx
	./download_prebuilt.sh   # the following commands are from linux-sgx README
	make
	make sdk_install_pkg
	make psw_install_pkg
	cd linux/installer/bin && sudo ./sgx_linux_x64_psw_${version}.bin 
	cd linux/installer/bin && sudo ./sgx_linux_x64_sdk_${version}.bin  # Choose "/opt/intel" as installdir 
	sudo service aesmd start
	cd /opt/intel/sgxsdk/SampleCode/LocalAttestation && make &&  ./app  # simple test that SGX SDK works
```



Install Intel DPDK  (SGX-Snort was tested with DPDK 17.08)

```
	cd ~
	git clone http://dpdk.org/git/dpdk && cd dpdk
	make install T=x86_64-native-linuxapp-gcc DESTDIR=install  EXTRA_CFLAGS="-fPIC"
	echo 'export RTE_SDK=$HOME/dpdk' >> ~/.bashrc
	echo 'export RTE_TARGET=x86_64-native-linuxapp-gcc' >> ~/.bashrc
	cd usertools && sudo ./dpdk-setup.sh  # choose "[17] Insert VFIO module"; then "[23] Bind Ethernet/Crypto device to VFIO module" for all required network interfaces; then "[24] Setup VFIO permissions"
```

Apply graphene patches and Build Graphene-SGX. Also build libdaq libraries to link with Graphene PAL

```
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
```

Then build snort and depdendent libaries with graphene SGX support

```
    make -C LibOS/shim/test/apps

```

--------------------------------------------------------------------------------------------------------------------------


### Time to test SGX snort ...Success if you see snort version output

```
	export LD_LIBRARY_PATH="$LD_LIBRARY_PATH":$(readlink -f graphene/LibOS/shim/test/apps/libdaq/install/lib)
	cd graphene/LibOS/shim/test/apps/snort3 && SGX=1 ./pal_loader snort3.manifest.sgx --version && cd -

```

Test helloworld app inside Graphene-SGX to make sure the installation was successful

```
	cd graphene/LibOS/shim/test/native/ && make SGX=1 DEBUG=1 && make SGX_RUN=1 && ./pal_loader SGX helloworld
```

Run experiments on SGX-Snort (NOTE: change constants in run scripts for your configuration beforehand!)

```
	./graphene-snort/LibOS/shim/test/apps/snort3 && run.sh -v=sgx
```

Run experiments on vanilla Snort (NOTE: change constants in run scripts for your configuration beforehand!)

```
	./graphene-snort/LibOS/shim/test/apps/snort3 && run.sh -v=vanilla
```


Sample rules are already present in ~/code/graphene-snort/LibOS/shim/test/apps/snort3/rules/ folder. 
you can also add rules by adding the new rules file in the folder. 

Latest Rules are available at https://www.snort.org/downloads/community/snort3-community-rules.tar.gz

To use new rules in SEC-IDS you must add the new rules file name in the snort manifest file

```
	./graphene/LibOS/shim/test/apps/snort3/snort3.manifest.template:sgx.allowed_files.rules6 = file:install/etc/snort/<new_rules_file>.rules
```

Include the new rule file in snortrules for snort to use it

```
	./graphene/LibOS/shim/test/apps/snort3/run.sh:declare -a   snortrules=("" "" "<new_rules_file>.rules")
```


### LICENSE INFORMATION

Snort v3 and daq-2.2.1 patches are released under GPLv2

Graphene patches are released under LGPL

Build and run scripts are released under Apache 2.0

