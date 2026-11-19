#!/bin/sh

. /usr/local/bin/parse_var_state_cfg.sh
parse_dropbear_authkey

start_ssh() {
		umask 077
    
		if [ -z "${CFG_dropbear_authkey}" ]; then
        echo "The ssh key was not present in the flash"
    else
        cp -pr /root /tmp/root
        if [ ! -d "/tmp/root/.ssh" ]; then
						if [ -e "/tmp/root/.ssh" ]; then
								rm -rf "/tmp/root/.ssh"
						fi
            mkdir /tmp/root/.ssh
        fi
        mount --bind /tmp/root /root
        echo "${CFG_dropbear_authkey}" >> /tmp/root/.ssh/authorized_keys
    fi
    
		#/usr/bin/dropbearkey -t rsa -f /tmp/dropbear_rsa_host_key
		#/usr/sbin/dropbear -r /tmp/dropbear_rsa_host_key

		# Use fixed key in default location (/etc/dropbear/dropbear_rsa_host_key) so that scp's from the routerboard would recognize us
		/usr/sbin/dropbear

		# Open up firewall, otherwise this whole thing is pretty useless.
		iptables -A INPUT -p tcp --dport 22 -j ACCEPT
		iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT
}

