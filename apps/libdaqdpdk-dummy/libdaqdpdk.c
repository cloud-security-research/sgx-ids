#include <stdint.h>
#include <stdlib.h>


int ocall_dpdk_initialize(char* config_name, int config_snaplen, unsigned int config_timeout, uint32_t config_flags, int config_mode,
       char* dpdk_args, int debug, int dpdk_queues, void** ctxt_ptr, char* errbuf, size_t errlen) {
    return 0;
}

int ocall_dpdk_start_device(void* handle, void* dev) {
    return 0;
}

int ocall_dpdk_acquire(void* handle) {
    return 0;
}

int ocall_dpdk_stop(void* handle) {
    return 0;
}

int ocall_dpdk_shutdown(void* handle) {
    return 0;
}
