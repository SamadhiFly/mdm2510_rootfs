check_swdownload#!/bin/sh
#
# checks if all kernel drivers are currently loaded.
#
result=$(/sbin/lsmod)
while read m; do
	if [ -n "${result##*${m}*}" ]; then
		exit 1
	fi
done < "/etc/s3phal_modules"

# the sleep invocation here is meant to avoid contention with other monit checks
# that also call 's3p' command.
sleep 1

# check if communication between userspace and newtec kernel drivers are ok.
# (if not, this command will lock and watchdog will timeout on this function)
/usr/local/bin/s3p getstate
exit $?

