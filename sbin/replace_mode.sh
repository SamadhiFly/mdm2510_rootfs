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

is_not_mode() {
    local iter_mode=$1
    local iter_mode_str=$2
    local compare_mode=$3

    test "${compare_mode}" != "${mode_str}"
}

do_replace_mode() {
    local iter_mode=$1
    local iter_mode_str=$2
    local old_mode=$3
    local new_mode=$4

    if [ ${old_mode} == ${iter_mode} -o ${old_mode} == ${iter_mode_str} ]; then
        if [ ${iter_mode} == $(get_cmdline_var selMode) ]; then
            die "Can not replace the current mode"
        else
            update_uboot_var mode_${iter_mode} ${new_mode}
        fi
    fi
}

replace_mode() {
    local old_mode=$1
    local new_mode=$2

    if [ ${new_mode} == "<empty>" ]; then
        new_mode=""
    fi

    iterate_over_modes is_not_mode ${new_mode} || die "${new_mode} already exists"
    iterate_over_modes do_replace_mode ${old_mode} ${new_mode}
}

get_free_mode()
{
num_modes=$(get_uboot_var numbermodes)
for mode in $(seq 0 $((num_modes-1))); do
	if [ -z "$(get_uboot_var mode_${mode})" ]; then
		echo ${mode}
		return
	fi
done
}

add_mode() {
    local new_mode=$1
    local free_mode=$(get_free_mode)
    
    test -z "${free_mode}" && die "no free mode available"
    
    update_uboot_var mode_${free_mode} ${new_mode}
}


if [ $# -ne 2 ]; then
    die "Usage: $0 <old_mode> <new_mode>"
fi

old_mode=$1
new_mode=$2

if [ ${old_mode} == "<empty>" ]; then
	execute_with_cfg_lock add_mode "${new_mode}"
else
	execute_with_cfg_lock replace_mode "${old_mode}" "${new_mode}"
fi
