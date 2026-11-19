#!/bin/sh

case "$1" in
start)
	# find keymap
	read MANF MODEL REST < /proc/device-tree/model
	MAPFILE=/etc/inputevent-${MODEL}.conf
	CHARDEV="$2"

	if ! [ -r "$MAPFILE" ]; then
		exit 0
	fi

	if ! [ -c "$CHARDEV" ]; then
		echo "$0: $CHARDEV is not a chardev" >&2
		exit 1
	fi
	# Launch program
	echo "rc.sh: Start log on $CHARDEV"
	exec inputevent -0 -m "$MAPFILE" "$CHARDEV" "$0" logger
	;;
logger)
	while read TIME CODE VALUE; do
	case "$CODE:$VALUE" in
	SYN_*)
		# ignore
		;;
	*)
		echo "INFO: $CODE $VALUE"
		;;
	esac
	done 2>&1 | logger -s -p local1.info -t inputs
	;;
esac



