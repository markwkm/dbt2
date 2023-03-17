#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Satish Madrage & Oracle Corporation. All rights reserved.

##############################################################################
#set -x
f_stopstats()
{
	sleep_pid=$(ps -eafl | grep "sleep 300" | grep -v grep | awk '{print $4}' )
        sleep_ppid=$(ps -eafl | grep "sleep 300" | grep -v grep | awk '{print $5}' )
        killall -9 iostat
        killall -9 mpstat
        killall -9 vmstat
        killall -9 sar
        kill -9 ${sleep_pid}
        kill -9 ${sleep_ppid}
	
}

print()
{
	echo "" >> $LOGFILE
	echo "---------------------------------------" >> $LOGFILE
	echo "- Now dumping $@ - $(date) - " >> $LOGFILE
	echo "---------------------------------------" >> $LOGFILE
}
dumpinfo()
{
	LOGFILE=$1
	shift
	print $LOGFILE $@
	eval $@ >> $LOGFILE 2>&1
}

f_stat()
{
if [ -z $1 ]
then
        echo " Usage $0 <logpath> [-sleep <minutes>]"
        exit 1
fi

while [ $1 ]
do
        if  [ "x$1" = "x-sleep" ]
        then
                SLEEP_INTERVAL=$2
                if [ -z $SLEEP_INTERVAL ]
                then
                        echo " no sleep interval specified"
                        exit 1
                        fi
                echo "sleep interval = $SLEEP_INTERVAL"
                shift 2
        else
                logpath=$1
                shift
        fi
done

if [ -z $SLEEP_INTERVAL ]
then
        SLEEP_INTERVAL=1;
        echo " Defaulting to $SLEEP_INTERVAL minute sleep"
fi

if [ "x$logpath" != "x" ]
then
        if [ ! -d $logpath ]
        then
                mkdir -p $logpath
                if [ $? != 0 ]
                then
                        echo "$logpath: cannot make directory"
                        exit 1
                fi
        fi
fi

dumpinfo $logpath/sysinfo uname -a
dumpinfo $logpath/sysinfo /sbin/lsmod
dumpinfo $logpath/sysinfo mount
dumpinfo $logpath/sysinfo cat /proc/cmdline
dumpinfo $logpath/sysinfo cat /proc/cpuinfo
dumpinfo $logpath/sysinfo cat /proc/meminfo
dumpinfo $logpath/sysinfo /proc/sys/kernel/tainted
dumpinfo $logpath/sysinfo dmesg
dumpinfo $logpath/sysinfo lspci -vv
dumpinfo $logpath/sysinfo rpm -qa
dumpinfo $logpath/sysinfo ifconfig -a
dumpinfo $logpath/sysinfo cat /var/log/messages

sleeptime=$((60*$SLEEP_INTERVAL))

dumpinfo $logpath/iostat iostat -t -x ${sleeptime} &
dumpinfo $logpath/vmstat vmstat ${sleeptime}  &
dumpinfo $logpath/mpstat mpstat -P ALL ${sleeptime} &
dumpinfo $logpath/sar sar -n DEV ${sleeptime} 0 &

while [ true ]
do
	dumpinfo $logpath/uptime uptime
        dumpinfo $logpath/meminfo-slabinfo cat /proc/meminfo
        dumpinfo $logpath/meminfo-slabinfo cat /proc/slabinfo
        dumpinfo $logpath/aio-nr cat /proc/sys/fs/aio-max-nr
        dumpinfo $logpath/aio-nr cat /proc/sys/fs/aio-nr
        dumpinfo $logpath/ps-auxw ps auxw
        dumpinfo $logpath/profile /usr/sbin/readprofile -m /boot/System.map-`uname -r`
	dumpinfo $logpath/netstat netstat -s
	sleep $sleeptime
done



}


f_startstats()
{
        (f_stat ${WSRLOG}/osstats -sleep 5  &> /dev/null) &
        if [ $? != 0 ];then
	        echo  " Error: Errors starting stats process!"
        fi

}


if [ $# -eq 0 ]
then
        echo " Usage $0 start/stop"
        exit 1
fi
l_command=$1

if [ $l_command = "start" ]
then
	f_startstats
else
	f_stopstats	 	
fi
