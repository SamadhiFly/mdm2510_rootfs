#!/bin/sh

TS_TN_IF=eth0
TS_TN_VLAN=3001
TS_TN_FULL_IF=${TS_TN_IF}.${TS_TN_VLAN}

ts_tn_connection_init()
{
    logger -t $0 -p daemon.info "ts_tn_connection_init"

    /sbin/ip link set dev ${TS_TN_IF} mtu 1792
    /sbin/ip link set ${TS_TN_IF} up
    /sbin/ip link add link ${TS_TN_IF} ${TS_TN_FULL_IF} type vlan id ${TS_TN_VLAN}
    /sbin/ip link set dev ${TS_TN_FULL_IF} mtu 1792
    /sbin/ip link set dev ${TS_TN_FULL_IF} up

    # Linux network stack not involved.  All return traffic is handled by Tellishape/Netring (and the forward traffic by the Netring Bridge).
    echo "" > /sys/class/net/${TS_TN_FULL_IF}/netring_host_filter
}

