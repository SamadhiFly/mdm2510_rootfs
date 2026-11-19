#!/bin/sh
#
# rotate the wdreason[0..4] and write the latest reason at item 4 with timestamp.
# also write to syslog as well.
#
# usage example:
#   log2flashandreboot.sh unrecoverable backpressure_IRQ
#

# lock the cfg using the same lock as readcfg/writecfg to make sure noone touches it during our update.
# unlocked by reboot. :-)
if [ -z "$LOCK" ]; then
    # be aware that the lock file is really /var/state/cfg to prevent anybody from changing it while we do our update.
    LOCK=/var/state/cfg
    export LOCK
    flock -x $LOCK "$0" "$@"
    exit $?
fi

reason=$1
detail=$2
currenttime=`date +"%T"`
currentdate=`date +"%d-%m-%Y"`
message_prefix="WATCHDOG ERROR:"
message_postfix="Rebooting!"

case "${reason}" in
    canary)
        reason="wdreboot_thread_starvation"
        savelogs=1
        logger -t monitor "${message_prefix} Canary died; normal threads got starved for too long. ${message_postfix}"
        ;;

    ping_tcs)
        reason="wdreboot_tcs_unreachable"
        logger -t monitor "${message_prefix} TCS is not reachable. ${message_postfix}"
        ;;

    drivers)
        reason="wdreboot_kernel_drivers"
        savelogs=1
        logger -t monitor "${message_prefix} Kernel drivers are not working. ${message_postfix}"
        ;;

    modem_controller)
        reason="wdreboot_modem_controller"
        savelogs=1
        logger -t monitor "${message_prefix} modem_controller malfunctioning. ${message_postfix}"
        ;;

    swdownload)
        reason="wdreboot_swdownload_malfunction"
        savelogs=1
        logger -t monitor "${message_prefix} swdownload malfunctioning. ${message_postfix}"
        ;;

    tellinet)
        reason="wdreboot_tellinet_malfunction"
        logger -t monitor "${message_prefix} Tellinet malfunctioning. ${message_postfix}"
        ;;

    temperature)
        temperature=`cat /tmp/temperature.log`
        reason="wdreboot_temperature"_${temperature}
        savelogs=1
        logger -t monitor "${message_prefix} Temperature ${temperature} exceeded maximum value. ${message_postfix}"
        ;;

    *)
        reason="wdreboot_unknown"
        logger -t monitor "${message_prefix} Unknown error. ${message_postfix}"
        ;;
esac

# re-read the configuration to not write changes that are not meant to be written yet, see MODSWFW-664
/usr/local/bin/readcfg

sed -i "s/\(^wd[a-z_][a-z_]*=[0-9][0-9]*|[0-9][0-9]*-[0-9][0-9]*-[0-9][0-9]*|[0-9][0-9]*:[0-9][0-9]*:[0-9][0-9]*\).*$/\1/g" /var/state/cfg

counter=`sed -n "s/^$reason=\([0-9][0-9]*\).*$/\1/p" /var/state/cfg`

if [ -z "$counter" ]; then
    echo "$reason=1|$currentdate|$currenttime|newest" >> /var/state/cfg
else
    counter=$((counter+1))
    sed -i "s/^$reason=.*$/$reason=$counter|$currentdate|$currenttime|newest/" /var/state/cfg
fi

#Set reboot_reason_id to watchdog (1) in flash config
exists=`grep "^reboot_reason_id=" /var/state/cfg`
if [ -z "$exists" ]; then
    echo "reboot_reason_id=1" >> /var/state/cfg
else
    sed -i "s/^reboot_reason_id=.*/reboot_reason_id=1/" /var/state/cfg
fi

# write the cfg
/usr/local/bin/writecfg

# kill the rotator so that it will backup logs since the reboot -f will forcekill apps without signal handling
pgrep 'rotator' | xargs -r kill -15

if [ -n "$savelogs" ] && grep -q "/mnt/sd" /proc/mounts; then
  watchdog_log=`echo "watchdog_logs_${reason}_${currentdate}_${currenttime}.tar.gz" | sed 's/:/-/g'`
  tail -n 500 /tmp/logfiles/main_board.log > /tmp/logfiles/main_board.log.wdlog
  pgrep 'ModemCtrl' | xargs -r kill -SIGUSR2
  sleep 10
  cp /tmp/rip.txt /tmp/logfiles/rip.txt.wdlog
  for log in /tmp/logfiles/router_board.*
  do
    tail -n 500 $log > ${log}.wdlog
  done
  cd /tmp/logfiles && tar cvzf /mnt/sd/$watchdog_log throwlog ./*.wdlog > /dev/null 2>&1
  n_watchdog_logs=`ls /mnt/sd/watchdog_logs* | wc -l`
  if [ "$n_watchdog_logs" -gt "5" ]; then
      rm "$(ls -t -d /mnt/sd/watchdog_logs* | tail -1)" > /dev/null 2>&1
  fi
fi

# sync files to disk
sync

# force hard reboot
/sbin/reboot -f

