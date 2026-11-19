#!/bin/sh

source /sbin/env_processing.source
source /sbin/mode_slot_handling.source


init_mode_slot_selection() {
    numbermodes=$(execute_with_cfg_lock get_uboot_var numbermodes)
    SECTOR_SIZE=$((64*1024))
    UBOOT_SLOT_BLOCKSIZE=$((4*SECTOR_SIZE))
    PERIPH_RBF_SLOT_BLOCKSIZE=$((8*SECTOR_SIZE))
    PERIPH_RBF_SLOT_START=$(((numbermodes*2)*UBOOT_SLOT_BLOCKSIZE))
}

get_mode_info() {
    local mode

    for mode in $(seq 0 $((numbermodes-1))); do
        echo ${mode} $(get_uboot_var mode_${mode}) $(get_uboot_var activeslot_mode${mode})
    done
}


get_slot()
{
    local slot=$1
    local activeslot=$2
    case ${slot} in
        "passive")
            echo $((1-activeslot))
            ;;
        "active")
            echo ${activeslot}
            ;;
        *)
            echo ${slot}
            ;;
    esac
}

# Invalidate bank(s) where the alternative SW is going to be written.
# Needs to be done to prevent two banks with alternative software available (MODSWFW-775)

# clear legacy
activebuild=$(get_cmdline_var "activebuild")
slot=$((1-activebuild))

target1=/dev/img$slot
logger -t clear_passive -p user.info "Clearing legacy image in $target1"
dd if=/dev/zero of=$target1 bs=64 count=1

# clear multipersonality

requested_mode=dlg
slot=passive

init_mode_slot_selection

while read mode mode_str activeslot; do
    if [ -n "${mode_str}" ]; then
        selectedMode=$(get_cmdline_var selMode)

        if [ "${mode}" == "${selectedMode}" ]; then
            activeslot=$(get_cmdline_var selSlot)
        fi

        if [ "${requested_mode}" == "${mode}" -o "${requested_mode}" == "${mode_str}" ]; then
            target1=$(get_sw_dev ${mode} $(get_slot ${slot} ${activeslot}))
            logger -t clear_passive -p user.info "Clearing multipersonality image in $target1"
            dd if=/dev/zero of=$target1 bs=1k count=5 2>/dev/null
        fi
    fi
done <<EOF
$(execute_with_cfg_lock get_mode_info)
EOF
