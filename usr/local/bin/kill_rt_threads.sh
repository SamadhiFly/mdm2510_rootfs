#!/bin/sh

# Force-kill all real-time threads, except for watchdog and canary threads.

for file in /proc/*/task/*/stat; do
  tid=$(awk '{print $1}' $file);
  thread=$(awk '{print $2}' $file);
  pol=$(awk '{print $41}' $file);
  prio=$(awk '{print $40}' $file);
  if [ "$pol" -ne "0" -a "$prio" -ne "99" ] && ! { echo ${thread} | grep -q 'ntc_wd_'; } then
    echo "Killing thread: $thread (tid: $tid, pol: $pol, prio: $prio)";
    kill -9 "$tid"
  fi
done

