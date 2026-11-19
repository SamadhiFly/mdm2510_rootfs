#!/bin/sh

source /sbin/env_processing.source
source /sbin/mode_slot_handling.source


usage() {
    echo "Usage: $0 [-M <mode>] [-S <slot>] [-P <periph-file>] [-C <core-file>]" >&2
    echo "    mode: specify the mode for which to install the fpgas (default = current mode)" >&2
    echo "    slot: 'active' or 'passive' (default = active)"  >&2
    echo "    periph-file: periph rbf mkimage file"  >&2
    echo "    core-file: core rbf file (no mkimage)"  >&2
    exit 1
}

get_mode_num() {
    /sbin/get_supported_modes.sh | grep $1 | cut -d ' ' -f 1
}


init_mode_slot_selection() {
    numbermodes=$(execute_with_cfg_lock get_uboot_var numbermodes)

	UBOOT_SLOT_BLOCKSIZE=4
	PERIPH_RBF_SLOT_BLOCKSIZE=8
	PERIPH_RBF_SLOT_START=$(((numbermodes*2)*UBOOT_SLOT_BLOCKSIZE))
}


get_mode_info() {
    local mode
    local numbermodes=$(get_uboot_var numbermodes)
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

get_slot_num_no_lock() {
    local mode=$1
    local slot=$2

    get_mode_info | while read mode_num mode_str active_slot; do
        if test ${mode} -eq ${mode_num}; then
            get_slot ${slot} ${active_slot}
        fi
    done
}

get_slot_num() {
    local mode=$1
    local slot=$2

    execute_with_cfg_lock get_slot_num_no_lock ${mode} ${slot}
}

get_file_size()
{
	filename=$1
	stat -t ${filename} | cut -d ' ' -f 2
}

write_flash_img() {
	local sectorsize=$((64*1024))
	local image=$1
	local target=$2
	local target_start_sector=$3
	local size=$(get_file_size ${image})
	local num_sectors=$(((size+sectorsize-1)/sectorsize))

	echo write_flash_img image=${image} target=${target} sector=${target_start_sector:=0} num=${num_sectors}
	flash_erase ${target} ${target_start_sector:=0} ${num_sectors} || die "can not erase flash $target (err: $?)"
	dd if=${image} count=${size} obs=${sectorsize} of=${target} seek=${target_start_sector:=0} 2>/dev/null || die "can not extract image $image (err: $?)"

	echo "${target}@${target_start_sector:=0}: size=$(stat -t ${image}  | cut -d' ' -f 2) md5=$(md5sum ${image} | cut -d'/' -f 1)"
}

update_core_fpga() {
    local file=$1
    local dev=$2

    mount | grep -q ${dev}
    if [ $? ]; then
        mount -o remount,rw /lib/firmware
        cp ${file} /lib/firmware/boot/fpga.core.mkimage
        mount -o remount,ro /lib/firmware
        sync
    else
        mkdir -p /tmp/mnt
        mount ${dev} /tmp/mnt
        cp ${file} /tmp/mnt/boot/fpga.core.mkimage
        umount /tmp/mnt
        rmdir /tmp/mnt
    fi
}

MODE=$(get_cmdline_var selMode)
SLOT=active

while test $# -gt 0; do
    case $1 in
        '-M')
            shift
            MODE=$(get_mode_num $1)

            if test -z "${MODE}"; then
                die "Invalid mode specified"
            fi
        ;;
        '-S')
            shift
            SLOT=$1
            if test "${SLOT}" != "active" && test "${SLOT}" != "passive"; then
                die "slot must be 'active' or 'passive'"
            fi
        ;;
        '-P')
            shift
            PERIPH=$1
            test -f ${PERIPH} || die "Periph fpga file does not exist"
        ;;
        '-C')
            shift
            CORE=$1
            test -f ${CORE} || die "Core fpga file does not exist"
        ;;
        *)
            usage
        ;;
    esac
    shift
done


if test -z "${PERIPH}" && test -z "${CORE}"; then 
    die "You need to specify at least 1 of the fpgas to be replaced"
fi


is_mp_supported ||  die "This script can only work on multi personality enabled devices"
/sbin/is_confirmation_pending.sh && die "Must not replace FPGAs while upgrade is pending"

slot=$(get_slot_num ${MODE} ${SLOT})

echo "Replacing FPGA(s) on mode ${MODE}, slot ${SLOT} (${slot})"
if test -n "${PERIPH}"; then
    echo "  periph fpga: ${PERIPH}"
    init_mode_slot_selection
    bank=$(select_bank)
    fpga_target=$(get_periph_rbf_dev_and_offset ${bank} ${MODE} ${slot})
    write_flash_img ${PERIPH} ${fpga_target}
fi

if test -n "${CORE}"; then
    echo "  core fpga: ${CORE}"
    mmcdev=$(get_sw_dev ${MODE} ${slot})
    update_core_fpga ${CORE} ${mmcdev}
fi
