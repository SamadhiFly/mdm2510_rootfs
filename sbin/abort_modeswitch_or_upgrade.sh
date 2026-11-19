#!/bin/sh

source /sbin/env_processing.source

abort_upgrade()
{
        if [ "$(get_uboot_var tryotherbuild)" == "1" ]; then
                update_uboot_var tryotherbuild 0
        fi
        if [ "$(get_uboot_var tryotherslot)" == "1" ]; then
                update_uboot_var tryotherslot 0
        fi
        activemode=$(get_uboot_var activemode)
        if [ "${activemode}" != "$(get_uboot_var trymode)" ]; then
                update_uboot_var trymode ${activemode}
        fi
}

execute_with_cfg_lock abort_upgrade

