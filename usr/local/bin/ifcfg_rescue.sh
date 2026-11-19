#!/bin/sh

RESCUE_IF=eth0
#RESCUE_VLAN=3007
RESCUE_VLAN=""
if [ -z "$RESCUE_VLAN" ]; then
  RESCUE_FULL_IF=${RESCUE_IF}
else
  RESCUE_FULL_IF=${RESCUE_IF}.${RESCUE_VLAN}
fi
RESCUE_IPADDR="192.168.5.1"
RESCUE_NETMASK="255.255.255.252"
RESCUE_PREFIX="30"

rescue_init()
{
    logger -t $0 -p daemon.info "rescue_init"

    /sbin/ip link set ${RESCUE_IF} up

    if [ -n "$RESCUE_VLAN" ]; then
        /sbin/ip link add link ${RESCUE_IF} ${RESCUE_FULL_IF} type vlan id ${RESCUE_VLAN}
        /sbin/ip link set dev ${RESCUE_FULL_IF} mtu 1500
        /sbin/ip link set dev ${RESCUE_FULL_IF} up
        echo "system" > /sys/class/net/${RESCUE_FULL_IF}/netring_host_filter
    else
        # Hostfilter for native interface eth0 is configured elsewere in a generic way (covering all use cases).
        :
    fi

    /sbin/ip addr add ${RESCUE_IPADDR}/${RESCUE_PREFIX} dev ${RESCUE_FULL_IF} 
}

