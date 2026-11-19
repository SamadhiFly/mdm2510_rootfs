#!/bin/sh

ETHTOOL="/usr/sbin/ethtool"

if [ $# -eq 3 ]; then
  interface=$1
  rxrings=$2
  txrings=$3
else
  echo "This script checks if the interface has correct number of rings,"
  echo "    and reconfigures them if needed."
  echo ""
  echo "usage: set_ring_buffers <interface> <rx rings> <tx rings>"
  echo "    interface The ethernet interface to change the rings."
  echo "    rx rings  The number of rx rings."
  echo "    tx rings  The number of tx rings."
  exit 1
fi

###### MODIFY ######

currentrxrings=`${ETHTOOL} -g ${interface} | sed "1,/Current/d" | sed -n "s/RX:\s*\(\d*\)/\1/p"`
currenttxrings=`${ETHTOOL} -g ${interface} | sed "1,/Current/d" | sed -n "s/TX:\s*\(\d*\)/\1/p"`

if [ "${currentrxrings}" -ne "${rxrings}" ]; then
  ${ETHTOOL} -G ${interface} rx ${rxrings}
fi
if [ "${currenttxrings}" -ne "${txrings}" ]; then
  ${ETHTOOL} -G ${interface} tx ${txrings}
fi

###### VERIFY ######

currentrxrings=`${ETHTOOL} -g ${interface} | sed "1,/Current/d" | sed -n "s/RX:\s*\(\d*\)/\1/p"`
currenttxrings=`${ETHTOOL} -g ${interface} | sed "1,/Current/d" | sed -n "s/TX:\s*\(\d*\)/\1/p"`

if [ "${currentrxrings}" -ne "${rxrings}" ]; then
  echo "Unable to change ${interface} rx buffers to ${rxrings}, current value is ${currentrxrings}."
fi
if [ "${currenttxrings}" -ne "${txrings}" ]; then
  echo "Unable to change ${interface} tx buffers to ${txrings}, current value is ${currenttxrings}."
fi
