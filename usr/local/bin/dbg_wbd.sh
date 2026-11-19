#!/bin/sh
# This script allows debugging the wideband demodulator for MDM5010 modem series
modemtype="None"
# run a command $2 for a $1 times
run_command() {
   for i in $(seq 1 $1)
   do
      eval $2
   done
}

cmd="/usr/local/bin/clish -u newtec -c "
# check modem type
res=`/usr/local/bin/cliclient GetDeviceInformation -g RequestData.Hardware.ModemType`
if [ $res == 'MDM5010' ]; then
   wbd="$cmd debug wbd0-0 "
elif [ $res == 'AMC5001' ]; then
   wbd="$cmd debug wbd0 "
   modemtype=$res
else
   echo 'St Oxford demodulator status'
   run_command 1 "$cmd debug stoxford status"
   exit
fi
if [ $modemtype == "AMC5001" ]; then
   wbd_dc_get="$wbd wbd dc_get_mon_get"
else
   wbd_dc_get="$wbd wbd dc_wbc_mon_get"
fi

run_command 1 "$wbd fe nios_version_get"
# Some commands are repeated on purpose in order to check changing counters.
run_command 2 "$wbd status"
run_command 2 "$wbd modcodstats"
run_command 1 "$wbd counters"
run_command 2 "$wbd wbd dem_get_state_counters_get"
echo 'Demod timesliced mode'
run_command 1 "$wbd wbd dem_get_timesliced_mode_get"
echo
run_command 2 "$wbd wbd fs_get_state_get"
run_command 2 "$wbd wbd cs_get_stat_get"
run_command 2 "$wbd_dc_get"

sleep 1
run_command 1 "$wbd status"
run_command 1 "$wbd modcodstats"
run_command 1 "$wbd counters"
run_command 1 "$wbd wbd dem_get_state_counters_get"
run_command 1 "$wbd wbd fs_get_state_get"
run_command 1 "$wbd wbd cs_get_stat_get"
run_command 1 "$wbd_dc_get"

for i in $(seq 0 255)
do
   run_command 1 "$wbd wbd dc_get_tsn_get $i"
done
echo "St Oxford demodulator status"
run_command 1 "$cmd debug stoxford status"
echo
