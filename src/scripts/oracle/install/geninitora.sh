#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_geninitora()
{
echo "Generating create.ora...." 
echo "Generating run.ora...." 

l_runora=${ISCONFIG}/run.ora
l_prunora=${ISCONFIG}/p_run.ora
l_createora=${ISCONFIG}/create.ora
export NUMCPU=`cat /proc/cpuinfo  |grep -c "processor" `
export COMPAT=${ORACLE_VERSION}
export USERS=100
typeset l_arch=`s_f_getarch`

if [ -z "${FSOPTIONS}" ];then
       	if [ "x${AIO}" = "xtrue" ];then
       	        if [ "x${DIO}" = "xtrue" ];then	FSOPTIONS=setall;else FSOPTIONS=asynch;fi
        else
       	        if [ "x${DIO}" = "xtrue" ];then	FSOPTIONS=directio;else FSOPTIONS=none;fi
       	fi
fi
if [ -z "${SHAREDPOOLSIZE}" ];then
	SHAREDPOOLSIZE=`echo "((${SGA}*1024*1024*1024)-(31457280*2)) * 0.7" | bc -l | cut -d "." -f1`
        declare -i l_sharedpoolsize=${SHAREDPOOLSIZE}
	# Limit Shared pool to 1.5GB
	test "x${l_arch}" = "x32bit" -a "${l_sharedpoolsize}" -gt "1610612736" && SHAREDPOOLSIZE=1610612736
fi
declare -i l_sharedpoolsize=${SHAREDPOOLSIZE}
if [ -z "${DBBUF}" ];then
	DBBUF=`echo "((${SGA}*1024*1024*1024)-(31457280*2)) * 0.2 / ${DBBLOCKSIZE}" | bc -l | cut -d "." -f1`
	test "x${l_arch}" = "x32bit" -a "${l_sharedpoolsize}" -gt "1610612736" && DBBUF=`echo "((${SGA}*1024*1024*1024*0.9)-${SHAREDPOOLSIZE}-(31457280*2))/${DBBLOCKSIZE}" |bc -l | cut -d "." -f1`;
fi
if [ -z "${USEINDIRECTBUF}" ];then
	USEINDIRECTBUF=false
        if [ "x${l_arch}" = "x32bit" -a  "x${SHMFS}" = "xtrue" ];then
		test -z "${VLMWINDOWSIZE}" && VLMWINDOWSIZE=536870912
		if [ `echo "(${DBBUF}*${DBBLOCKSIZE}) > ${VLMWINDOWSIZE}" | bc -l ` -eq 1 ];then
                       	USEINDIRECTBUF=true;SGATARGET=false;
                fi
        fi
fi

Mem_Total=`free | head -2 | tail -1 | awk -F" " '{print $2 }'`
if [ $Mem_Total -gt 8388608 -a $Mem_Total -le 16777216 ];then
        _ksmg_granule_size=67108864
elif [ $Mem_Total -gt 16777216 -a $Mem_Total -le 33554432 ];then
        _ksmg_granule_size=134217728
elif [ $Mem_Total -gt 33554432 ];then
	if [ `echo "$SGA * 1024" | bc -l |  cut -d "." -f1` -lt 1300 ]
	then
        	_ksmg_granule_size=134217728
	else
	        _ksmg_granule_size=268435456
	fi
else
        _ksmg_granule_size=33554432
fi


test -z "${NUMPROCESS}" && NUMPROCESS=`echo "${USERS} * 1.6 + 150" | bc -l | cut -d "." -f1`
UNDORETENTION="${UNDORETENTION:-900}"  
test -z "${SES}" && SES=`echo "${NUMPROCESS} * 2" | bc -l| cut -d "." -f1`
LARGEPOOLSIZE="${LARGEPOOLSIZE:-31457280}"  
LOGBUF="${LOGBUF:-31457280}" 
test -z "${BACKDUMPDEST}" && BACKDUMPDEST=${DB_RUN_DUMP} 
test -z "${USERDUMPDEST}" && USERDUMPDEST=${DB_RUN_DUMP} 
test -z "${COREDUMPDEST}" && COREDUMPDEST=${DB_RUN_DUMP} 
#FIXME
ARCHIVELOC="${ARCHIVELOC:-/tmp}"  
test -z "${PARALLELMAXSRV}" && PARALLELMAXSRV=`expr 10 \* ${NUMCPU}` 
test -z "${PARALLELMINSRV}" && PARALLELMINSRV=`expr ${NUMCPU} - 1`
test -z "${RECOVPARALLELISM}" && RECOVPARALLELISM=`expr ${NUMCPU} - 1`
LOGCHKPTALERT="${LOGCHKPTALERT:-"TRUE"}" 
#test -z "${OPENCURSORS}" && OPENCURSORS=3000 
test -z "${OPENCURSORS}" && OPENCURSORS=`echo "50 + ( ${USERS} * ${NUMOFSERVERS}) " | bc -l | cut -d "." -f1`
test ${OPENCURSORS} -lt 3000 && OPENCURSORS=3000 ;
CURSORSPACETIME="${CURSORSPACETIME:-"TRUE"}"  
test -z "${DBWRITERPROC}" && DBWRITERPROC=`expr ${NUMCPU} - 1`; test "${DBWRITERPROC}" -eq "0" && DBWRITERPROC="1"
test -z "${DBINSTANCES}" && DBINSTANCES="${NUMOFSERVERS}"
TIMEDSTATS="${TIMEDSTATS:-"TRUE"}"  
ENQRES="${ENQRES:-30000}"
DMLLCKS="${DMLLCKS:-3000}"  
DMLLCKSR="${DMLLCKSR:-3000}"  
MULTIBLKCNT="${MULTIBLKCNT:-1}" 
REPDEPTRK="${REPDEPTRK:-"false"}"  
FASTSTARTMTTRTARGET="${FASTSTARTMTTRTARGET:-500}" 

echo "
control_files=$CTRLLOC/control_001
db_name=$DBNAME
cluster_database=$RAC

db_block_checking=TRUE
db_block_checksum=TRUE

parallel_max_servers=$PARALLELMAXSRV
parallel_min_servers=$PARALLELMINSRV
recovery_parallelism=$RECOVPARALLELISM


log_checkpoints_to_alert=$LOGCHKPTALERT

open_cursors=$OPENCURSORS
cursor_space_for_time=$CURSORSPACETIME

db_writer_processes=$DBWRITERPROC
cluster_database_instances=$DBINSTANCES
timed_statistics=$TIMEDSTATS

#enqueue_resources=$ENQRES
dml_locks=$DMLLCKS
db_file_multiblock_read_count=$MULTIBLKCNT

replication_dependency_tracking=$REPDEPTRK
FAST_START_MTTR_TARGET=$FASTSTARTMTTRTARGET


# Parameters calculated
undo_management=auto
#log_archive_start=true

compatible=$COMPAT
processes=$NUMPROCESS
sessions=$SES
db_block_size=$DBBLOCKSIZE
shared_pool_size=$SHAREDPOOLSIZE
large_pool_size=$LARGEPOOLSIZE
log_buffer=$LOGBUF
db_block_buffers=$DBBUF
use_indirect_data_buffers=$USEINDIRECTBUF
undo_retention=$UNDORETENTION
filesystemio_options=$FSOPTIONS
background_dump_dest=$WSRARUN
user_dump_dest=$WSRARUN
core_dump_dest=$WSRARUN
log_archive_dest=$ARCHIVELOC
log_archive_format='arch_%t_%s_%r.arc'
service_names=$SERVICENAME
	
" > ${ISCONFIG}/run.ora

echo "
control_files=$CTRLLOC/control_001
db_name="$DBNAME"
db_block_checking=TRUE
db_block_checksum=TRUE

# Parameters calculated
undo_management=auto
compatible=$COMPAT
db_block_size=$DBBLOCKSIZE
shared_pool_size=$SHAREDPOOLSIZE
large_pool_size=$LARGEPOOLSIZE
log_buffer=$LOGBUF
db_block_buffers=$DBBUF
use_indirect_data_buffers=$USEINDIRECTBUF
processes=$NUMPROCESS
sessions=$SES
dml_locks=$DMLLCKS
undo_retention=$UNDORETENTION
filesystemio_options=$FSOPTIONS
parallel_max_servers=$PARALLELMAXSRV
parallel_min_servers=$PARALLELMINSRV
recovery_parallelism=$RECOVPARALLELISM
db_writer_processes=$DBWRITERPROC
cursor_space_for_time=$CURSORSPACETIME
background_dump_dest=$WSRACREATE
user_dump_dest=$WSRACREATE
core_dump_dest=$WSRACREATE
log_archive_dest=$ARCHIVELOC

log_archive_format='arch_%t_%s_%r.arc'

" >  ${ISCONFIG}/create.ora

typeset ora_major=`echo ${ORACLE_VERSION} | awk -F"." '{print $1}'`

if [ $ora_major -eq 10 ];then
	echo "_ksmg_granule_size=$_ksmg_granule_size" >> ${l_runora}
fi

if [ "x${SGATARGET}" = "xtrue" ];then
	for i in  "${l_createora}" "${l_runora}";do 
		if [ $ora_major -eq 10 -o "x${MTARGET}" = "xfalse" ];then
                	echo  "sga_target=`echo ${SGA}*1024 | bc -l | cut -d . -f1`M"       >> "${i}"
		else
			echo  "memory_target=`echo ${SGA}*1024 | bc -l | cut -d . -f1`M"       >> "${i}"
		fi
                #Removing sga entries
       	        find_replace_strings  "shared_pool_size"    "#shared_pool_size"   "${i}"
               	find_replace_strings  "large_pool_size"     "#large_pool_size"    "${i}"
                find_replace_strings  "log_buffer"          "#log_buffer"         "${i}"
       	        find_replace_strings  "db_block_buffers"    "#db_block_buffers"   "${i}"
	done
       fi

rundump="$DB_RUN_DUMP";test -z "$DB_RUN_DUMP" && rundump="$WSRARUN" ;
createdump="$DB_CREATE_DUMP";test -z "$DB_CREATE_DUMP" && createdump="$WSRACREATE" ;


if [ ${ora_major} -ge 11 ]
then
	#11G support
	echo "diagnostic_dest=${rundump}"     >> ${l_runora}
	echo "diagnostic_dest=${createdump}"        >> ${l_createora}
	find_replace_strings "background_dump_dest" "#background_dump_dest" ${l_createora}
	find_replace_strings "user_dump_dest" "#user_dump_dest"  ${l_createora}
														     
	find_replace_strings "background_dump_dest" "#background_dump_dest" ${l_runora}
	find_replace_strings "user_dump_dest" "#user_dump_dest"  ${l_runora}
        find_replace_strings "cursor_space_for_time" "#cursor_space_for_time" ${l_createora}
        find_replace_strings "cursor_space_for_time" "#cursor_space_for_time" ${l_runora}


fi
# prun.ora
if [ "x${RAC}" = "xtrue" ];then
	declare -i l_count=1
        for i in ${SERVERS};do
		echo "ifile=${WSCONFIG}/run.ora" 		> ${ISCONFIG}/$i/p_run.ora
        	echo "instance_number=$l_count "                >> ${ISCONFIG}/$i/p_run.ora
                echo "thread=$l_count "                         >> ${ISCONFIG}/$i/p_run.ora
		echo "instance_name=$INSTANCENAME${l_count} " 	>> ${ISCONFIG}/$i/p_run.ora
		echo "undo_tablespace=roll_${l_count} " 	>> ${ISCONFIG}/$i/p_run.ora
		l_vip=`echo $SERVERSVIP | cut -d" " -f$l_count`
		echo "local_listener=\"(address=(protocol=tcp)(host="$l_vip")(port=$PORTNUM))\"" >> ${ISCONFIG}/$i/p_run.ora

		s_f_addremotelistener $i;
		
                l_count=$l_count+1
	done
else
	echo "undo_tablespace=roll_1 "  >> ${l_runora}
	echo "instance_name=$INSTANCENAME${l_count} " >> ${l_runora}

fi

return 0 
}


s_f_addremotelistener ()
{

	declare -i l_rcount=1
	i=$1
	for j in ${SERVERS};do
		l_vip=`echo $SERVERSVIP | cut -d" " -f$l_rcount`
		if [ $l_rcount -eq 1 ]	
		then
			echo "remote_listener=\"(DESCRIPTION=(address=(protocol=tcp)(host="$l_vip")(port=$PORTNUM))" >> ${ISCONFIG}/$i/p_run.ora
		else
			if [ $l_rcount -eq ${NUMOFSERVERS} ];then 
				echo " 		       (address=(protocol=tcp)(host="$l_vip")(port=$PORTNUM)))\"">> ${ISCONFIG}/$i/p_run.ora
			else
				echo " 		       (address=(protocol=tcp)(host="$l_vip")(port=$PORTNUM))">> ${ISCONFIG}/$i/p_run.ora
			fi
		fi
		l_rcount=$l_rcount+1
	done


}

s_f_getarch ()
{
   typeset l_uname=`uname -a`
   typeset l_string=`echo ${l_uname} | sed -e 's:i586:i386:g' | sed -e 's:i686:i386:g'`
   typeset l_res=""

   l_res=`echo ${l_string} | grep " ia64"`
   if [ "x${l_res}" != "x" ]; then
      echo "64bit"
      return 0
   fi

   l_res=`echo ${l_string} | grep " x86_64"`
   if [ "x${l_res}" != "x" ]; then
      echo "64bit"
      return 0
   fi;

   l_res=`echo ${l_string} | grep "i386"`
   if [ "x${l_res}" != "x" ]; then
      echo "32bit"
      return 0
   fi
   return 1
}


