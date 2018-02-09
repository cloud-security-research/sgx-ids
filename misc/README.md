# Patches to add LibDAQ+DPDK support to Graphene-SGX
Tested with commit 4d8eacdd44029af28887247ebeb11b3d3ac1f6df (March 23, 2017 by donporter).

Apply patches in the following order:
1. graphene-pull-request-58.patch
2. graphene-01-mmap-map32bit.diff
3. graphene-02-unmap-tcs.diff
4. graphene-03-trustedclock-dpdkocalls.diff

The first patch (pull request) fixes the naming issue of Intel SGX Driver.
The second patch fixes issue with `mmap(.., MAP_32BIT,..)` that was triggered on LuaJIT library.
The third patch fixes the Graphene-SGX bug of not-enough TCS slots for re-allocated threads.
The fourth patch introduces the Trusted Clock thread (used in `gettime()` syscall) and DPDK Ocalls (used to initialize/finalize DPDK layer).

# testclock utility
This is an utility to find out the "correct" value for the coefficient of the trusted clock (CPUFREQ).
Specify CPUFREQ values in `run.sh` and run the script. Peak the value that is closest to the real clock value.
