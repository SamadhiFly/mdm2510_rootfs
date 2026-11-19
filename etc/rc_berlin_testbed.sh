#!/bin/sh

# /var/state/cfg needs to be available at this point.
. /usr/local/bin/parse_var_state_cfg.sh
parse_modemtype
parse_ipaddr
parse_netmask
parse_routercontroller_supported

. /usr/local/bin/ifcfg_internal_mgmt.sh
. /usr/local/bin/pxeboot

sname=`basename "$0"`

# make firewall less strict for debugging. 
/usr/sbin/iptables -F INPUT
/usr/sbin/iptables -F OUTPUT
/usr/sbin/iptables -F FORWARD
/usr/sbin/iptables -P INPUT ACCEPT
/usr/sbin/iptables -P OUTPUT ACCEPT

/usr/sbin/ip6tables -F INPUT
/usr/sbin/ip6tables -F OUTPUT
/usr/sbin/ip6tables -F FORWARD
/usr/sbin/ip6tables -P INPUT ACCEPT
/usr/sbin/ip6tables -P OUTPUT ACCEPT

if [ "${CFG_modemtype}" -eq 12 ]; then
	ip link set name sgmii0 dev eth0
	ip link set name eth0 dev eth1
elif [ "${CFG_modemtype}" -eq 13 ]; then
	ip link set name mac0 dev eth0
	ip link set name eth0 dev eth1
fi

## Netring ring buffer configuration
# Eth0 needs to be up for configuring ring buffers.
/sbin/ip link set dev eth0 mtu 8000
/sbin/ip link set dev eth0 up
#MDM5x00/MDM3310/AMC5001
if [ "${CFG_modemtype}" -eq 8 -o "${CFG_modemtype}" -eq 11 -o "${CFG_modemtype}" -eq 12 ]; then
	/usr/local/bin/set_ring_buffers.sh eth0 2048 1024
#MDM2210
elif [ "${CFG_modemtype}" -eq 9 ]; then
	/usr/local/bin/set_ring_buffers.sh eth0 256 256
#MDM2510
elif [ "${CFG_modemtype}" -eq 10 ]; then
	/usr/local/bin/set_ring_buffers.sh eth0 512 512
#MDM5010
elif [ "${CFG_modemtype}" -eq 13 ]; then
	/usr/local/bin/set_ring_buffers.sh eth0 2048 2048
#MDM2010
elif [ "${CFG_modemtype}" -eq 15 ]; then
	/usr/local/bin/set_ring_buffers.sh eth0 256 256
fi

if [ "${CFG_modemtype}" -eq 13 ]; then
	# For MDM5010, Berlin needs direct access to the routerboard (since Tellinet and Tellishape are running there).
  # Therefore the routerboard should be able to PXE boot properly, and the CPE needs SSH access to both routerboard and mainboard.
	echo "Doing MDM5010-specific things."
	# Eth0 needs to be up for configuring netring related settings.
	/sbin/ip link set dev eth0 up
	echo "any_arp,system" > /sys/class/net/eth0/netring_host_filter

	# MDM5010-style.
	/sbin/ip link set dev eth0 down
	# Reset to a known state.
	/sbin/ip -4 addr flush dev eth0
	/sbin/ip -6 addr flush dev eth0 scope global
	/sbin/ip -6 addr flush dev eth0 scope site
	# Why would we need forwarding on the main board?
	/sbin/sysctl -w net.ipv4.conf.all.forwarding=0
	/sbin/sysctl -w net.ipv6.conf.all.forwarding=0
	/sbin/ip link set dev eth0 mtu 8000 # max BBF size
	# For configuring netring host filter, the interface needs to be up.
	/sbin/ip link set dev eth0 up

	############################################
	# Configure dedicated VLAN-access devices. #
	############################################

	# eth0.3000: internal mgmt
	internal_mgmt_init

	# pxe boot
  IPT="/usr/sbin/iptables"
  key="EXTERNAL_ROUTER_INTERNAL_MGMT";
  keyComment="-m comment --comment ${key}"

  TFTP_IF=${PXE_IF}
  TFTP_SIP=${PXE_SUBNET}
  TFTP_DIP=${PXE_MB_IPADDR}
  ${IPT} -A INPUT -p udp  -i ${TFTP_IF} --sport 68 --dport 67  -j ACCEPT ${keyComment}
  pxeboot_start

else
	# Other modems
	if [ -n "${CFG_ipaddr}" ]; then
		ifconfig eth0 "${CFG_ipaddr}"
	fi
fi

# On some modems the HW watchdog is enabled by default and requires petting.
/bin/nice -n +10 /usr/local/bin/rc_init_watchdog.sh "0"

modprobe ntc-switch
for i in 0 1; do
	if test $(ls -d /sys/devices/switch${i}.* 2>/dev/null | wc -l) -eq 1; then
		ln -s /sys/devices/switch${i}.* /var/state/switch${i}
	fi
done

. /usr/local/bin/ssh_commands.sh
start_ssh

