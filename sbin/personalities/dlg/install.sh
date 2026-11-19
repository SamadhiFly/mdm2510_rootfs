#!/bin/sh

EXECDIR=$(dirname $(realpath "$0"))
source ${EXECDIR}/install_handling.source

test $# -eq 1 || die "Usage: $(basename $0) <installer.bin>"
filename=$1
[ -f ${filename} ] || die "File does not exist"

/sbin/is_confirmation_pending.sh && die "SW validation still pending"
/sbin/modeswitch_or_upgrade_in_progress.sh && die "Upgrade/Modeswitch already initiated"

hwid="$(2>/dev/null get_hardwareid.sh)"

do_install "${filename}" "${hwid}"
