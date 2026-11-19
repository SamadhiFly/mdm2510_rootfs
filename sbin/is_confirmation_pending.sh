#!/bin/sh

source /sbin/env_processing.source

check_confirmation_pending()
{
    runningbuild=$(get_cmdline_var activebuild)
    runningmode=$(get_cmdline_var selMode)
    runningslot=$(get_cmdline_var selSlot)

    configuredbuild=$(get_uboot_var activebuild)
    configuredMode=$(get_uboot_var activemode)
    configuredSlot=$(get_uboot_var activeslot_mode${runningmode})

    test "${runningbuild}:${runningmode}:${runningslot}" != "${configuredbuild}:${configuredMode}:${configuredSlot}"
}

check_confirmation_pending_legacy()
{
    runningbuild=$(get_cmdline_var activebuild)
    configuredbuild=$(get_uboot_var activebuild)

    test "${runningbuild}" != "${configuredbuild}"
}

tried_something_different=$(get_cmdline_var tryotherbuild):$(get_cmdline_var ModeChanged):$(get_cmdline_var SlotChanged)

case "${tried_something_different}" in
    *::)
        execute_with_cfg_lock check_confirmation_pending_legacy
    ;;
    *:*:*)
        execute_with_cfg_lock check_confirmation_pending
    ;;
esac
