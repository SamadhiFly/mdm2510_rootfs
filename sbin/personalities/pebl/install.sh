#!/bin/sh

EXECDIR=$(dirname $(realpath "$0"))
source ${EXECDIR}/install_handling.source

[ $# -eq 1 ] || die "Usage: $(basename $0) <installer.bin>"
filename=$1
[ -f ${filename} ] || die "File does not exist"

/sbin/is_confirmation_pending.sh && die "SW validation still pending"
/sbin/modeswitch_or_upgrade_in_progress.sh && die "Upgrade/Modeswitch already initiated"

create_tempdir || die "Can not create tempdir"

product=$(2>/dev/null get_product.sh || true)
if [ -z ${product} ]; then
    product="hwid:$(2>/dev/null get_hardwareid.sh)"
fi

do_install "${filename}" "${product}"
