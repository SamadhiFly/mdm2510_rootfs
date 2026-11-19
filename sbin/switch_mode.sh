#!/bin/sh

source /sbin/env_processing.source

find_mode()
{
	requested_mode_str=$1
	num_modes=$(get_uboot_var numbermodes)
	for mode in $(seq 0 $((num_modes-1))); do
		mode_str=$(get_uboot_var mode_${mode})
		if [ "${requested_mode_str}" == "${mode_str}" ]; then
			echo ${mode}
			return 0
		fi
	done
	return 1
}

do_mp_mode_change()
{
	if upgrade_in_progress; then
		exit 2
	fi
	
	requested_mode_str=$1
	requested_slot_str=$2
	mode=$(find_mode ${requested_mode_str})

	if test $? -eq 0 ; then
		update_uboot_var trymode ${mode}
	else
		exit 1
	fi

	if [ "${requested_slot_str}" != "active" ]; then
		update_uboot_var tryotherslot 1
	fi

}

do_sp_bank_switch()
{
	if upgrade_in_progress; then
		exit 2
	fi
	update_uboot_var tryotherbuild 1
}

if [ "$1" == "legacy" ]; then
	execute_with_cfg_lock do_sp_bank_switch
elif is_mp_supported; then
	execute_with_cfg_lock do_mp_mode_change $1 $2
elif [ "$2" != "active" ]; then
	execute_with_cfg_lock do_sp_bank_switch
fi
