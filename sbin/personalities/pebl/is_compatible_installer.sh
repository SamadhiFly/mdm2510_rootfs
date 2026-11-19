#!/bin/sh

EXECDIR=$(dirname $(realpath "$0"))
source ${EXECDIR}/install_handling.source

test $# -eq 1 || die "Usage: $(basename $0) <installer.bin>"
filename=$1
[ -f ${filename} ] || die "File does not exist"
product=$2

create_tempdir || die "Can not create tempdir"

product=$(2>/dev/null get_product.sh || true)
if [ -z ${product} ]; then
    product="hwid:$(2>/dev/null get_hardwareid.sh)"
fi

is_compatible_installer "${filename}" "${product}"
