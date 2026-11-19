#!/bin/sh

source /sbin/env_processing.source


get_mode_info() {
    local mode
    local numbermodes=$(get_uboot_var numbermodes)

    for mode in $(seq 0 $((numbermodes-1))); do
        local mode_str=$(get_uboot_var mode_${mode})
        echo ${mode} ${mode_str:=<empty>}
    done
}


execute_with_cfg_lock get_mode_info
