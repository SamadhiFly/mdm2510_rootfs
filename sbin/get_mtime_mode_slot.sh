#!/bin/sh

source /sbin/env_processing.source
source /sbin/mode_slot_handling.source

iterate_over_modes() {
    local func=$1
    shift

    local numbermodes=$(get_uboot_var numbermodes)
    for mode in $(seq 0 $((numbermodes-1))); do
        local mode_str=$(get_uboot_var mode_${mode})
        ${func} ${mode} "${mode_str}" $@ || return $?
    done
}

report_mtime_for_mode_slot() {
    local iter_mode=$1
    local iter_mode_str=$2
    local mode=$3
    local slot=$4

    if [ ${mode} == ${iter_mode} -o ${mode} == "${iter_mode_str}" ]; then
        echo "$(date -r $(get_sw_dev ${iter_mode} ${slot}) +%s 2>/dev/null)"
    fi
}

get_mtime() {
    local mode=$1
    local slot=$2

    iterate_over_modes report_mtime_for_mode_slot ${mode} ${slot}
}


if [ $# -ne 2 ]; then
    die "Usage: $0 <mode> <slot>"
fi

mode=$1
slot=$2

if is_mp_supported; then
    execute_with_cfg_lock get_mtime ${mode} ${slot}
fi
