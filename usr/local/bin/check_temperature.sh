#!/bin/sh

#max component temperatures 
spirit_max=105
marvell_max=115
oxford_max=105

result=0

spirit=`/usr/local/bin/clish -u newtec -c debug board temp | grep Spirit | awk '{ print $3 }'`
marvell=`/usr/local/bin/clish -u newtec -c debug board temp | grep Marvell | awk '{ print $3 }'`
oxford=`/usr/local/bin/clish -u newtec -c debug board temp | grep StOxford | awk '{ print $3 }'`

spirit=${spirit%.*}
marvell=${marvell%.*}
oxford=${oxford%.*}

if [ -z $spirit ];then
	spirit=0
fi

if [ -z $marvell ];then
	marvell=0
fi

if [ -z $oxford ];then
	oxford=0
fi

if [ "$spirit" -gt "$spirit_max" ]; then
	echo "Spirit" >> /tmp/temperature.log
	result=1
fi

if [ "$marvell" -gt "$marvell_max" ]; then
	echo "Marvell" >> /tmp/temperature.log
	result=1
fi

if [ "$oxford" -gt "$oxford_max" ]; then
	echo "Oxford" >> /tmp/temperature.log
	result=1
fi

exit ${result}
