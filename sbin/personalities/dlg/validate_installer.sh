#!/bin/sh

EXECDIR=$(dirname $(realpath "$0"))
source ${EXECDIR}/install_handling.source

[ $# -eq 1 ] || die "Usage: $(basename $0) <installer.bin>"
filename=$1
[ -f ${filename} ] || die "File does not exist"

create_tempdir || die "Can not create tempdir"

validate_installer ${filename}
