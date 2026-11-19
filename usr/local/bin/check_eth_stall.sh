#!/bin/sh

if [ $# -gt 1 ]; then
	device=$1
	baseaddr=$2
else
	device=eth0
	baseaddr=ff800000
fi

segaddr=`echo ${baseaddr} | cut -b 1-2`
lowaddr=`echo ${baseaddr} | cut -b 3-8`

logger "Starting monitoring for eth freeze on $device ."

regaddr=$segaddr`printf "%06x" $((0x${lowaddr} + 0x1014))`

while [ true ] ; do
	/bin/sleep 2
	
	#first check
	status=`/sbin/devmem 0x${regaddr} w`
	echo $status | grep 66 > /dev/null
	hang=$?
	if [ "$hang" != "1" ]; then
		continue
	fi
	
	#second check
	status=`/sbin/devmem 0x${regaddr} w`
	echo $status | grep 66 > /dev/null
	hang=$?
	if [ "$hang" != "1" ]; then
		continue
	fi
	
	rx_packets=`cat /sys/devices/soc.0/${baseaddr}.ethernet/net/${device}/statistics/rx_packets`

  logger "RX packets on first check:  $rx_packets "

	sleep 1
	
	#third check
	status=`/sbin/devmem 0x${regaddr} w`
	echo $status | grep 66 > /dev/null
	hang=$?
	if [ "$hang" != "1" ]; then
		continue
	fi
	
	sleep 1
	
	rx_packets2=`cat /sys/devices/soc.0/${baseaddr}.ethernet/net/${device}/statistics/rx_packets`
  logger "RX packets on second check:  $rx_packets2 "

    if [ "${rx_packets}" != "${rx_packets2}" ]; then
		continue
	fi
	
	#fourth check
	status=`/sbin/devmem 0x${regaddr} w`
	echo $status | grep 66 > /dev/null
	hang=$?
	if [ "$hang" != "1" ]; then
		continue
	fi

	logger "$0 : status $status , restarting ${device}"
	/sbin/ifconfig ${device} down
	/sbin/ifconfig ${device} up
done
