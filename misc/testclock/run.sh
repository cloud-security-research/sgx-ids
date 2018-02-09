#!/bin/bash

# first build
gcc -O2 testclock.c -pthread

# now run many times

#for t in 30 60 90 120 150 180; do
for t in 30 60 90 120; do
    for CPUFREQ in 782.0; do
        for i in 1 2 3; do
            echo "EXP $CPUFREQ $t $i"
            ./a.out $t $CPUFREQ
        done
    done
done
echo "DONE!"
