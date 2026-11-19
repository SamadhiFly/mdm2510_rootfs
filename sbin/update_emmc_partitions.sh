#!/bin/sh
die()
{
	echo $@
	exit 1
}

# preparation of eMMC partitions
################################
partition_emmc()
{
echo adding partitions to eMMC
fdisk /dev/mmcblk0 <<EOF
d
4
n
e


n

+230M
n

+230M
n

+230M
n

+230M
w
EOF
}

try_partition_emmc()
{
	echo "Check eMMC partitions"
	num_partitions=$(fdisk -l /dev/mmcblk0 | grep mmcblk0p | wc -l)

	if [ "${num_partitions}" != "8" ]; then
		partition_emmc || die "cannot update emmc partitions"
	fi
}

try_partition_emmc
