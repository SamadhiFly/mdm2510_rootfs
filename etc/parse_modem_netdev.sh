#!/bin/sh

net_devices_path="/sys/devices/virtual/net"

#args: type mode
find_modem_netdev_netdev()
{
	local result=""
	for d in $(ls -1 ${net_devices_path}); do
		local ntdv="${net_devices_path}/${d}/modem_netdev"
		if [ -d "${ntdv}" ]; then
			local mode=$(cat "${ntdv}/mode")
			local type=$(cat "${ntdv}/type")
			if [ "${type}" == "${1}" -a "${mode}" == "${2}" ]; then
				result="${result} ${d}"
			fi
		fi
	done
	echo "${result}"
}

modem_netdev_generic_mod=$(cat "/etc/generic_mod")
modem_netdev_sig_demod=$(cat "/etc/sig_demod")
modem_netdev_sig_demods=$(find_modem_netdev_netdev "signal" "rx")
