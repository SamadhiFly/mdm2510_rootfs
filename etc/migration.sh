#!/bin/sh
#
# migration.sh
#
# migrate /var/state/cfg data

. /usr/local/bin/parse_var_state_cfg.sh

ipaddr=`sed -n "s/^ipaddr=\(.*\)$/\1/p" /var/state/cfg`
netmask=`sed -n "s/^netmask=\(.*\)$/\1/p" /var/state/cfg`

syslogmode=`sed -n "s/^syslogmode=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$syslogmode" ]; then
  syslogmode=0
  echo "syslogmode=$syslogmode" >> /var/state/cfg
fi

if [ "$syslogmode" = "2" ]; then
  #automatic not supported any more, turn it off
  sed -i "s/^syslogmode=.*/syslogmode=0/g" /var/state/cfg
fi

syslogport=`sed -n "s/^syslogport=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$syslogport" ]; then
  syslogport=514
  echo "syslogport=$syslogport" >> /var/state/cfg
fi

syslogaddr=`sed -n "s/^syslogaddr=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$syslogaddr" ]; then
  syslogaddr=$ipaddr
  echo "syslogaddr=$syslogaddr" >> /var/state/cfg
fi

syslogsize=`sed -n "s/^syslogsize=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$syslogsize" ]; then
  syslogsize=256
  echo "syslogsize=$syslogsize" >> /var/state/cfg
fi

ethswupgrade=`sed -n "s/^ethswupgrade=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$ethswupgrade" ]; then
  ethswupgrade=0
  echo "ethswupgrade=$ethswupgrade" >> /var/state/cfg
fi

modemipaddr=`sed -n "s/^modemipaddr=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$modemipaddr" ]; then
    modemipaddr="10.1.0.1"
    echo "modemipaddr=$modemipaddr" >> /var/state/cfg
fi

modemtype=`sed -n "s/^modemtype=\(.*\)/\1/p" /var/state/cfg`
if [ -z "$modemtype" ]; then
    modemtype=0
    echo "modemtype=$modemtype" >> /var/state/cfg
fi

#A few calls are now part of mobility thus if installedit is set and mobedit not yet we need to migrate
# the value to keep the authorization level consistent after an upgrade (MODSWFW-4064)
installedit=$(sed -n "s/^installedit=\(.*\)$/\1/p" /var/state/cfg)
mobedit=$(sed -n "s/^mobedit=\(.*\)$/\1/p" /var/state/cfg)
if [[ -z "$mobedit" && -n "$installedit" ]] ; then
    if [[ "$installedit" == "normal" || "$installedit" == "expert" || "$installedit" == "admin" ]] ; then
        echo "mobedit=$installedit" >> /var/state/cfg
    fi
fi

#initial transponder settings
trppref=`sed -n "s/^trppref=\(.*\)$/\1/p" /var/state/cfg`

trpfreq=`sed -n "s/^trpfreq=\(.*\)$/\1/p" /var/state/cfg`
trpgenmode=`sed -n "s/^trpgenmode=\(.*\)$/\1/p" /var/state/cfg`
trppol=`sed -n "s/^trppol=\(.*\)$/\1/p" /var/state/cfg`
trpsr=`sed -n "s/^trpsr=\(.*\)$/\1/p" /var/state/cfg`

#Carrier Selection Data
trppopid=`sed -n "s/^trppopid=\(.*\)$/\1/p" /var/state/cfg`
carselrmttsid=`sed -n "s/^carselrmttsid=\(.*\)$/\1/p" /var/state/cfg`
carselrmtserviceid=`sed -n "s/^carselrmtserviceid=\(.*\)$/\1/p" /var/state/cfg`

#2nd initial transponder settings
trp2freq=`sed -n "s/^trp2freq=\(.*\)$/\1/p" /var/state/cfg`
trp2genmode=`sed -n "s/^trp2genmode=\(.*\)$/\1/p" /var/state/cfg`
trp2pol=`sed -n "s/^trp2pol=\(.*\)$/\1/p" /var/state/cfg`
trp2sr=`sed -n "s/^trp2sr=\(.*\)$/\1/p" /var/state/cfg`


if [ -z "$trppref" ]; then
   trppref="1"
   echo "trppref=$trppref" >> /var/state/cfg
fi
if [ -z "$trpfreq" ]; then
   trpfreq="111370000"
   echo "trpfreq=$trpfreq" >> /var/state/cfg
fi
if [ -z "$trpgenmode" ]; then
   trpgenmode="2"
   echo "trpgenmode=$trpgenmode" >> /var/state/cfg
fi
if [ -z "$trppol" ]; then
   trppol="1"
   echo "trppol=$trppol" >> /var/state/cfg
fi
if [ -z "$trpsr" ]; then
   trpsr="220000"
   echo "trpsr=$trpsr" >> /var/state/cfg
fi
if [ -z "$trppopid" ]; then
   trppopid="0"
   echo "trppopid=$trppopid" >> /var/state/cfg
fi
if [ -z "$carselrmttsid" ]; then
   carselrmttsid="0"
   echo "carselrmttsid=$carselrmttsid" >> /var/state/cfg
fi
if [ -z "$carselrmtserviceid" ]; then
   carselrmtserviceid="0"
   echo "carselrmtserviceid=$carselrmtserviceid" >> /var/state/cfg
fi

if [ -z "$trp2freq" ]; then
   trp2freq="0"
   echo "trp2freq=$trp2freq" >> /var/state/cfg
fi
if [ -z "$trp2genmode" ]; then
   trp2genmode="2"
   echo "trp2genmode=$trp2genmode" >> /var/state/cfg
fi
if [ -z "$trp2pol" ]; then
   trp2pol="1"
   echo "trp2pol=$trp2pol" >> /var/state/cfg
fi
if [ -z "$trp2sr" ]; then
   trp2sr="0" 
   echo "trp2sr=$trp2sr" >> /var/state/cfg
fi

#pointing transponder settings
acutype=`sed -n "s/^acutype=\(.*\)$/\1/p" /var/state/cfg`
if [ -n "$acutype" ]; then # not supported anymore
  sed -i "s#^acutype=.*##" /var/state/cfg
  grep -v "^ *$" /var/state/cfg > /var/state/cfg_new	#remove empty line
  mv /var/state/cfg_new /var/state/cfg
  sed -i "s#^ptstatus=.*#ptstatus=1#" /var/state/cfg
fi

ptstatus=`sed -n "s/^ptstatus=\(.*\)$/\1/p" /var/state/cfg`
ptenabled=`sed -n "s/^ptenabled=\(.*\)$/\1/p" /var/state/cfg`
ptpref=`grep "ptpref" /var/state/cfg | sed -n "s/^ptpref=\(.*\)$/\1/p" `
ptgenmode=`grep "ptgenmode" /var/state/cfg | sed -n "s/^ptgenmode=\(.*\)$/\1/p"`
ptfreq=`grep "ptfreq" /var/state/cfg | sed -n "s/^ptfreq=\(.*\)$/\1/p" `
ptpol=`grep "ptpol" /var/state/cfg | sed -n "s/^ptpol=\(.*\)$/\1/p" `
ptsr=`grep "ptsr" /var/state/cfg |sed -n "s/^ptsr=\(.*\)$/\1/p" `
ptorbpos=`grep "ptorbpos" /var/state/cfg | sed -n "s/ptorbpos=\(.*\)$/\1/p" `
ptweflag=`grep "ptweflag" /var/state/cfg | sed -n "s/ptweflag=\(.*\)$/\1/p" `
pt2genmode=`grep "pt2genmode" /var/state/cfg | sed -n "s/^pt2genmode=\(.*\)$/\1/p"`
pt2freq=`grep "pt2freq" /var/state/cfg | sed -n "s/^pt2freq=\(.*\)$/\1/p" `
pt2pol=`grep "pt2pol" /var/state/cfg | sed -n "s/^pt2pol=\(.*\)$/\1/p" `
pt2sr=`grep "pt2sr" /var/state/cfg |sed -n "s/^pt2sr=\(.*\)$/\1/p" `
pt2orbpos=`grep "pt2orbpos" /var/state/cfg | sed -n "s/pt2orbpos=\(.*\)$/\1/p" `
pt2weflag=`grep "pt2weflag" /var/state/cfg | sed -n "s/pt2weflag=\(.*\)$/\1/p" `

if [ -z "$ptstatus" ]; then
  ptstatus="1"
  echo "ptstatus=$ptstatus" >> /var/state/cfg
fi
if [ -z "$ptenabled" ]; then
  ptenabled="1"
  echo "ptenabled=$ptenabled" >> /var/state/cfg
fi
if [ -z "$ptpref" ]; then
  ptpref="1"
  echo "ptpref=$ptpref" >> /var/state/cfg
fi
if [ -z "$ptgenmode" ]; then
   ptgenmode=$trpgenmode
   echo "ptgenmode=$ptgenmode" >> /var/state/cfg
fi
if [ -z "$ptfreq" ]; then
   ptfreq=$trpfreq
   echo "ptfreq=$ptfreq" >> /var/state/cfg
fi
if [ -z "$ptpol" ]; then
   ptpol=$trppol
   echo "ptpol=$ptpol" >> /var/state/cfg
fi
if [ -z "$ptsr" ]; then
   ptsr=$trpsr
   echo "ptsr=$ptsr" >> /var/state/cfg
fi
if [ -z "$ptorbpos" ]; then
   ptorbpos="235"
   echo "ptorbpos=$ptorbpos" >> /var/state/cfg
fi
if [ -z "$ptweflag" ]; then
   ptweflag="1"
   echo "ptweflag=$ptweflag" >> /var/state/cfg
fi

if [ -z "$pt2genmode" ]; then
   echo "pt2genmode=2" >> /var/state/cfg
fi
if [ -z "$pt2freq" ]; then
   echo "pt2freq=0" >> /var/state/cfg
fi
if [ -z "$pt2pol" ]; then
   echo "pt2pol=1" >> /var/state/cfg
fi
if [ -z "$pt2sr" ]; then
   echo "pt2sr=0" >> /var/state/cfg
fi
if [ -z "$pt2orbpos" ]; then
   echo "pt2orbpos=235" >> /var/state/cfg
fi
if [ -z "$pt2weflag" ]; then
   echo "pt2weflag=1" >> /var/state/cfg
fi

#terminal certification data

certificationstatus=`sed -n "s/^certificationstatus=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$certificationstatus" ]; then
   echo "certificationstatus=1" >> /var/state/cfg
fi

#multicast mode
mcmode=`grep "mcmode" /var/state/cfg | sed -n "s/^mcmode=\(.*\)$/\1/p" `
if [ -z "$mcmode" ]; then
   mcmode=0
   echo "mcmode=$mcmode" >> /var/state/cfg
fi

#tx data
txnompwr=`sed -n "s/^txnompwr=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$txnompwr" ]; then
  echo "txnompwr=-30.0" >> /var/state/cfg
fi

txnombw=`sed -n "s/^txnombw=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$txnombw" ]; then
  echo "txnombw=1250000" >> /var/state/cfg
fi

txabspwr=`sed -n "s/^txpwr=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$txabspwr" ]; then
  echo "txpwr=-30.0" >> /var/state/cfg
fi

txpwrmode=`sed -n "s/^txpwrmode=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$txpwrmode" ]; then
  echo "txpwrmode=0" >> /var/state/cfg
fi

# watchdog stuff
wdenable=`sed -n "s/^wdenable=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$wdenable" ]; then
  echo "wdenable=1" >> /var/state/cfg
fi

wdcycle=`sed -n "s/^wdcycle=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$wdcycle" ]; then
  echo "wdcycle=1800" >> /var/state/cfg
fi

wdretries=`sed -n "s/^wdretries=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$wdretries" ]; then
  echo "wdretries=5" >> /var/state/cfg
fi

wdtimeoutlong=`sed -n "s/^wdtimeoutlong=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$wdtimeoutlong" ]; then
  echo "wdtimeoutlong=86400" >> /var/state/cfg
fi

wdtimeoutshort=`sed -n "s/^wdtimeoutshort=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$wdtimeoutshort" ]; then
  echo "wdtimeoutshort=300" >> /var/state/cfg
fi

wdtrafficchecks=`sed -n "s/^wdtrafficchecks=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$wdenable" ]; then
  echo "wdtrafficchecks=0" >> /var/state/cfg
fi

sed -i "/^wdreason./d" /var/state/cfg
sed -i "/^wdmonitinterval./d" /var/state/cfg

wdinterval=`sed -n "s/^wdinterval=\(.*\)$/\1/p" /var/state/cfg`
if [ -z "$wdinterval" ]; then
  echo "wdinterval=60" >> /var/state/cfg
fi

# SMS-5359: Explicitly change routercontroller_supported from 2 to 1 on an MDM3310
parse_modemtype
parse_routercontroller_supported
if [[ "${CFG_modemtype}" = "12" && "${CFG_routercontroller_supported}" = "2" ]]; then
  echo "ERROR: MDM3310 does not support routercontroller_supported=2, reverting to routercontroller_supported=1" 1>&2
  sed -i 's/^routercontroller_supported=.*$/routercontroller_supported=1/' /var/state/cfg
fi

# Introduction of 50 Mhz reference to the LNB on some modems: migrate to new setting
sed -i 's/^odubuc10mhz/odubucreferenceclock/' /var/state/cfg

#Do not enable moob without server address
parse_moob_enabled
moob_config_server_url=`sed -n "s/^moob_config_server_url=\(.*\)$/\1/p" /var/state/cfg`
if [ ${moob_enabled} -eq 1 ] && [ -z "$moob_config_server_url" ]; then
    sed -i 's/moob_enabled=1/moob_enabled=0/g' /var/state/cfg
fi


parse_verify
parse_tryotherbuild
parse_active_build
bootm_reset=$(grep bootm /var/state/cfg | grep '|| reset')
if [ "${CFG_verify}" == "n" ]; then
   #check if bootm is followed by '|| reset ', if so we may change it to verify=y if tryotherbuild is not 1
   if [ ! -z "$bootm_reset" ] && [ "${CFG_tryotherbuild}" -eq 0 ] &&  [ ! $(ubimage verify --input /dev/img${CFG_active_build}) ]; then
         sed -i 's/verify=n/verify=y/g' /var/state/cfg
   fi
else
   if [ -z "$bootm_reset" ]; then 
      sed -i 's/verify=y/verify=n/g' /var/state/cfg
   fi
fi
