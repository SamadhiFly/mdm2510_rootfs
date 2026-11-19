#!/bin/sh

. /usr/local/bin/parse_var_state_cfg.sh

parse_watchdog_config()
{
	until [ -z "$1" ]
	do
		#echo "Processing parameter of: '$1'"
		parameter=${1%%=*}
		value=${1##*=}
		#echo "Parameter: '$parameter', value: '$value'"
		case "$parameter" in
		"wdcycle") wdcycle=$value ;;
		"wdinterval") wdinterval=$value ;;
		"wdretries") wdretries=$value ;;
		"wdtimeoutlong") wdtimeoutlong=$value ;;
		"wdtimeoutshort") wdtimeoutshort=$value ;;
		"wdtrafficchecks") wdtrafficchecks=$value ;;
		esac
		shift
	done

}

stringContain() { [ -z "${2##*$1*}" ] && [ -z "$1" -o -n "$2" ]; }

install_cron_entry()
{
	base=$1

	. /var/state/monitoring/cfg/${base}

	if [ -z "$cron" ]; then
		return
	fi

	# Append this to any existing crontab entries
	(crontab -l ; echo "${cron} /usr/local/bin/monitoring ${base}") | crontab -
}

parse_script() {
	base=`basename $1 .templ`
	tmpl="/etc/monitoring/$1"
	tmp="/tmp/${base}.tmp"
	cfg="/var/state/monitoring/cfg/${base}"
	start=`expr $RANDOM % 24`
	prend=`expr $start + 3`
	end=`expr $prend % 24`
	instance=`expr 60 / $wdcycles` # calculate how many cicles has to be performed within one hour
	# put an extra random value on the first min,
	# so not every terminal that has the same hours region is kicked at the same minute for this test
	value=`expr $RANDOM % 60`
	while stringContain " $value " "$saved_minutes"
	do
		value=`expr $RANDOM % 60`
	done
	minutes=$value
	first=$value
	saved_minutes="$saved_minutes $value "
	# calculate which minutes the test has to be performed on the ping_tcs test
	# so that is isn't executed every cycle the monit is kicked
	while [ $instance -gt 1 ]
	do
		while stringContain " $value " "$saved_minutes"
		do
			value=`expr $value + $wdcycles`	# add the number of minutes between two cycles to the previous moment
			if test $value -ge 60; then     # if bigger than an hour, substract an hour
				value=`expr $value - 60`
			fi
		done
		saved_minutes="$saved_minutes $value "
		minutes="$minutes,$value"       # and put in the list
		instance=`expr $instance - 1`   # and calculate how many instance there are still left within an hour
	done
	cp $tmpl $tmp
	sed -i "s/%WDTIMEOUTLONG_CYCLES%/${wdtimeoutlong_cycles}/g" $tmp
	sed -i "s/%WDTIMEOUTLONG%/${wdtimeoutlong}/g" $tmp
	sed -i "s/%WDTIMEOUTSHORT%/${wdtimeoutshort}/g" $tmp
	sed -i "s/%WDRETRIES%/${wdretries}/g" $tmp
	sed -i "s/%WDCYCLE%/${wdcycle}/g" $tmp
	sed -i "s/%START%/${start}/g" $tmp
	sed -i "s/%END%/${end}/g" $tmp
	sed -i "s/%CYCLES%/${wdcycles}/g" $tmp
	sed -i "s/%MINUTES%/${minutes}/g" $tmp
	cp $tmp $cfg
	rm $tmp

	install_cron_entry $base
	mkdir -p /var/state/monitoring/state/${base}
}

start_hardware_watchdog()
{
	echo "start hardware watchdog"
	# Start the Newtec watchdog application (including the canary feature for thread starvation detection).
	/usr/local/sbin/ntc_watchdog '/usr/local/bin/kill_rt_threads.sh 2>/dev/null' '/usr/local/bin/log2flashandreboot.sh canary' &
	# The OOM killer should ignore our process.
	echo '-17'> /proc/$!/oom_score_adj
}

################
##    MAIN    ##
################

[ "$#" -eq 1 ] || { echo "$0: Incorrect number of arguments!"; exit 1; }
parse_modemtype
enable_tellinet_check="$1"

parse_watchdog_config $(grep ^wd /var/state/cfg)
wdcycles=`expr $wdcycle / $wdinterval`
wdtimeoutlong_cycles=`expr $wdtimeoutlong / $wdinterval`
saved_minutes=" "

parse_wdenable
if [ "${CFG_wdenable}" -ne 1 ]; then
	# AMC5001: always start the hardware watchdog, regardless of the wdenable configuration
	if [ "${CFG_modemtype}" -eq 11 ]; then
		start_hardware_watchdog
	else
		logger -t ntc_watchdog "watchdog did not start because it is disabled in flash config."
	fi
	logger -t monitor "monitor did not start because it is disabled in flash config."
	exit
fi

# parse general scripts
scripts="check_kernel_drivers.templ check_modem_controller.templ check_kensogui.templ"

# only add Tellinet if it's enabled
if [ "${enable_tellinet_check}" = "1" ]; then
	scripts="$scripts check_tellinet.templ"
fi

# parse traffic checks, if enabled
if [ "${wdtrafficchecks}" = "1" ]; then
	scripts="$scripts ping_tcs.templ"
fi

# add temperature check if modem is MDM2210 of MDM2010
if [ "${CFG_modemtype}" = "9" -o "${CFG_modemtype}" = "15" ] ; then
	scripts="$scripts check_temperature.templ"
fi

# check swdownload for 'all models with /dev/img0 & /dev/img1'
# This check corresponds to the condition for swdownload to start
if [ -c /dev/img0 ] && [ -c /dev/img1 ]; then
	scripts="$scripts check_swdownload.templ"
fi

mkdir -p /var/state/monitoring/cfg

for i in $scripts; do
	parse_script $i
done

start_hardware_watchdog
/usr/local/bin/parse_tcs_when_available.sh &
