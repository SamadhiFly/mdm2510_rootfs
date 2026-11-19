#!/bin/sh

# setup internal communication between mainboard and tellishape on addin board
# for e.g. modulator feedback, queueing status, ACM and HRC signalling...
#
# This script only does STATIC (one-time) configuration !!!
#

# MB2TS: mainboard to tellishape
# - control plane: modem-local: modulator feedback, queueing status
MB2TS_PHYS_IF=eth0
MB2TS_VLAN=3003
MB2TS_IF=${MB2TS_PHYS_IF}.${MB2TS_VLAN}
MB2TS_MAINBOARD_IP=169.254.0.233
MB2TS_ADDINBOARD_IP=169.254.0.234
MB2TS_NETWORK="169.254.0.232"
MB2TS_NETMASK="30"
MB2TS_SUBNET=${MB2TS_NETWORK}/${MB2TS_NETMASK}

# MB2TS2HUB: mainboard to tellishape to hub
# - management plane: remote gui, snmp
# - control plane: TCS signalling, ACM client and HRC signalling
MB2TS2HUB_PHYS_IF=eth0
MB2TS2HUB_VLAN=3004
MB2TS2HUB_IF=${MB2TS2HUB_PHYS_IF}.${MB2TS2HUB_VLAN}
MB2TS2HUB_MAINBOARD_IP=169.254.0.165
MB2TS2HUB_ADDINBOARD_IP=169.254.0.166
MB2TS2HUB_NETWORK="169.254.0.164"
MB2TS2HUB_NETMASK="30"
MB2TS2HUB_SUBNET=${MB2TS2HUB_NETWORK}/${MB2TS2HUB_NETMASK}

# TS2MB: all traffic from tellishape to mainboard
TS2MB_PHYS_IF=eth0
TS2MB_VLAN=3002
TS2MB_IF=${TS2MB_PHYS_IF}.${TS2MB_VLAN}
TS2MB_MAINBOARD_IP=169.254.0.229
TS2MB_ADDINBOARD_IP=169.254.0.230
TS2MB_NETWORK="169.254.0.228"
TS2MB_NETMASK="30"
TS2MB_SUBNET=${TS2MB_NETWORK}/${TS2MB_NETMASK}

. /etc/parse_modem_netdev.sh

vlan_if_add()
{
    PHYS_IF=$1
    VLAN=$2
    MAINBOARD_IP=$3
    NETMASK=$4
    VLAN_IF=${PHYS_IF}.${VLAN}
    MTU=$5

    /sbin/ip link set ${PHYS_IF} up
    /sbin/vconfig add ${PHYS_IF} ${VLAN}
    /sbin/ip addr add ${MAINBOARD_IP}/${NETMASK} dev ${VLAN_IF} 
    /sbin/ip link set dev ${VLAN_IF} mtu ${MTU}
    /sbin/ip link set ${VLAN_IF} up
}

mainboard2tellishape_init()
{
    logger -t $0 -p daemon.info "mainboard2tellishape_init"

    vlan_if_add ${MB2TS_PHYS_IF} ${MB2TS_VLAN} ${MB2TS_MAINBOARD_IP} ${MB2TS_NETMASK} 1500
    iptables -A INPUT -i ${MB2TS_IF} -j ACCEPT
    echo "any" > /sys/class/net/${MB2TS_IF}/netring_host_filter # only expect traffic for linux stack

    vlan_if_add ${MB2TS2HUB_PHYS_IF} ${MB2TS2HUB_VLAN} ${MB2TS2HUB_MAINBOARD_IP} ${MB2TS2HUB_NETMASK} 1500
    iptables -A INPUT -i ${MB2TS2HUB_IF} -j ACCEPT
    echo "any" > /sys/class/net/${MB2TS2HUB_IF}/netring_host_filter # only expect traffic for linux stack
}

tellishape2mainboard_init()
{
    logger -t $0 -p daemon.info "tellishape2mainboard_init"

    vlan_if_add ${TS2MB_PHYS_IF} ${TS2MB_VLAN} ${TS2MB_MAINBOARD_IP} ${TS2MB_NETMASK} 8000
    echo "local_arp" > /sys/class/net/${TS2MB_PHYS_IF}.${TS2MB_VLAN}/netring_host_filter

    # netring bridge
    BRIDGE=br_return
    echo "${BRIDGE}" > /sys/class/misc/netring_bridges/add_new_bridge
    echo "${TS2MB_PHYS_IF}.${TS2MB_VLAN}" > /sys/class/misc/netring_bridges/${BRIDGE}/source
    echo "${modem_netdev_generic_mod}" > /sys/class/misc/netring_bridges/${BRIDGE}/destination
    echo "1500" > /sys/class/misc/netring_bridges/${BRIDGE}/slots
    echo "enable" > /sys/class/misc/netring_bridges/${BRIDGE}/config_state
    echo "any" > /sys/class/misc/netring_bridges/${BRIDGE}/filter
}

