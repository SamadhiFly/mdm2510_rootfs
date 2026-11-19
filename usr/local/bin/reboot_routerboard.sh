#!/bin/sh

set -e

if [ -z "$LOCK" ]; then
        LOCK=/var/run/rt_reboot.lock
        export LOCK
        flock -x $LOCK "$0" "$@"
        exit $?
fi

SELF=$(basename "$0")

. /usr/local/bin/parse_var_state_cfg.sh
parse_routercontroller_supported

# check for presence of routerboard
if [ -z "${CFG_routercontroller_supported}" ] || [ ${CFG_routercontroller_supported} -ne 1 ]; then
    logger -t $SELF "Routerboard not present, exiting."
    exit 0
fi

SAFETY_DELAY=60
STAT=$(which stat || true)
DATE=$(which date || true)
if [ -n "$STAT" ] && [ -n "$DATE" ]; then
    LAST_RUN=$(stat -t $LOCK | cut -d' ' -f12)
    CREATED_AT=$(stat -t $LOCK | cut -d' ' -f13)
    NOW=$(date +%s)
    if [ $LAST_RUN -eq $CREATED_AT ]; then
        # the lock file was just created, there was no previous run, skip the check
        true
    else
        if [ $(($NOW - $LAST_RUN)) -lt $SAFETY_DELAY ]; then
            logger -t $SELF "Called too soon after the previous reboot, try later please."
            exit 0
        fi
    fi
else
    logger -t $SELF -p user.err "ERROR: 'stat' or 'date' not found!"
fi

if [ -z "$1" ]; then
    reboot_type=0
elif [ 1 -eq "$1" ] || [ 2 -eq "$1" ]; then
    reboot_type=$1
else
    logger -t $SELF -p user.err "ERROR: wrong parameter value, use '1' for SSH, '2' for register reboot. Or no parameter."
    exit 1
fi

# reboot_type == 0 -> both methods, SSH then register
# reboot_type == 1 -> only SSH method
# reboot_type == 2 -> only register method

if [ $reboot_type -eq 0 ] || [ $reboot_type -eq 1 ]; then
    SSH=$(which ssh || true)
    if [ -z "$SSH" ]; then
        logger -t $SELF -p user.err "ERROR: ssh command not found!"
        # try the other method
        $reboot_type=2
    else
        RT_ACCESS_CMD="timeout -t 10 ${SSH} 169.254.0.130"
        RT_ERR_CODE=0
        $RT_ACCESS_CMD reboot 2> /dev/null || RT_ERR_CODE=$?
        if [ $RT_ERR_CODE -ne 0 ]; then
            logger -t $SELF "The routerboard is not accessible via ssh."
            if [ $reboot_type -eq 1 ]; then
                exit 0
            fi
            # try the other method
            reboot_type=2
        else
            logger -t $SELF "The routerboard was rebooted using SSH."
            # don't use the 'touch' command, it changes the "created" time as well
            cat /dev/null > $LOCK
            exit 0
        fi
    fi
fi

if [ $reboot_type -eq 2 ]; then
    CLI=$(which clish || true)
    if [ -z "$CLI" ]; then
        logger -t $SELF -p user.err "ERROR: clish command not found!"
        exit 1
    fi
    CLI="$CLI -u newtec -c debug registers"
    WRITE_CMD="writebit"
    READ_CMD="readbit"
    POWER_ENABLE_REGISTER="max10moncon routercontrollercontrol powerenable"

    ERROR_LOG="/tmp/rt_err.log"
    ERROR_CODE=0
    $CLI $READ_CMD $POWER_ENABLE_REGISTER > $ERROR_LOG 2>&1 || ERROR_CODE=$?
    if [ $ERROR_CODE -gt 0 ] || grep -q "Error occurred:" $ERROR_LOG; then
        # the stupid clish returns 0 even on missing register; we need to grep the output
        logger -t $SELF "Max10 powerenable register is not available."
    else
        trap "" SIGINT SIGABRT # next section must not be intetrupted

        # make sure the routerboard is powered up in case of an error somewhere
        trap "$CLI $WRITE_CMD $POWER_ENABLE_REGISTER 1 || true" EXIT

        $CLI $WRITE_CMD $POWER_ENABLE_REGISTER 0 || true
        sleep 2
        $CLI $WRITE_CMD $POWER_ENABLE_REGISTER 1 || true
        trap - EXIT SIGINT SIGABRT # allow signals again

        logger -t $SELF "The routerboard was rebooted using register write."

        # don't use the 'touch' command, it changes the "created" time as well
        cat /dev/null > $LOCK
    fi
fi
