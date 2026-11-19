#!/bin/sh


# lock the cfg using the same lock as readcfg/writecfg to make sure noone touches it during our update.
if [ -z "$LOCK" ]; then
    LOCK=/var/state/cfg
    export LOCK
    flock -x $LOCK "$0" "$@"
    exit $?
fi

reboot_reason_id=$(cat /var/state/cfg | grep "^reboot_reason_id=" | cut -d"=" -f2)
echo "reboot_reason_id=$reboot_reason_id" > /tmp/reboot_reason_info

sed -i '/^reboot_reason_id=/d' /var/state/cfg
/usr/local/bin/writecfg
