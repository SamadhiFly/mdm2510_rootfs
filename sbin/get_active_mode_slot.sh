#!/bin/sh

source /sbin/env_processing.source


iterate_over_modes() {
    local func=$1
    shift

    local numbermodes=$(get_uboot_var numbermodes)
    for mode in $(seq 0 $((numbermodes-1))); do
        local mode_str=$(get_uboot_var mode_${mode})
        ${func} ${mode} "${mode_str}" $@ || return $?
    done
}

report_activeslot_for_mode() {
    local iter_mode=$1
    local iter_mode_str=$2
    local mode=$3

    if [ ${mode} == ${iter_mode} -o ${mode} == "${iter_mode_str}" ]; then
        echo "$(get_uboot_var activeslot_mode${iter_mode})"
    fi
}

get_activeslot() {
    local mode=$1

    iterate_over_modes report_activeslot_for_mode ${mode}
}


if [ $# -ne 1 ]; then
    die "Usage: $0 <mode>"
fi

mode=$1

if is_mp_supported; then
        execute_with_cfg_lock get_activeslot ${mode}
else
        echo $(get_cmdline_var activebuild)
fi


