#!/bin/sh

source /sbin/env_processing.source
source /sbin/mode_slot_handling.source

MOUNTPT=/tmp/versioninfo-$$

cleanup_versioninfo() {
    if mount | fgrep -q $MOUNTPT; then
        umount $MOUNTPT
    fi
    if [ -d $MOUNTPT ] ; then
        rmdir $MOUNTPT
    fi
}

trap cleanup_versioninfo EXIT

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

get_version_info() {
    local mode=$1
    local slot=$2
    local versionfile=$3

    local dev=$(get_sw_dev ${mode} ${slot})
    mkdir -p $MOUNTPT
    BLKID=$(type -q blkid || true)
    if [ -n "$BLKID" ] ; then
        if ! $BLKID ${dev} | grep -q 'TYPE=' > /dev/null 2>&1 ; then
            return
        fi
    fi
    if mount -o ro ${dev} $MOUNTPT > /dev/null 2>&1 ; then
        if [ -r $MOUNTPT/${versionfile} ] ; then
            cat $MOUNTPT/${versionfile}
        fi
    fi
}

## main processing

if [ $# -lt 2 ]; then
    echo "$0 <mode> <slot> <versionfile>" >&2
    exit 1
fi

requested_mode=$1
slot=$2
versionfile=$3

init_mode_slot_selection

while read mode mode_str activeslot; do
    if [ -n "${mode_str}" ]; then
        selectedMode=$(get_cmdline_var selMode)

        if [ "${mode}" == "${selectedMode}" ]; then
            activeslot=$(get_cmdline_var selSlot)
        fi

        if [ "${requested_mode}" == "${mode}" -o "${requested_mode}" == "${mode_str}" ]; then
	    get_version_info ${mode} $(get_slot ${slot} ${activeslot}) ${versionfile}
        fi
    fi
done <<EOF
$(execute_with_cfg_lock get_mode_info)
EOF
