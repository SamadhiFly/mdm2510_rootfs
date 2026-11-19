#!/bin/sh

new_image=$1

if /sbin/is_confirmation_pending.sh; then
	exit 2
fi

if /sbin/modeswitch_or_upgrade_in_progress.sh; then
	exit 2
fi

if ! /sbin/personalities/dlg/validate_installer.sh ${new_image}; then
	exit 4
fi

if ! /sbin/personalities/dlg/is_compatible_installer.sh ${new_image}; then
	exit 3
fi

#This was introduced by MODSWFW-4135 to avoid downgrading to versions lower than 4.6.5 on MD5010 HW-02
hwid=$(/sbin/get_hardwareid.sh | sed -e 's#.*=\(\)#\1#')
image_version=$(/sbin/personalities/dlg/version_info_installer.sh ${new_image})
image_version_sort=$(printf "${image_version}\n4.6.5.0\n" | sort | head -n 1)

if [ "$hwid" = "0x0241" ] && [ "$image_version_sort" != "4.6.5.0" ]; then
	exit 3
fi

/usr/local/bin/populate_bank $new_image &>/dev/null

if [ $? != 0 ]; then
	exit 1   #writing to flash failed
fi

# Tell swdownload to rewrite /var/state/downloadreport
killall -HUP swdownload 2>/dev/null 1>/dev/null

exit 0
