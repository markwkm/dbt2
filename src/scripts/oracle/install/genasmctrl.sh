#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

generate_asm_stopinstance()
{
echo " Generating asmstop.sh...."	
ASMSTOP="${ISWARE}/asmstop.sh"
cat <<EOF > ${ASMSTOP}
. ${WSCONFIG}/asm.env
\$SEQLPLUS \$connect_initate_string << !
\$SYS_CONNECTION_STRING
spool ${WSRLDB}/asmstop.log ;
set echo on ;
shutdown ;
exit sql.sqlcode;
EOF
}

generate_asm_startinstance()
{
echo " Generating startasm.sh...."	
ASMSTART="${ISWARE}/asmstart.sh"
cat <<EOF > ${ASMSTART}
. ${WSCONFIG}/asm.env
\$SEQLPLUS \$connect_initate_string << !
\$SYS_CONNECTION_STRING
spool ${WSRLDB}/asmstart.log ;
set echo on ;
shutdown abort ;
startup pfile=${WSCONFIG}/asm.ora nomount ;
select path from v\\\$asm_disk ;
alter diskgroup ${ASMGROUPNAME} mount ;
exit sql.sqlcode
EOF
}

generate_asm_grpcreate()
{ 
echo " Generating createasm.sh...."	
echo " 
. ${WSCONFIG}/asm.env
\$SEQLPLUS \$connect_initate_string << !
\$SYS_CONNECTION_STRING
spool ${WSRLDB}/createasmgrp.log ;
set echo on ;
select path from v\\\$asm_disk ;
" > ${ISWARE}/createasm.sh

case $REDUNDANCY in
	"external" )
			echo "
			create diskgroup ${ASMGROUPNAME} external redundancy disk ${ASMDISKLIST1} ;
			" >> ${ISWARE}/createasm.sh 
			;;
	"normal" ) 
			echo "
			create diskgroup ${ASMGROUPNAME} normal redundancy
			FAILGROUP fail1 DISK ${ASMDISKLIST1}  
			FAILGROUP fail2 DISK ${ASMDISKLIST2} ;
			" >> ${ISWARE}/createasm.sh 
			;;
	"high" ) 
			echo "
                        create diskgroup ${ASMGROUPNAME} high redundancy
                        FAILGROUP fail1 DISK ${ASMDISKLIST1} 
                        FAILGROUP fail2 DISK ${ASMDISKLIST2} 
                        FAILGROUP fail3 DISK ${ASMDISKLIST3};
                        " >> ${ISWARE}/createasm.sh 
                        ;;

esac
echo "exit sql.sqlcode ; " >> ${ISWARE}/createasm.sh 
}

generate_asm_grpdrop()
{ 
echo " Generating dropasm.sh...."	
cat <<EOF > ${ISWARE}/dropasm.sh
. ${WSCONFIG}/asm.env
\$SEQLPLUS \$connect_initate_string << !
\$SYS_CONNECTION_STRING
spool ${WSRLDB}/dropasmgrp.log ;
set echo on ;
startup pfile=${WSCONFIG}/asm.ora nomount ;
alter diskgroup ${ASMGROUPNAME} mount ;
drop diskgroup ${ASMGROUPNAME} including contents ;
exit sql.sqlcode ;
EOF
}

generate_asm_initora()
{
echo " Generating asm init.ora files...."	
# Find the Oracle version 
if test -f ${ORACLE_HOME}/bin/sqlplus;then
	export ORACLE_HOME=${ORACLE_HOME} 
       	l_oracle_release=`${ORACLE_HOME}/bin/sqlplus -? | awk '/Release/ {print $3}'`
fi
typeset ora_major=`echo ${l_oracle_release} | awk -F"." '{print $1}'`
if [ ${ora_major} -lt 10 ];then
	echo "ASM not supported in this release of Oracle - ${l_oracle_release}" | tee  ${WORKHOME}/setup_fail 
	exit -1 
fi
# Generate the initora file for the ASM instance
declare -i count=1 
for i in $SERVERS;do
	ASMINITORAFILE="${ISCONFIG}/asm.ora"
	test $RAC = "true" && ASMINITORAFILE="${ISCONFIG}/$i/asm.ora"
	echo "asm_power_limit=11" 		 >  ${ASMINITORAFILE}
	echo "instance_type=asm"		 >>  ${ASMINITORAFILE}
	echo "remote_login_passwordfile=NONE"	 >>  ${ASMINITORAFILE}
	echo "cluster_database=true"		 >>  ${ASMINITORAFILE}
	echo "instance_number=${count}"		 >>  ${ASMINITORAFILE}
	echo "asm_diskstring='$DISKSTRING'"      >>  ${ASMINITORAFILE}
	if [ ${ora_major} -ge 11 ];then
		echo "diagnostic_dest=${l_wsrarun}"     >>  ${ASMINITORAFILE}
	else
		echo "compatible=${l_oracle_release}" 	 >>   ${ASMINITORAFILE}
		echo "large_pool_size=12M"		 >>  ${ASMINITORAFILE}
	        echo "background_dump_dest=${l_wsrarun}" >>  ${ASMINITORAFILE}
        	echo "user_dump_dest=${l_wsrarun}"     >>  ${ASMINITORAFILE}
	fi

        echo "core_dump_dest=${l_wsrarun}"     >>  ${ASMINITORAFILE}
	count=${count}+1 
done
}

generate_asm_envfile ()
{
echo " Generating asm env file files...."	
declare -i count=1
if test -f ${ORACLE_HOME}/bin/sqlplus;then
        export ORACLE_HOME=${ORACLE_HOME}
        l_oracle_release=`${ORACLE_HOME}/bin/sqlplus -? | awk '/Release/ {print $3}'`
fi
typeset ora_major=`echo ${l_oracle_release} | awk -F"." '{print $1}'`
if [ ${ora_major} -ge 11 ];then
	SYSASM="sysasm"
else
	SYSASM="sysdba"
fi

for i in $SERVERS;do
	ASMENVFILE="${ISCONFIG}/asm.env"
	test $RAC = "true" && ASMENVFILE="${ISCONFIG}/$i/asm.env"
	echo "export ORACLE_HOME=${ORACLE_HOME} " 			>  ${ASMENVFILE}
	echo "PATH=\$ORACLE_HOME/bin:\$PATH "     			>> ${ASMENVFILE}
	echo "LD_LIBRARY_PATH=\$ORACLE_HOME/lib:\$LD_LIBRARY_PATH "     >> ${ASMENVFILE}
	echo "export SEQLPLUS=sqlplus"					>> ${ASMENVFILE}
	echo "export connect_initate_string=\"/nolog\" "		>> ${ASMENVFILE}	
	echo "export SYS_CONNECTION_STRING=\"connect \\\\/ as $SYSASM\"" >> ${ASMENVFILE}
	echo "export ORACLE_SID=Asm${count}"				>> ${ASMENVFILE}			
	count=${count}+1 
done	
}

main()
{
test $STORAGETYPE != "asm" && return 0
echo "Generating asm realted files...."	

l_wsrarun="$DB_RUN_DUMP";test -z "$DB_RUN_DUMP" && l_wsrarun="$WSRARUN" ;export l_wsrarun ;
typeset alldisks="$ASMDISKLIST1"\ "$ASMDISKLIST2"\ "$ASMDISKLIST3"
declare -i l_count=0
l_tempfile=${ITMPDIR}/tempfile
echo ${alldisks} | awk '{print gensub(" ","\n","g")}' 1> ${l_tempfile} 
l_count=`echo ${alldisks} | awk '{ print NF }'`	
l_diskstr=`cat $l_tempfile | tail -1`
l_len=${#l_diskstr}

while [ $l_len -gt 0 ];do
       	str=${l_diskstr:0:l_len-1}
       	l_len=${#str}
	test `grep -c $str $l_tempfile` -ge $l_count && break
done
export 	DISKSTRING="$str""*"
typeset asmdisklist=""
declare -i count=1
for i in $ASMDISKLIST1;do
	if [ $count -eq 1 ];then
		asmdisklist="'${i}'"
	else
		asmdisklist="${asmdisklist},'${i}'"   
	fi
	count=$count+1
done
ASMDISKLIST1="$asmdisklist"
typeset asmdisklist=""
declare -i count=1
for i in $ASMDISKLIST2;do
	if [ $count -eq 1 ];then
		asmdisklist="'${i}'"
	else
		asmdisklist="${asmdisklist},'${i}'"   
	fi
	count=$count+1
done
ASMDISKLIST2="$asmdisklist"
typeset asmdisklist=""
declare -i count=1
for i in $ASMDISKLIST3;do
	if [ $count -eq 1 ];then
		asmdisklist="'${i}'"
	else
		asmdisklist="${asmdisklist},'${i}'"   
	fi
	count=$count+1
done
ASMDISKLIST3="${asmdisklist}"

generate_asm_envfile 
generate_asm_initora 
generate_asm_grpcreate 
generate_asm_grpdrop 
generate_asm_startinstance 
generate_asm_stopinstance 
}

f_asmctrl()
{

main $* 
}
