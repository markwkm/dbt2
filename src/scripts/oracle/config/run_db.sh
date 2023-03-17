#!/bin/bash 
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

if [ $# -lt 2 ];then
	echo "
	Usage :
	run_db.sh testname users duration
	"
	exit -1
fi

l_users=$1
l_users=`echo "$l_users / ( $WAREHOUSE ) " | bc -l | cut -d "." -f1`
l_duration=$2
l_nodb=$3
l_nolsnr=$4
l_nosp=$5

test -f ${WORKHOME}/run_fail && rm -f ${WORKHOME}/run_fail
test -f ${WORKHOME}/run_done && rm -f ${WORKHOME}/run_done

f_cleanup(){
for i in $SERVERS;do
	if [ "x${l_nodb}" = "xfalse" ];then
		echo  "Stopping Oracle Instance On Server Node : $i "
                ssh -l $USER $i "$WSWARE/dbstop.sh "
		echo "Stopping Oracle Instance On Server Node : $i"
	fi
        if [ "x${l_nolsnr}" = "xfalse" ];then
		echo  "Stopping Oracle Listener On Server Node : $i "
		ssh -l $USER $i "$WSWARE/listenerstop.sh  "
		echo  "Stopping Oracle Listener On Server Node : $i"	
	fi
done
if [ "x${l_nodb}" = "xfalse" -a "x$STORAGETYPE" = "xasm" ];then
	for i in $SERVERS;do
		echo "Stopping asm instance on server node $i"
                ssh -l $USER $i "$WSWARE/asmstop.sh  "
		echo "Stopping asm Instance On Server Node : $i"
        done
fi
}
f_runres()
{
if [ $1 -ne 0 ];then
	mkdir -p ${WSRLOG}/$TESTNAME	
	echo "$2 FAILED " | tee ${WSRLOG}/$TESTNAME/run_stop; f_cleanup; exit 1;
else
      	echo "$2 PASSED "
fi
}

test -z "$l_users" && l_users=1 

l_runora=${WSCONFIG}/run.ora
test "x$RAC" = "xtrue" && l_runora=${WSCONFIG}/p_run.ora

if [ "x${l_nodb}" = "xfalse" -a "x$STORAGETYPE" = "xasm" ];then
	for i in $SERVERS;do	
		echo "Starting asm instance on server node $i"
		ssh -l $USER $i "${WSWARE}/asmstart.sh  "
		f_runres $? "Starting asm Instance On Server Node : $i"
	done
fi

for i in $SERVERS;do
	if [ "x${l_nodb}" = "xfalse" ];then
        	echo  "Starting Oracle Instance On Server Node : $i "
		ssh -l $USER $i "${WSWARE}/dbstart.sh  ${l_runora} "
		f_runres $? "Starting Oracle Instance On Server Node : $i"
	fi

	if [ "x${l_nolsnr}" = "xfalse" ];then
        	echo  "Starting Oracle Listener On Server Node : $i "
      	        ssh -l $USER $i "${WSWARE}/listenerstart.sh  "
		f_runres $? "Starting Oracle Listener On Server Node : $i"
	fi
done

case ${TESTCASE} in
	"io" )
		l_options=""		
		;;
	"io_cpu" ) 
		l_options="-q 0.02 -r 0.02 -e 0.02 -t 0.82 "
		;;

	"cpu_erp" )
		l_options="-q 0.005 -r 0.005 -e 0.005 -t 0.96 "
		;;
			
		*)
			echo "No options specified"
		;;
esac

if [ "x${NO_SLEEP}" = "xtrue" ]
then
	l_sleep_options="-ktd 0 -ktn 0 -kto 0 -ktp 0 -kts 0 -ttd 0 -ttn 0 -tto 0 -ttp 0 -tts 0"
else
	l_sleep_options="-ktd 1 -ktn 1 -kto 1 -ktp 1 -kts 1 -ttd 1000 -ttn 1000 -tto 1000 -ttp 1000 -tts 1000"
fi

l_options="$l_options $l_sleep_options"

l_dbname="$TNSALIAS"
test "x${DRIVER}" = "xodbc" && l_dbname="TestDBDSN" 
l_proc_list=""


if [ "x${l_nosp}" = "xfalse" ];then
	for i in $SERVERS;do
       		echo  "Collecting StatsPack before the test on Node : $i "
		ssh -l $USER $i ". ${SERVERENV};${WSWARE}/sp_before.sh;"
		f_runres $? "Collecting StatsPack before the test on Node : $i"
		# Pass start snap number to sp_after script.
		export l_before=`ssh -l $USER $i grep SNAP_BEFORE -A4 ${WSRLOG}/sp_before.log | grep "^[ \t]*[0-9]*[ \t]*$" |awk '{print gensub(" ","","g")}'`
		ssh -l $USER $i "cp ${WSWARE}/sp_after-template.sh ${WSWARE}/sp_after.sh; perl -p -i -e "s%START_SNAP%$l_before%g" ${WSWARE}/sp_after.sh; chmod +x ${WSWARE}/sp_after.sh;"
	done
fi

for i in $CLIENTS;do
       	#startclient
	echo " Starting Driver on $i "
	ssh -l $USER $i ". ${CLIENTENV} ; $WCSCRIPTS/driver -dbname $l_dbname -l $l_duration -wmin 1 -wmax $WAREHOUSE -w $WAREHOUSE -tpw $l_users -outdir ${WCLOG} $l_options " & 
	l_proc_list="$!"\ "$l_proc_list"
	echo "Logs are available at ${WCLOG} on $i "
done

declare -i l_count2=0
declare -i l_count1=0
while [ $l_count2 -lt $NUMOFCLIENTS ];do
	l_count2=0
	sleep 10
	l_count1=$l_count1+10
	
       	#wait for clients to exit 
	for i in $l_proc_list;do
		test ! -d /proc/"${i}" && l_count2=$l_count2+1 
	done
done

if [ "x${l_nosp}" = "xfalse" ];then
	for i in $SERVERS;do
		echo "Collecting StatsPack after the test on Node : $i"
		ssh -l $USER $i ". ${SERVERENV};${WSWARE}/sp_after.sh &> /dev/null"
		ssh -l $USER $i ". ${SERVERENV};mv *.lst $WSRANALYZE;test -f *.out && mv *.out $WSRANALYZE; rm -f sp_*.log"
		echo "Statspack report of $i is available at"
		echo "$WSRANALYZE/sp_dbt2.lst"
		echo 
	done
fi

echo "Driver stopped on $CLIENTS after $l_count1 seconds "
f_cleanup
