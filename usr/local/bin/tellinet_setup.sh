#!/bin/sh

stop_tellitec
killall tc-net-client

mode="S2"
if [ ! -z $1 ];
then
    mode=$1
fi

#set_debug_mode activate #if connected through serial connection instead of ett

#wget http://192.168.1.2/firmware/net-client_$mode.ini -O /net-client_$mode.ini

if [ ! -e /net-client_$mode.ini ]
then
    cp /etc/net-client_$mode.default.ini /net-client_$mode.ini
fi  

/usr/local/bin/tc-net-client -c /net-client_$mode.ini &
