#!/bin/sh

if [ $# -ne 2 ]
then
    echo "Usage: $0 <serverIp> <serverPort>"
    exit 1
fi

iptables -P INPUT ACCEPT

modprobe ipRegisterAccess serverIp=$1 serverPort=$2

s3p init_for_test_bench
