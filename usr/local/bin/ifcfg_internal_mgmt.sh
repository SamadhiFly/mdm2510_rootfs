#!/bin/sh

IM_PHYS_IF=eth0
IM_VLAN=3000
IM_IF=${IM_PHYS_IF}.${IM_VLAN}
IM_MAINBOARD_IP=169.254.0.129
IM_ADDINBOARD_IP=169.254.0.130
IM_SUBNET="169.254.0.128/27"

internal_mgmt_init()
{
    logger -t $0 -p daemon.info "internal_mgmt_init"

    # configure specificed VLAN ${IM_VLAN} for internal communication between main board and router board.
    /sbin/ip link set ${IM_PHYS_IF} up
    /sbin/vconfig add ${IM_PHYS_IF} ${IM_VLAN}
    /sbin/ip addr add ${IM_MAINBOARD_IP}/27 dev ${IM_IF} 
    /sbin/ip link set dev ${IM_IF} mtu 1500
    /sbin/ifconfig ${IM_IF} up

    # Make the netring host filter configuration explicit.
    # On this interface we only expect traffic we actually need in the Linux stack, so no need for filtering.
    echo "any" > /sys/class/net/${IM_IF}/netring_host_filter

}

