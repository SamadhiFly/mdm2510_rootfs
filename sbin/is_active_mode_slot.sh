#!/bin/sh

scriptdir=$(dirname "$0")
source ${scriptdir}/env_processing.source

if [ $# -ne 2 ]; then
    die "Usage: $0 <mode> <slot>"
fi

mode=$1
slot=$2

if [ "$(${scriptdir}/get_active_mode_slot.sh ${mode})" == "${slot}" ]; then
        result=active
fi
echo ${result} | grep active
