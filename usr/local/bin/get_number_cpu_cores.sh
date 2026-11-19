#!/bin/sh

MAX_CPU=$(sed /sys/devices/system/cpu/possible -e 's/.*\([0-9]\)$/\1/')
NUM_CPUS=$((MAX_CPU+1))
echo ${NUM_CPUS}
