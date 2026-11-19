#!/bin/sh

VERBOSE=

. /usr/local/bin/parse_var_state_cfg.sh
parse_ipaddr
parse_netmask

LM_VLAN=3010
LM_PHYS_IF=eth0
LM_IF=${LM_PHYS_IF}.${LM_VLAN}
LM_IPADDR="169.254.0.193"
RB_LM_BRIDGE_IPADDR="169.254.0.194"
LM_NETMASK="255.255.255.224"
LM_SUBNET="169.254.0.192/27"
LM_GATEWAY="169.254.0.195"
LM_PREFIX=27

LM_IP6ADDR="fd00:4c4d::1"
LM_IP6GATEWAY="fd00:4c4d::3"
LM_IP6PREFIX=64
LM_IP6SUBNET="fd00:4c4d::/64"

get_netconfig_var_state_cfg() {
  ipaddr="${CFG_ipaddr}"
  netmask="${CFG_netmask}"

  if [ -n "$ipaddr" ]; then
    if ! /usr/local/bin/check_eth_subnet "$ipaddr" "$netmask"
    then
      fac_ipaddr=`sed -n "s/^fac_ipaddr=\(.*\)$/\1/p" /var/state/cfg`
      fac_netmask=`sed -n "s/^fac_netmask=\(.*\)$/\1/p" /var/state/cfg`
      ipaddr=${fac_ipaddr:=192.168.1.1}
      netmask=${fac_netmask:=255.255.255.0}
    fi
  fi

  if [ -n "$ipaddr" ]; then
    prefix=`ipcalc -sp $ipaddr $netmask | sed -n "s/PREFIX=\(.*\)/\1/p"`
  fi
}

get_netconfig_var_state_cfg

ipv4_local_mgmt_init()
{
    /sbin/ip -4 addr add ${LM_IPADDR}/${LM_PREFIX} dev ${LM_IF}
    # route mgmt network towards router controller
    ethmgmtnet=`ipcalc -sn ${ipaddr}/${prefix} | sed -n "s/NETWORK=\(.*\)/\1/p"`
    ip -4 route add  ${ethmgmtnet}/${prefix} via ${LM_GATEWAY} dev ${LM_IF}
}

ipv6_local_mgmt_init()
{
    /sbin/ip -6 addr add ${LM_IP6ADDR}/${LM_IP6PREFIX} dev ${LM_IF}

    # source-based routing
    # traffic from local mgmt subnet should always go to addin board
    /sbin/ip -6 rule add from ${LM_IP6SUBNET} table ${LM_VLAN}
    /sbin/ip -6 route add default via ${LM_IP6GATEWAY} dev ${LM_IF} table ${LM_VLAN}
}

local_mgmt_init()
{
    logger -t $0 -p daemon.info "local_mgmt_init"

    /sbin/ip link set ${LM_PHYS_IF} up
    /sbin/vconfig add ${LM_PHYS_IF} ${LM_VLAN}
    /sbin/ip link set dev ${LM_IF} mtu 1500
    /sbin/ip link set ${LM_IF} up

    # Make the netring host filter configuration explicit.
    # On this interface we only expect traffic we actually need in the Linux stack, so no need for filtering.
    echo "any" > /sys/class/net/${LM_IF}/netring_host_filter

    ipv4_local_mgmt_init
    ipv6_local_mgmt_init
}

local_mgmt_update_route()
{
    oldipaddr=$1
    oldnetmask=$2

    newipaddr=$ipaddr
    newprefix=$prefix
    if [ $# -eq 4 ]; then
        newipaddr=$3
        newnetmask=$4
        newprefix=`ipcalc -sp $newipaddr $newnetmask | sed -n "s/PREFIX=\(.*\)/\1/p"`
    fi

    logger -t $0 -p daemon.info "local_mgmt_update_route old:$oldipaddr/$oldnetmask, new:$newipaddr/$newnetmask"

    # Delete old route
    oldprefix=`ipcalc -sp $oldipaddr $oldnetmask | sed -n "s/PREFIX=\(.*\)/\1/p"`
    oldnet=`ipcalc -sn ${oldipaddr}/${oldprefix} | sed -n "s/NETWORK=\(.*\)/\1/p"`
    [ ! -z "$VERBOSE" ] && logger -t $0 -p daemon.info "ip -4 route del  ${oldnet}/${oldprefix}  via ${LM_GATEWAY} dev ${LM_IF}"
    ip -4 route del  ${oldnet}/${oldprefix}  via ${LM_GATEWAY} dev ${LM_IF}

    # Add new one
    ethmgmtnet=`ipcalc -sn ${newipaddr}/${newprefix} | sed -n "s/NETWORK=\(.*\)/\1/p"`
    [ ! -z "$VERBOSE" ] && logger -t $0 -p daemon.info "ip -4 route add  ${ethmgmtnet}/${newprefix} via ${LM_GATEWAY} dev ${LM_IF}"
    ip -4 route add  ${ethmgmtnet}/${newprefix} via ${LM_GATEWAY} dev ${LM_IF}
}

