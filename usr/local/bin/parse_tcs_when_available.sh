#!/bin/sh
#
# check every 2 minutes forever if the modem has been pointed
# and status is green.
# if this loops continues for more than a day, just reboot the 
# terminal as well as ping wont ever come through either.
# (i.e. emulate the same behaviour as the watchdog/monit would do)

# only do this check if traffic tests are enabled
wdtrafficchecks=`sed -n "s/^wdtrafficchecks=\(.*\)$/\1/p" /var/state/cfg`
if [ "${wdtrafficchecks}" = "0" ]; then
	exit
fi

counter=0
while [ 1 ]; do
	# uneven sleep cmd to avoid contention with other s3p cmds issued
	sleep 117
	ptstatus=`sed -n "s/^ptstatus=\(.*\)$/\1/p" /var/state/cfg`
	green=`/usr/local/bin/s3p getstate | grep summary_state | grep GREEN`
	if [ "${ptstatus}" = 1 -a "${green}" = 0 ]; then
		break;
	fi
	counter=`expr ${counter} + 1`
	if [ "${counter}" -gt 720 ]; then
		/usr/local/bin/log2flashandreboot.sh ping_tcs
	fi
done
