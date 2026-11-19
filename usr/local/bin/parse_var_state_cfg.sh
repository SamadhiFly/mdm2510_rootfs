#!/bin/sh

# parse_var_state_cfg.sh
#
#   Created on: Feb 2, 2018
#
# To be sourced if you are interested in any of the settings in "${CFGFILE}".
#
# varname (as used in "${CFGFILE}") is translated into CFG_varname (as a means of variable scoping / preventing name clashes).
#
# TODO: Make parsing more efficient.
# TODO: Make a seperate module to generate capability-variables based on modemtype.

if [ "$#" -ne 1 -o ! -r "$1" ]; then
  CFGFILE="/var/state/cfg"
else
  CFGFILE="$1"
fi

parse_modemtype()
{
  # S3P                = 0
  # D1                 = 1
  # S3PCOSTIMPROVED    = 2
  # S3PACMREADY        = 3
  # DX                 = 4
  # M1                 = 5
  # SIM                = 6
  # MDM2500            = 7
  # MDM5000            = 8
  # MDM2210            = 9
  # MDM2510            = 10
  # AMC5001            = 11
  # MDM3310            = 12
  # MDM5010            = 13
  # MDM2010            = 15

  if [ -n "${CFG_modemtype}" ]; then
    return
  fi

  CFG_modemtype="$(sed -n "s/^modemtype=\([0-9]*\)/\1/p" "${CFGFILE}")"
  [ -n "${CFG_modemtype}" ] || CFG_modemtype=0
}

parse_berlin_test()
{
  if [ -n "${CFG_berlin_test}" ]; then
    return
  fi
  CFG_berlin_test="$(sed -n "s/^berlin_test=\([0-9]*\)/\1/p" "${CFGFILE}")"
  [ -n "${CFG_berlin_test}" ] || CFG_berlin_test=0
}

parse_startssh()
{
	if [ -n "${CFG_startssh}" ]; then
    return
  fi
	CFG_startssh="$(sed -n 's/^startssh=\([01]\)/\1/p' "${CFGFILE}")"
  [ -n "${CFG_startssh}" ] || CFG_startssh=0
}

parse_wdenable()
{
	if [ -n "${CFG_wdenable}" ]; then
    return
  fi
	parse_berlin_test
	if [ "${CFG_berlin_test}" -eq 1 ]; then
		CFG_wdenable=0
	else
		CFG_wdenable="$(sed -n 's/^wdenable=\([01]\)/\1/p' "${CFGFILE}")"
	  [ -n "${CFG_wdenable}" ] || CFG_wdenable=0
	fi
}

parse_routercontroller_supported()
{
  if [ -n "${CFG_routercontroller_supported}" ]; then
    return
  fi

  # Check if routercontroller_supported = 1 (supported, normal mode) or 2 (supported, bridged mode)
  CFG_routercontroller_supported="$(sed -n 's/^routercontroller_supported=\([012]\)/\1/p' "${CFGFILE}")"
  [ -n "${CFG_routercontroller_supported}" ] || CFG_routercontroller_supported=0

  # TODO: Does not belong here
  if [ "${CFG_routercontroller_supported}" -eq 1 ]; then
      . /usr/local/bin/ifcfg_local_mgmt.sh
  fi
}

parse_debugmode()
{
  if [ -n "${CFG_debugmode}" ]; then
    return
  fi
	CFG_debugmode="$(sed -n 's/^debugmode=\([01]\)/\1/p' "${CFGFILE}")"
  [ -n "${CFG_debugmode}" ] || CFG_debugmode=0
}

# TODO: Remove after finishing MDM5010 development.
parse_enable_rescue_if()
{
  if [ -n "${CFG_enable_rescue_if}" ]; then
    return
  fi

  CFG_enable_rescue_if="$(sed -n 's/^enable_rescue_if=\([01]\)/\1/p' "${CFGFILE}")"
  [ -n "${CFG_enable_rescue_if}" ] || CFG_enable_rescue_if=0

}

# TODO: Move to capabilities-module
parse_tellinet_on_addin_board()
{
  if [ -n "${tellinet_on_addin_board}" ]; then
    return
  fi

  parse_modemtype

  # Tellinet on add-in board.
  if [ "${CFG_modemtype}" -eq 13 ]; then
    tellinet_on_addin_board=1
  else
    tellinet_on_addin_board=0
  fi
}

# TODO: Move to capabilities-module
parse_tellishape_on_addin_board()
{
  if [ -n "${tellishape_on_addin_board}" ]; then
    return
  fi

  parse_modemtype

  # Tellishape on add-in board.
  if [ "${CFG_modemtype}" -eq 13 ]; then
    tellishape_on_addin_board=1
  else
    tellishape_on_addin_board=0
  fi
}

parse_moob_enabled()
{
  if [ -n "${moob_enabled}" ]; then
    return
  fi
  moob_enabled="$(sed -n 's/^moob_enabled=\([0-9*]\)/\1/p' "${CFGFILE}")"
  [ -n "${moob_enabled}" ] || moob_enabled=0
}

parse_moob_config_valid()
{
  if [ -n "${CFG_moob_config_valid}" ]; then
    return
  fi
  CFG_moob_config_valid="$(sed -n 's/^moob_config_valid=\([0-9*]\)/\1/p' "${CFGFILE}")"
  [ -n "${CFG_moob_config_valid}" ] || CFG_moob_config_valid=0
}

parse_moob_config_server_url()
{
  if [ -n "${moob_config_server_url}" ]; then
    return
  fi
  moob_config_server_url="$(sed -n 's/^moob_config_server_url=\(\)/\1/p' "${CFGFILE}")"
}


parse_ipaddr()
{
  if [ -n "${CFG_ipaddr}" ]; then
    return
  fi
  CFG_ipaddr="$(sed -n "s/^ipaddr=\(.*\)$/\1/p" "${CFGFILE}")"
}

parse_netmask()
{
  if [ -n "${CFG_netmask}" ]; then
    return
  fi
  CFG_netmask="$(sed -n "s/^netmask=\(.*\)$/\1/p" "${CFGFILE}")"
}

parse_dropbear_authkey()
{
  if [ -n "${CFG_dropbear_authkey}" ]; then
    return
  fi

  CFG_dropbear_authkey="$(sed -n 's/^dropbear_authkey=\([a-z]\)/\1/p' "${CFGFILE}")"
}

parse_verify()
{
  if [ -n "${CFG_verify}" ]; then
    return
  fi
  CFG_verify="$(sed -n "s/^verify=\(.*\)$/\1/p" "${CFGFILE}")"
}

parse_tryotherbuild()
{
  if [ -n "${CFG_tryotherbuild}" ]; then
    return
  fi
  CFG_tryotherbuild="$(sed -n "s/^tryotherbuild=\(.*\)$/\1/p" "${CFGFILE}")"
}

parse_active_build()
{
  if [ -n "${CFG_active_build}" ]; then
    return
  fi
  CFG_active_build="$(sed -n "s/^activebuild=\(.*\)$/\1/p" "${CFGFILE}")"
}
