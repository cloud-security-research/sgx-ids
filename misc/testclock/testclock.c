#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <pthread.h>

volatile long unsigned trusted_clock;

static void* clock_thread_main(void* dummy) {
//    printf("[clock_thread] starts incrementing trusted_clock variable\n");

    trusted_clock = 0;

    asm volatile (
            "mov %0, %%rcx\n\t"
            "mov (%%rcx), %%rax\n\t"
            "1: inc %%rax\n\t"
            "   mov %%rax, (%%rcx)\n\t"
            "   jmp 1b"
            : /* no output operands */
            : "r"(&trusted_clock)
            : "%rax", "%rcx", "cc"
            );

    /* unreachable */
    return 0; 
}

int main(int argc, char** argv) {
#define CPUFREQ 3980.5  /* NOTE: for my particular Xeon CPU E3-1270 v5 @ 3.60GHz */

    int s = 0;
    if (argc > 1)
        s = atoi(argv[1]);
    if (s == 0)
        s = 30;

    double r = 0.0;
    if (argc > 2)
        r = atof(argv[2]);
    if (r == 0.0)
        r = CPUFREQ;

    pthread_t clock_thread;
    pthread_create(&clock_thread, NULL, clock_thread_main, NULL);

    long unsigned start2, end2;
    long unsigned diff, diff2;
    struct timespec start, end;

    clock_gettime(CLOCK_MONOTONIC, &start);
    start2 = (long unsigned) (trusted_clock/r);

    sleep(s);

    clock_gettime(CLOCK_MONOTONIC, &end);
    end2 = (long unsigned) (trusted_clock/r);

    diff  = (1000000000L * (end.tv_sec - start.tv_sec) + end.tv_nsec - start.tv_nsec) / 1000L;
    diff2 = end2 - start2;

    printf("clock_gettime = %10lu us\n", (long unsigned) diff);
    printf("trusted time  = %10lu us\n", (long unsigned) diff2);

    return 0;
}
