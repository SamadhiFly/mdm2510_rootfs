#!/bin/sh

###
# Monit script to check if Tellinet is still running.
###
. ntc_functions
. parse_var_state_cfg.sh
parse_tellinet_on_addin_board

moobError_reply="$(/usr/local/bin/cliclient GetOutOfBandError)"
moobError="$(json_get_value "${moobError_reply}" "Error")"
parse_moob_enabled
#if moob enabled and there is a moob error then it means that moob has not finished and it should wait in that state until user takes action
# Tellinet doesn't need to be running. In that case, the test succeeds.
if [ "${moob_enabled}" = "1" ] && [ "${moobError}" != "" ]; then
    exit 0
fi

txdisabled_reply="$(/usr/local/bin/cliclient GetTxDisabled)"
txdisabled="$(json_get_value "${txdisabled_reply}" "Disabled")"
lossoffwlock="$(json_get_value "${txdisabled_reply}" "LossOfFwLock")"
# If Tx is disabled for any reason besides "loss of fw lock",
# Tellinet doesn't need to be running. In that case, the test succeeds.
if [[ "${txdisabled}" == "true" && "${lossoffwlock}" == "false" ]]; then
    exit 0
fi

netConfig=`/usr/local/bin/cliclient GetLayer3Data -g RequestData.Layer3Data`
echo ${netConfig} | grep -q tellitec_server0
#grep returns 1 if no line was found, 0 if a line was found
noL3Config=$?
if [ ${#netConfig} -gt 0 -a ${noL3Config} -eq 1 ]; then
    #Network config exists and only contains layer 2 networks => Tellinet doesn't need to be running.
    exit 0
fi

if [ "${tellinet_on_addin_board}" -eq 0 ]; then
  # Check if Tellinet is running
  /bin/pidof tc-net-client
  exit $?
else
  # Check if Tellinet is OK
  . ifcfg_internal_mgmt.sh
  destination="${IM_ADDINBOARD_IP}"
  port=10010
  echo "GET statistics.status" | nc -w 5 "${destination}" "${port}" 2>/dev/null | grep "statistics.status" > /dev/null 2>&1
  if [ "$?" = "0" ] ; then
      #success
      exit 0
  else
      exit 1
  fi
fi
