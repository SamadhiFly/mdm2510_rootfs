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

get_flash_mtdblock()
{
    grep '"flash"' /proc/mtd | cut -d: -f 1 | sed 's,mtd,/dev/mtdblock,'
}


temp_mount()
{
    local dev=$1
    TMPDIR=$(mktemp -d /tmp/.XXXXXX || die "Could not create temp dir")

    mount -t jffs2 -o ro ${dev} ${TMPDIR} || die "Could not mount ${dev}"
}

get_product()
{
    local filename=$1
    sed -n -e 's,.*<Product value="\([^"=]*\)"\s*/>.*,\1,p' ${filename}
}

mtdblock=$(get_flash_mtdblock)
if ! is_mounted ${mtdblock}; then
    temp_mount ${mtdblock}
fi

mountpoint=$(get_mount_point ${mtdblock})

get_product ${mountpoint}/DeviceInformation.xml
