#include <stdint.h>
#include <stdlib.h>

struct bitmask {
    unsigned long size; /* number of bits in the map */
    unsigned long *maskp;
};

int numa_available(void) {
    return 0;
}

long get_mempolicy(int *mode, unsigned long *nodemask, unsigned long maxnode, void *addr, unsigned long flags) {
    return 0;
}

void numa_bitmask_free(struct bitmask *bmp) {
    /* noop */;
}

struct bitmask *numa_allocate_nodemask(void) {
    return NULL;
}

int set_mempolicy(int mode, unsigned long *nodemask, unsigned long maxnode) {
    return 0;
}

void numa_set_localalloc(void) {
    /* noop */;
}

void numa_set_preferred(int node) {
    /* noop */;
}
