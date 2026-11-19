#!/bin/sh

sname=`basename "$0"`

# Enable coredumps
ulimit -c unlimited
echo '|/usr/local/bin/coredumper -e=%e -p=%p -s=%s -t=%t -d=/tmp/coredumps' > /proc/sys/kernel/core_pattern
echo "rc.sh: configure hotplug firmware loading"
/sbin/mdev -s
echo /sbin/mdev > /proc/sys/kernel/hotplug

test -f /usr/local/bin/partition_qspi_flash.sh && /usr/local/bin/partition_qspi_flash.sh

echo "rc.sh: mount everything"
mkdir /dev/pts
mkdir /dev/shm
chmod 664 /dev/urandom
/bin/mount -a

echo "rc.sh: configure loopback"
ip addr add 127.0.0.1/8 dev lo
ip link set lo up

echo "rc.sh: configure initial file structure"
>/etc/mtab
>/etc/net-client.ini
>/etc/ntp.conf
>/etc/modprobe.conf
echo 0 >/etc/mgroup.conf
chmod 664 /etc/mgroup.conf
chown root:gui /etc/mgroup.conf
cat /etc/hosts.templ > /etc/hosts
mkdir -p /var/lib/ntp
mkdir -p /lib/oprofile
mkdir /var/state
chmod 774 /var/state
chown root:gui /var/state
mkdir /var/net-snmp
mkdir /etc/snmp

# spi-mux must be loaded before trying to access the spi flash!
modprobe spi_barco_orka_mux_gpio

# create working dir for TelliShape and TelliNet (SMS-6462)
mkdir /tmp/tellitec

# create dir for coredumps
mkdir /tmp/coredumps

# arp_tables must be loaded before normal users (like httpd) can use /sbin/arptables
modprobe arp_tables


echo "rc.sh: configure /dev stuff"
ln -sf fb0 /dev/fb
ln -sf flasha1 /dev/flash_monitor
ln -sf flasha2 /dev/flash_kernel
ln -sf flasha3 /dev/flash_environment
ln -sf flasha4 /dev/flash_reserved
ln -sf null /dev/mouse

mount_create_jffs2() {
	MTD="$1"
	MNT="$2"
	shift;
	shift;

	echo "FLASH: mount $MTD on $MNT"
	if ! mount -tjffs2 $MTD $MNT "$@"; then
		echo "FLASH: erase /dev/$MTD" >&2
		flash_eraseall -j /dev/$MTD
		if ! mount -tjffs2 $MTD $MNT "$@"; then
			RET=$?
			echo "FLASH: mount /dev/$MTD on $MNT failed!"
			return $RET
		fi
	fi
}

# deal with MTD partitions
sed /proc/mtd -e "/^dev:/d" -e "s/:.* / /g" -e "s/\"//g" | while read MTD NAME; do
	case "$NAME" in
	fpga*)
		# Danger! don't replace /dev/fpgaX
		ln -sf $MTD /dev/mtd${NAME}
		;;
	config)
		ln -sf $MTD /dev/$NAME
		mkdir -p /mnt/$NAME
		mount_create_jffs2 $MTD /mnt/$NAME -o rw,sync
		;;
	pactest)
		ln -sf $MTD /dev/$NAME
		mkdir -p /mnt/$NAME
		mount_create_jffs2 $MTD /mnt/$NAME -o ro
		;;
	calibration)
		ln -sf $MTD /dev/$NAME
		mkdir -p /mnt/cal
		mount_create_jffs2 $MTD /mnt/cal -o ro
		;;
	spi*)
		;;
	*)
		if [ "$NAME" != "img1a" ] && [ "$NAME" != "img1b" ]; then # these are concatenated on the MDM2210 to img1 and should be left out in the symbolic links MODSWFW-3834
			ln -sf $MTD /dev/$NAME
		fi
		;;
	esac
done

NEEPROM=0
\ls /sys/bus/i2c/devices/?-*/eeprom 2> /dev/null | while read EEPROM; do
	echo "rc.sh: symlink /dev/eeprom${NEEPROM} -> $EEPROM"
	ln -s $EEPROM /dev/eeprom$NEEPROM
	NEEPROM=$(( $NEEPROM + 1 ))
done

echo "rc.sh: shadow flash cfg to ram"
/usr/local/bin/readcfg
chmod 664 /var/state/cfg
chown root:gui /var/state/cfg

# grab user parameters
# copy pid1's environment to a regular file since
# modemconfigtool is confused on the filesize (try to stat /proc/1/environ).
cp /proc/1/environ /tmp/environ1
/usr/sbin/modemconfigtool read -o default /tmp/environ1 > /var/state/cmdlineconfig
rm /tmp/environ1

# /var/state/cfg needs to be available at this point.
. /usr/local/bin/parse_var_state_cfg.sh
parse_berlin_test
parse_modemtype

# kick watchdog early
# On AMC5001 the watchdog is always enabled
if [ "${CFG_modemtype}" -eq 11 ]; then
	if [ -c /dev/kmsg ]; then
		echo "<1>Early kick watchdog" > /dev/kmsg
		echo "<1>Next 'Watchdog did not stop' message is normal" > /dev/kmsg
	fi
	# even better is to set the watchdog timeout here ...
	echo "1" > /dev/watchdog
fi

if [ "${CFG_berlin_test}" -eq 1 ]; then
	echo "${sname}: Setting up the Berlin test bed"
else
	echo "${sname}: Setting up normal environment"
fi

if [ "${CFG_berlin_test}" -ne 1 ]; then
	/etc/rc_operational.sh
else
	/etc/rc_berlin_testbed.sh
fi

