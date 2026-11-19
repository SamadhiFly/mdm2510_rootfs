#!/bin/sh

# From S3PFIELDISSUE-12518.
# There were two cases where max10 was not able to reboot the routerboard when mainboard was rebooted.
# To detect such case, we try to read the routerboard's uptime. If the routerboard is not reachable,
# then it is booting and all is fine. If it is reachable, we check the uptime and if the routerboard
# is up longer then mainboard, we reboot it.

set -e

SELF=$(basename $0)

. /usr/local/bin/parse_var_state_cfg.sh
parse_routercontroller_supported

# check for presence of routerboard
if [ -z "${CFG_routercontroller_supported}" ] || [ ${CFG_routercontroller_supported} -ne 1 ]; then
    exit 0
fi

SSH=$(which ssh || true)
if [ -z "$SSH" ]; then
    logger -t $SELF -p user.err "ERROR: ssh command not found!"
    exit 1
fi

RT_ACCESS_CMD="timeout -t 10 ${SSH} 169.254.0.130"
GET_UPTIME_CMD="cut -d '.' -f 1 /proc/uptime"
ALLOWED_DIFF_SEC=300
RT_TMP_FILE="/tmp/rt_uptime.txt"

RT_ERR_CODE=0
$RT_ACCESS_CMD "$GET_UPTIME_CMD" > $RT_TMP_FILE 2> /dev/null || RT_ERR_CODE=$?
if [ $RT_ERR_CODE -ne 0 ]; then
    # this is not an error, this means the routerboard is booting
    logger -t $SELF "The routerboard is not up yet."
    exit 0
fi

RT_UPTIME=$(cat $RT_TMP_FILE)
MB_UPTIME=$(eval "$GET_UPTIME_CMD")

if [ $RT_UPTIME -gt $MB_UPTIME ]; then
    UPTIME_DIFF=$(($RT_UPTIME - $MB_UPTIME))
    if [ $UPTIME_DIFF -gt $ALLOWED_DIFF_SEC ]; then
        logger -t $SELF "WARNING: The routerboard did not reboot! Mainboard uptime: $MB_UPTIME, routerboard uptime: $RT_UPTIME. Rebooting the routerboard now."
        # The reboot_routerboard.sh script is intentionally NOT used here, because it has dependencies that
        # are not running at the time this script runs.
        eval "$RT_ACCESS_CMD reboot"
        exit 0
    fi
fi

logger -t $SELF "Routerboard's uptime is within limits."
exit 0
