#!/bin/sh

source /sbin/env_processing.source

commit_current_software()
{
    runningbuild=$(get_cmdline_var activebuild)
    runningmode=$(get_cmdline_var selMode)
    runningslot=$(get_cmdline_var selSlot)

    update_uboot_var activebuild ${runningbuild}
    update_uboot_var activemode ${runningmode}
    update_uboot_var activeslot_mode${runningmode} ${runningslot}
    update_uboot_var tryotherbuild 0
    update_uboot_var tryotherslot 0
    update_uboot_var trymode ${runningmode}
    update_uboot_var per_upgrade_failure no
    update_uboot_var per_forced_upgrade no
}

commit_legacy_software()
{
    runningbuild=$(get_cmdline_var activebuild)

    update_uboot_var activebuild ${runningbuild}
    update_uboot_var tryotherbuild 0
    update_uboot_var per_upgrade_failure no
    update_uboot_var per_forced_upgrade no
}

tried_something_different=$(get_cmdline_var tryotherbuild):$(get_cmdline_var ModeChanged):$(get_cmdline_var SlotChanged)

case "${tried_something_different}" in
    0:0:0|0::)
    ;;
    1::)
        execute_with_cfg_lock commit_legacy_software
    ;;
    *)
        execute_with_cfg_lock commit_current_software
    ;;
esac
