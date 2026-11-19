. /etc/parse_modem_netdev.sh

set_sig_demod_devices_up()
{
	for demod in ${modem_netdev_sig_demods}; do
		echo "system" > "${net_devices_path}/${demod}/netring_host_filter"
		ip addr add ${modemipaddr}/32 dev ${demod}
		ip link set dev ${demod} up
	done
}
