#!/bin/sh

EXECDIR=$(dirname $(realpath "$0"))
source ${EXECDIR}/install_handling.source

test $# -eq 1 || die "Usage: $(basename $0) <installer.bin>"
filename=$1
[ -f ${filename} ] || die "File does not exist"

hwid="$(2>/dev/null get_hardwareid.sh)"

is_compatible_installer "${filename}" "${hwid}"
