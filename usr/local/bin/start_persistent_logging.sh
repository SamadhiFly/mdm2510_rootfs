#!/bin/sh

migrate()
{
    # ensure correct migration from old files
    if [ -f /mnt/sd/logs/monitoring/hw_events ]; then
        mv /mnt/sd/logs/monitoring/hw_events /mnt/sd/logs/monitoring/hw_events.log
    fi
    if [ -f /mnt/sd/logs/monitoring/sw_events ]; then
        mv /mnt/sd/logs/monitoring/sw_events /mnt/sd/logs/monitoring/sw_events.log
    fi
    if [ -f /mnt/sd/logs/monitoring/usage_statistics ]; then
        mv /mnt/sd/logs/monitoring/usage_statistics /mnt/sd/logs/monitoring/usage_statistics.log
    fi
}
case "$1" in
normal)
    sdcardpresent=0
    if [ -e "/dev/mmcblk0p1" ]; then
      if grep -qs '/mnt/sd' /proc/mounts; then
        # sd exists and is mounted
        sdcardpresent=1
        migrate
      fi
    fi

    /usr/local/bin/is_multi_core.sh && START="schedtool -a 0x1 -e "
    ${START:=""} /usr/local/bin/rotator -s $sdcardpresent &
    ;;
nosd)
    /usr/local/bin/is_multi_core.sh && START="schedtool -a 0x1 -e "
    ${START:=""} /usr/local/bin/rotator &
;;
sd)
    migrate
    /usr/local/bin/is_multi_core.sh && START="schedtool -a 0x1 -e "
    ${START:=""} /usr/local/bin/rotator -s 1 &
;;
esac

# try to tigger hardware monitoring to it's default state and ignore the outcome since this
#     could be error in case modem controller is not running
/usr/local/bin/clish -u newtec -c debug monitoring status set auto || true
