#!/bin/sh

source /sbin/env_processing.source
source /sbin/mode_slot_handling.source

WORKDIR=/tmp/verify-$$

cleanup_validation()
{
    cd /tmp
    if test -d $WORKDIR; then
        mount | grep -q $WORKDIR/firmware && umount $WORKDIR/firmware
        rm -rf $WORKDIR
    fi
}
trap cleanup_validation EXIT

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
        echo ${mode} $(get_uboot_var mode_${mode})
    done
}

extract_raw_uimage() {
    local dev=$1
    local offset=$2
    local target=$3

    mkdir -p $(dirname ${target})
    /sbin/mkimage.sh extract-image -o ${offset} -f ${target} ${dev}
}

validate_image() {
    local requested_mode=$1
    local mode=$2
    local slot=$3
    local bank=$(select_bank)
    local dev=$(get_sw_dev ${mode} ${slot})

    mkdir -p $WORKDIR/firmware

    extract_raw_uimage $(get_periph_rbf_dev_and_offset ${bank} ${mode} ${slot}) $WORKDIR/flash/fpga.img
    extract_raw_uimage $(get_uboot_dev_and_offset ${bank} ${mode} ${slot}) $WORKDIR/flash/uboot.img

    mount -o ro ${dev} $WORKDIR/firmware || die "Can not mount ${dev}"

    cd $WORKDIR
    set +e
    md5sum -s -c $WORKDIR/firmware/checksum.md5
    result=$?
    set -e

    test ${result} -eq 0 || >&2 echo validation failed for mode ${mode}-slot ${slot}

    return ${result}
}

## main processing

if [ $# -lt 2 ]; then
    >&2 "echo $0 <mode> <slot>"
    exit 1
fi

mp_validate()
{
    requested_mode=$1
    slot=$2

    init_mode_slot_selection

    valid_images=0
    invalid_images=0

    while read mode mode_str; do
        if [ -n "${mode_str}" ]; then
            if [ "${requested_mode}" == "all" ]; then
                for slot in 0 1; do
                    if validate_image ${mode_str} ${mode} ${slot}; then
                        valid_images=$((valid_images+1))
                    else
                        invalid_images=$((invalid_images+1))
                    fi
                done
            elif [ "${requested_mode}" == "${mode}" -o "${requested_mode}" == "${mode_str}" ]; then
                if validate_image ${mode_str} ${mode} ${slot}; then
                    valid_images=$((valid_images+1))
                else
                    invalid_images=$((invalid_images+1))
                fi
            fi
        fi
    done <<EOF
$(execute_with_cfg_lock get_mode_info)
EOF


    test ${invalid_images} -eq 0 -a ${valid_images} -gt 0
}

legacy_validate()
{
    /sbin/mkimage.sh verify /dev/mtdfpga$1 && /sbin/mkimage.sh verify /dev/img$1
}

if is_mp_supported; then
    mp_validate $1 $2
else
    legacy_validate $2
fi
