#!/bin/sh

sname=`basename "$0"`

# /var/state/cfg needs to be available at this point.
. /usr/local/bin/parse_var_state_cfg.sh
parse_modemtype
parse_routercontroller_supported

# Copy the value of flash config parameter reboot_reason_id to temporary storage
/etc/save_reboot_reason_info.sh

echo "${sname}: factory reset if requested"
factoryreset=`sed -n "s/.*factoryreset=\([01]\).*/\1/p" /proc/cmdline`
if [ -n "$factoryreset" -a "$factoryreset" = "1" ]; then
    echo "Perform factory reset"
    /usr/local/bin/do_factory_reset
fi

echo "${sname}: do any migration"
/etc/migration.sh

if [ "${CFG_routercontroller_supported}" -ne 1 ]; then
	# for mdm3310, if routercontroller supported is disabled, the default eth0 is not operational
	# since this is the link with the routercontroller, rename links so eth0 is a usable interface
	if [ "${CFG_modemtype}" -eq 12 ]; then
		ip link set name sgmii0 dev eth0
		ip link set name eth0 dev eth1
	fi
fi

if [ "${CFG_routercontroller_supported}" -eq 1 ]; then
	if [ "${CFG_modemtype}" -eq 10 ]; then
		ip link set name sgmii0 dev eth0
		ip link set name eth0 dev eth1
	fi
fi

syslogmode=`sed -n "s/^syslogmode=\(.*\)$/\1/p" /var/state/cfg`
syslogport=`sed -n "s/^syslogport=\(.*\)$/\1/p" /var/state/cfg`
syslogaddr=`sed -n "s/^syslogaddr=\(.*\)$/\1/p" /var/state/cfg`
syslogsize=`sed -n "s/^syslogsize=\(.*\)$/\1/p" /var/state/cfg`
ethswupgrade=`sed -n "s/^ethswupgrade=\(.*\)$/\1/p" /var/state/cfg`
modemipaddr=`sed -n "s/^modemipaddr=\(.*\)$/\1/p" /var/state/cfg`
norf_halsim=`sed -n "s/^norf_halsim=\(.*\)$/\1/p" /var/state/cfg`
airmac=`sed -n "s/^airmac=\(.*\)$/\1/p" /var/state/cfg`

#MDM3x00 and MDM5000: mount sd card of appropriate flash partition, used for storing GXT files for mobile terminals
if [ "${CFG_modemtype}" -eq 5 -o "${CFG_modemtype}" -eq 8 -o "${CFG_modemtype}" -eq 12 -o "${CFG_modemtype}" -eq 13 -o "${CFG_modemtype}" -eq 10 ]; then
	sdmountpoint=/mnt/sd
	gxtloc=${sdmountpoint}/gxt
	mount -o rw /dev/mmcblk0p1 $sdmountpoint
	if [ ! -d $gxtloc ]; then
		mkdir $gxtloc
	fi
fi

echo "airmac: $airmac"

echo "${sname}: Configure syslog"
echo '0 4 1 7' > /proc/sys/kernel/printk
/sbin/klogd
if [ "$syslogmode" = "1" ]; then
   /sbin/syslogd -m 0 -R 127.0.0.1:1514 -R $syslogaddr:$syslogport -L -C$syslogsize
else
   /sbin/syslogd -m 0 -R 127.0.0.1:1514 -L -C$syslogsize
fi

if [ -x /usr/sbin/syslogfwd ]; then
	SYSLOGDEST=
	if [ "$syslogmode" = 1 ]; then
		SYSLOGDEST="$syslogaddr:$syslogport"
	fi
	echo "${sname}: start syslog forwarder to '$SYSLOGDEST'"
	/usr/sbin/syslogfwd $SYSLOGDEST 127.0.0.1:2514 &
fi


/usr/local/bin/start_persistent_logging.sh normal

echo "${sname}: Start cron"
mkdir -p /var/spool/cron/crontabs
/usr/sbin/crond -l 9

# log input events
for INPUT in /dev/input/event*; do
	/etc/inputevent-log.sh start "$INPUT" &
done

sed -n 's/.*modem\.\(fe=[^ ]*\).*/options modem \1/p' /proc/cmdline >>/etc/modprobe.conf

# dmesg > /var/run/prngd-seed

# /usr/local/bin/prngd -c /etc/prngd.conf -s /var/run/prngd-seed  /var/run/prngd.socket

echo -n "RunningVersion=" > /var/state/downloadreport
sed -n 's/^firmware_version: \(.*\)/\1/p' /etc/version >> /var/state/downloadreport
touch /var/state/perfcounters
chown nobody /var/state/perfcounters
echo 0 > /var/state/debugmode

chmod 664 /var/state/debugmode
chown root:gui /var/state/debugmode

echo "${sname}: network config"

if [ "${CFG_modemtype}" -eq 13 ]; then
    ip link set name mac0 dev eth0
    ip link set name eth0 dev eth1
fi

if [ "${norf_halsim}" = "y" ]; then
	#do this before modem controller starts
	vconfig add eth0 4000
	ifconfig eth0.4000 10.110.104.102 netmask 255.255.255.0 broadcast 10.110.104.255 up
fi

#revert to default firewall config
/usr/local/bin/stop_firewall *IPTKEY:FW*

#revert to default network
/usr/local/bin/stop_network

# Tellishape needs 4 MB socket buffers for its system, host_ipv4 and host_ipv6 interfaces
/sbin/sysctl -w net.core.rmem_max=$((4 * 1024 * 1024))
/sbin/sysctl -w net.core.wmem_max=$((4 * 1024 * 1024))

## Netring ring buffer configuration
# Eth0 needs to be up for configuring ring buffers.
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
#AMC5001 eth1
if [ "${CFG_modemtype}" -eq 11 ]; then
	eth1addr=`sed -n "s/^eth1addr=\(.*\)/\1/p" /var/state/cfg`
	if [ -z "$eth1addr" ]; then
		eth1addr=00:0D:2E:00:42:01
	fi
	ip link set eth1 down
	ip link set eth1 address $eth1addr
	ip link set eth1 mtu 8000 up
	/usr/local/bin/set_ring_buffers.sh eth1 64 256
fi

# Set netring filter for eth0, to prevent unwanted traffic in Linux when no network is configured for the native interface.
# Eth0 needs to be up for configuring netring related settings.
/sbin/ip link set dev eth0 up
echo "any_arp,system,multi_ip4_igmp,multi_ip6_mld" > /sys/class/net/eth0/netring_host_filter

echo "${sname}: create tun interfaces"
/usr/local/sbin/tunctl -n -t tun2
#/sbin/ifconfig tun2 -arp 169.254.0.2

echo "${sname}: modprobe"

modprobe ntc-switch
for i in 0 1; do
	if test $(ls -d /sys/devices/switch${i}.* 2>/dev/null | wc -l) -eq 1; then
		ln -s /sys/devices/switch${i}.* /var/state/switch${i}
	fi
done

/sbin/modprobe fwloader

#modprobe fpga is technically not necessary, as it will be probed before digital_rx
/sbin/modprobe fpga
/sbin/modprobe digital_rx
/sbin/modprobe packet_engine
/sbin/modprobe gse_tx
/sbin/modprobe tx_netdev
/sbin/modprobe rx_netdev

. /etc/platform_modem_netdev.sh

#args: type mode
set_devices_up()
{
	for d in $(ls -1 ${net_devices_path}); do
		local ntdv="${net_devices_path}/${d}/modem_netdev"
		if [ -d "${ntdv}" ]; then
			local mode=$(cat "${ntdv}/mode")
			local type=$(cat "${ntdv}/type")
			if [ "${type}" == "${1}" -a "${mode}" == "${2}" ]; then
				echo "ip link set ${d} up"
				ip link set ${d} up
			fi
		fi
	done
}
#args: type mode filter
set_devices_up_filter()
{
	for d in $(ls -1 ${net_devices_path}); do
		local ntdv="${net_devices_path}/${d}/modem_netdev"
		if [ -d "${ntdv}" ]; then
			local mode=$(cat "${ntdv}/mode")
			local type=$(cat "${ntdv}/type")
			if [ "${type}" == "${1}" -a "${mode}" == "${2}" ]; then
				echo "ip link set ${d} up"
				ip link set ${d} up
				echo "${3}" > "${net_devices_path}/${d}/netring_host_filter"
			fi
		fi
	done
}
set_bbfoip_devices_up()
{
	for d in $(ls -1 ${net_devices_path}); do
		local ntdv="${net_devices_path}/${d}/modem_netdev"
		if [ -d "${ntdv}" ]; then
			local mode=$(cat "${ntdv}/mode")
			local type=$(cat "${ntdv}/type")
			if [ "${type}" == "bbfoip" -a "${mode}" == "rx" ]; then
				echo "ip link set ${d} up"
				ip link set ${d} up
				echo "${3}" > "${net_devices_path}/${d}/netring_host_filter"
				echo 1 > "${net_devices_path}/${d}/disable_ipv6"
			fi
		fi
	done
}

set_devices_up layer2 tx
#All layer 2 traffic needs to be handled by Tellishape, so no reason to forward anything to Linux.
set_devices_up_filter layer2 rx ""

if [ ! -z "$modemipaddr" ]; then
	set_devices_up generic tx
	set_sig_demod_devices_up
fi

set_bbfoip_devices_up

if [ "$ethswupgrade" != "1" ]; then
  if [ -c /dev/img0 ] && [ -c /dev/img1 ]; then
  echo "${sname}: software download"
  /usr/local/bin/start_swdownload &
  else
    echo "${sname}: no software download"
  fi
  #start DHCP now
  /usr/local/bin/init_dnsdhcp
  #add some default firewall rules
  /usr/local/bin/init_firewall *IPTKEY:FW*

  /usr/local/bin/init_httpd_config
  /usr/sbin/inetd
else
  echo "${sname}: eth software download"
  /usr/local/bin/init_httpd_config
  /usr/sbin/inetd
  /usr/sbin/iptables -P INPUT ACCEPT
  /usr/local/bin/start_ethswdownload &
  sed -i 's/ethswupgrade=[01]/ethswupgrade=0/' /var/state/cfg
  /usr/local/bin/writecfg
fi

set_devices_up_filter multicast rx ""

set_devices_up_filter unicast rx ""

echo "${sname}: check presence of external router board"
/usr/local/bin/init_routerboard

# also support factory reset when routercontroller_supported=2
# so that config files on the Marvell are always removed
if [ "${CFG_routercontroller_supported}" -eq 1 -o "${CFG_routercontroller_supported}" -eq 2 ]; then
    if [ -n "$factoryreset" -a "$factoryreset" = "1" ]; then
        # since 4.2.0 (saving on modem board was necessary because miniITX board of MDM5010 had no storage)
        rm -rf /mnt/config/segment4

        # 4.1.0: seg4 settings were saved on addin board
        # doing factory reset of addin board is done by modemcontroller SMS-5600
    fi
fi

/usr/local/bin/routerboard-uptime-check.sh || true

echo "${sname}: start snmpd"
/usr/local/bin/init_snmpd 0

echo "${sname}: start modem_controller"
/usr/local/bin/is_multi_core.sh && START="schedtool -a 0x1 -e "
#/usr/bin/valgrind --log-file=/tmp/mc_valgrind.log /usr/local/bin/modem_controller
${START:=""} /usr/local/bin/modem_controller

/usr/local/sbin/setclock

echo "${sname}: start watchdog services"
# SMS-7264: In the case that MOOB is enabled and no previous valid config is present,
# the modem should wait at the end of the MOOB state indefinitely.
#In this case we don't want to start the TelliNet watchdog check since TelliNet will not be running.
parse_moob_enabled
parse_moob_config_valid
enable_tellinet_check="1"
if [ "${moob_enabled}" = "1" ] && [ "${CFG_moob_config_valid}" = "0" ]; then
	logger -t $0 -p daemon.info "Not starting TelliNet watchdog check since MOOB is enabled and has no previous valid config."
	enable_tellinet_check="0"
fi
/bin/nice -n +10 /usr/local/bin/rc_init_watchdog.sh "${enable_tellinet_check}"

# make firewall less strict for debugging. (default: commented out)
parse_debugmode
if [ "${CFG_debugmode}" -eq 1 ]; then
	echo "${sname}: activate debug mode"
	/usr/local/bin/set_debug_mode activate
fi

# start ssh daemon (optionally)
parse_startssh
if [ "${CFG_startssh}" -eq 1 ]; then
	echo "${sname}: start ssh daemon"
  . /usr/local/bin/ssh_commands.sh
  start_ssh
fi

#uncomment when you've installed a predetermined keyset in the /root/.ssh
# /usr/sbin/dropbear -r /root/.ssh/dropbear_rsa_host_key

# outexec script
cat /var/state/cfg | grep autoexec | sort | sed 's/[^=]*=//' > /autoexec
if [ -s /autoexec ]; then
    logger "******* UNSUPPORTED DEMO VERSION *******"
fi
chmod +x /autoexec
/autoexec

# Create a file with the physical address of eth0 already in OCTET STRING for snmp-client-interfaces.sh scripted
touch /tmp/snmp-eth0-addr
ifPhysAddress=""
ifAddressLen=`cat /sys/class/net/eth0/addr_len`
if [ "$ifAddressLen" -gt "0" ] ; then
    ifAddress=`cat /sys/class/net/eth0/address`
    i="1"
    while [ "$i" -le "$ifAddressLen" ] ; do
        ifByte=`echo $ifAddress | cut -d':' -f$i`
        ifPhysAddress=`echo -e "$ifPhysAddress\x$ifByte"`
        i=`expr $i + 1`
    done
fi
echo "$ifPhysAddress" >> /tmp/snmp-eth0-addr

if [ "${norf_halsim}" = "y" ]; then
	#do again, netmask seems lost by now
	ifconfig eth0.4000 10.110.104.102 netmask 255.255.255.0 broadcast 10.110.104.255 up
	route add -net 239.192.0.0/16 dev eth0.4000
	ip route add 10.6.0.109/32 via 10.110.104.101
	/usr/local/bin/set_debug_mode activate
fi

# SMS-3597
# use of setsid would be best (or adding a disown)
nohup /bin/nice -n +20 /usr/local/bin/set_router_datetime </dev/null >/dev/null 2>&1 &

if [ "${CFG_modemtype}" -eq 9 -o "${CFG_modemtype}" -eq 15 ]; then
	/usr/local/bin/calibrate_spirit_temperature.sh &
fi

# monitors eht0 in case it stalls and restarts the interface. Only for 3310 for the moment
if [ "${CFG_modemtype}" -eq 12 ]; then
  /usr/local/bin/check_eth_stall.sh &
fi

echo "${sname}: completed"

