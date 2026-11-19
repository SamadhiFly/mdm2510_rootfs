#!/bin/sh

EXECDIR=$(dirname $(realpath "$0"))
source ${EXECDIR}/install_handling.source

if is_mp_supported; then
    ver=$(/sbin/versioninfo_mode_slot.sh dlg $1 version | sed -n 's/firmware_version: \(.*\)$/\1/p')
    if [ -n "$ver" ]; then
        echo "$ver yes"
    fi
else
    activebuild=$(get_cmdline_var "activebuild")

    case "$1" in
        "passive")
            slot=$((1-activebuild))
            ;;
        "active")
            slot=${activebuild}
            ;;
        *)
            slot=$1
            ;;
    esac
    ver=$(/sbin/mkimage.sh list /dev/img${slot} | format_version)
    if [ -n "$ver" ]; then
        echo "$ver no"
    fi
fi
