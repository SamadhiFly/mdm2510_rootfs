#!/bin/sh

#If Tx is disabled, Tellinet doesn't need to be running. In that case, the test succeeds.
txdisabled=$(/usr/local/bin/cliclient -g RequestData.Disabled GetTxDisabled)
if [ $txdisabled == "true" ]; then
    exit 0
fi

ptstatus=`sed -n "s/^ptstatus=\(.*\)$/\1/p" /var/state/cfg`
if [ "${ptstatus}" != 1 ]; then
    exit 0;
fi

green=`/usr/local/bin/s3p getstate | grep summary_state | grep GREEN`
if [ "${green}" != 0 ]; then
    exit 0
fi

tcs=`/usr/local/bin/s3p getmodemdata | grep http | head -n 1 | cut -d '/' -f 3 `
number=3
/bin/ping -c $number -q -W 300 $tcs
#ping will return with value 0 if all replies were received.
exit $?
