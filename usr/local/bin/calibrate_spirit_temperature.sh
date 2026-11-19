#!/bin/sh
boardtemp=`cat /var/state/cfg | grep "spiritreftemp"`
if [ -z $boardtemp ]; then
	while [ -z $boardtemp ]; do
		boardtemp=`/usr/local/bin/clish -u newtec -c debug board temp | grep "StOxford" | awk '{ print $3 }'`
	done
	while [ ${boardtemp%%.*} -lt 0 ]; do
		boardtemp=`/usr/local/bin/clish -u newtec -c debug board temp | grep "StOxford" | awk '{ print $3 }'`
	done
	while [ -z $boardvoltage ]; do
		boardvoltage=`/usr/local/bin/clish -u newtec -c debug spirit gettemperaturevoltage`
		wordcount=`echo "$boardvoltage" | wc -w`
		if [ $wordcount -ne 4 ]; then
			boardvoltage=""
		else
			boardvoltage=`echo "$boardvoltage" | awk '{ print $4 }'`
		fi
	done
	boardtemp="spiritreftemp=$boardtemp"
	boardvoltage="spiritrefvoltage=$boardvoltage"
	echo "$boardtemp" >> /var/state/cfg
	echo "$boardvoltage" >> /var/state/cfg
	/usr/local/bin/writecfg
fi

