#!/bin/sh

EXECDIR=$(dirname $(realpath "$0"))
source ${EXECDIR}/install_handling.source

[ $# -eq 1 ] || die "Usage: $(basename $0) <installer.bin>"
filename=$1
[ -f ${filename} ] || die "File does not exist"

2>/dev/null version_info_installer ${filename} && echo

