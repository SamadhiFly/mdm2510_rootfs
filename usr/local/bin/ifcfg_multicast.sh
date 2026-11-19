#!/bin/sh

FW_MC_PHYS_IF=eth0
FW_MC_VLAN=3011
FW_MC_IF=${FW_MC_PHYS_IF}.${FW_MC_VLAN}
FW_MC_IP=169.254.0.241/30
FW_MC_SUBNET=169.254.0.240/30
FW_MC_BROADCAST_IP=169.254.0.243

RT_MC_PHYS_IF=eth0
RT_MC_VLAN=3012
RT_MC_IF=${RT_MC_PHYS_IF}.${RT_MC_VLAN}

init_return_multicast()
{
    logger -t $0 -p daemon.info "multicast_init_mc_return"
    /sbin/ip link set ${RT_MC_PHYS_IF} up
    /sbin/ip link add link ${RT_MC_PHYS_IF} ${RT_MC_IF} type vlan id ${RT_MC_VLAN}
    /sbin/ip link set dev ${RT_MC_IF} mtu 1500
    /sbin/ip link set dev ${RT_MC_IF} up
    # Return multicast:  Only static mode supported.  User traffic goes straight into Tellishape; close this filter (SMS-5859).
    echo "" > /sys/class/net/${RT_MC_IF}/netring_host_filter
}

init_forward_multicast()
{
    logger -t $0 -p daemon.info "multicast_init_mc_forward"
    /sbin/ip link set ${FW_MC_PHYS_IF} up
    /sbin/ip link add link ${FW_MC_PHYS_IF} ${FW_MC_IF} type vlan id ${FW_MC_VLAN}
    /sbin/ip link set dev ${FW_MC_IF} mtu 1500
    /sbin/ip link set dev ${FW_MC_IF} up
    /sbin/ip addr add ${FW_MC_IP} broadcast ${FW_MC_BROADCAST_IP} dev ${FW_MC_IF}
    # Forward multicast: Dynamic mode: IGMP reports are received on the local management interface instead of this one.
    echo "" > /sys/class/net/${FW_MC_IF}/netring_host_filter
}

