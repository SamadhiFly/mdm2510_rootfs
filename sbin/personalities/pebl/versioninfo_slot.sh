#!/bin/sh

EXECDIR=$(dirname $(realpath "$0"))
source /sbin/env_processing.source
source ${EXECDIR}/install_handling.source

if is_mp_supported; then
    /sbin/versioninfo_mode_slot.sh pebl $1 build.xml | format_version
elif [ "$(get_cmdline_var activebuild)" == "$1"  -o "$1" == "active" ]; then
    cat /build.xml | format_version
else
    echo Undetermined
fi
