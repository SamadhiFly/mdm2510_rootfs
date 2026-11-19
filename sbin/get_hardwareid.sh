#!/bin/sh

set -e
trap 'cleanup' EXIT

cleanup()
{
    if [ -n "$TMPDIR" -a -d "$TMPDIR" ]; then
        is_mounted ${TMPDIR} && umount ${TMPDIR}
        rm -rf ${TMPDIR}
    fi
}

die() {
    >&2 echo "Error: $@"
    exit 1
}

is_mounted()
{
    local dev=$1
    mount | grep -q ${dev}
}

get_mount_point()
{
    local dev=$1
    mount | grep ${dev} | cut -d' ' -f 3
}

get_config_mtdblock()
{
    grep '"config"' /proc/mtd | cut -d: -f 1 | sed 's,mtd,/dev/mtdblock,'
}

temp_mount()
{
    local dev=$1
    TMPDIR=$(mktemp -d /tmp/.XXXXXX || die "Could not create temp dir")

    mount -t jffs2 -o ro ${dev} ${TMPDIR} || die "Could not mount ${dev}"
}

readcfg_jffs()
{
    mtdblock=$(get_config_mtdblock)
    if ! is_mounted ${mtdblock}; then
        temp_mount ${mtdblock}
    fi

    mountpoint=$(get_mount_point ${mtdblock})

    if [ -r "${mountpoint}/config" ]; then
        /usr/sbin/modemconfigtool -r -o "hdrsep,grow,sep=nl,00" read ${mountpoint}/config
    fi
}

select_uboot_cfg()
{
    local DEVA="$1"
    local DEVB="$2"
    if [ -n "$DEVA" ]; then shift; fi
    if [ -n "$DEVB" ]; then shift; fi

    case "$(/usr/sbin/modemconfigtool $@ state "$DEVA"):$(/usr/sbin/modemconfigtool $@ state "$DEVB")" in
    good:inactive)
        echo $DEVA
        ;;
    *:inactive|*:good)
        echo $DEVB
        ;;
    *)
        echo $DEVA
        ;;
    esac
}

readcfg_uboot()
{
    local CFGARGS="-r -s0x1000"
    local CFG=$(select_uboot_cfg /dev/cfg0 /dev/cfg1 $CFGARGS)
    /usr/sbin/modemconfigtool $CFGARGS read $CFG
}

fetch_hwid()
{
    grep '^hardwareID=' | sed -e "s/^[^=]*='\(.*\)'$/\1/g"
}

get_hardwareid()
{
    local ID=$(readcfg_uboot | fetch_hwid)
    if [ -z "$ID" ] ; then
        ID=$(readcfg_jffs | fetch_hwid)
    fi
    echo "$ID"
}

get_hardwareid
