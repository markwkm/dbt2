#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

export TRACEFILE=${WSRLDB}/tracefile
export STOPFILE=${WSRLDB}/stopfile

test -f $TRACEFILE && rm -f $TRACEFILE 
test -f $STOPFILE && rm -f $TRACEFILE
test -f ${WORKHOME}/dbcre_done && rm -f ${WORKHOME}/dbcre_done 

f_end()
{
if [ -f "$STOPFILE" ];then
	rm -f $STOPFILE
	echo "Db creation failed.. refer $TRACEFILE"
	exit 1	
else
	touch ${WORKHOME}/dbcre_done
	echo "DB/Tablespaces/Tables/Indexes/Views creation"
	echo "Datagen, stored Procs, Loading database completed Successfully" 
	exit 0
fi  

}

f_buildres()
{
if [ $1 -ne 0 ];then
	echo "$2 failed." `date` "\n" >> $TRACEFILE
	echo "Look at ${WSRLDB}/$2.log for more details." `date` "\n" >> $TRACEFILE
	echo "Stopped" >> $STOPFILE
       	echo "$2 failed ..."
        f_end
else
       	echo "$2  done." `date` "\n" >> $TRACEFILE
	echo "$2  done ..."
fi
}
f_buildmsg()
{
	echo "$1.."
        echo "$1.." `date` "\n" >> $TRACEFILE
}

cd ${WSWARE}

if [ "x$STORAGETYPE" = "xasm" ];then
	f_buildmsg "Dropping asm diskgroup"
	${WSWARE}/dropasm.sh 

	f_buildmsg "Creating asm diskgroup"
	${WSWARE}/createasm.sh
	f_buildres $? "createasm"

	f_buildmsg "Starting asm instance"
	${WSWARE}/asmstart.sh 
	f_buildres $? "asmstart"
fi

f_buildmsg "Creating the Database"
${WSWARE}/createdb.sh
f_buildres $?  "createdb"

f_buildmsg "Create User $DBUSER"
${WSWARE}/createuser.sh     	
f_buildres $? "createuser"

f_buildmsg "Create Tablespaces"
${WSWARE}/createts.sh
f_buildres $? "createts"

f_buildmsg "Create Temp Tablespace"
${WSWARE}/addts_temp.sh
f_buildres $? "addts_temp"

f_buildmsg "Assign Temporary Tablespace to $DBUSER"
${WSWARE}/usertemp.sh
f_buildres $? "usertemp"

f_buildmsg "Create Data Dictionary views"
${WSWARE}/createddviews.sh
f_buildres $? "createddviews"

for i in $ALLTABLES;do
	f_buildmsg "Create $i "
	$SEQLPLUS "$DBUSER/$DBPASSWD"  @create$i
	f_buildres $? "create$i"
done
for i in $STRDPROC 
do
	f_buildmsg "Load $i Stored Procedures "
	$SEQLPLUS "$DBUSER/$DBPASSWD"  @oracle/$i
	f_buildres $? "$i"
done
f_buildmsg "Loading database"
${WSWARE}/load_db.sh

if [ $? -ne 0 ];then
	echo "Load database failed." `date` "\n" >> $TRACEFILE
	echo "Look at ${WSRLOG}/datagen-loc for more details." `date` "\n" >> $TRACEFILE
	echo "Stopped" >> $STOPFILE
	echo "Load database failed ..."
	f_end
else
	echo "Load database done." `date` "\n" >> $TRACEFILE
	echo "Load database done ..."
	rm -f ${WSRLOG}/datagen-loc/*.data 	
fi
	
for i in $ALLINDEXES 
do
	f_buildmsg "Create $i index"
        $SEQLPLUS "$DBUSER/$DBPASSWD"  @create$i
	f_buildres $? "create$i"
done
f_buildmsg "Analyze Tables/Clusters/Indexes"	
$SEQLPLUS "$DBUSER/$DBPASSWD" @analyze 
f_buildres $? "analyze"

f_buildmsg "Create StatsPack"	
${WSWARE}/create_sp.sh
f_buildres $? "create_sp"

if [ "x${ARCHIVE}" = "xtrue" ];then
 
	f_buildmsg "Enable Database archive log"
	${WSWARE}/enable_archivelog.sh
	f_buildres $? "enable_archivelog"
fi

if [ "x$STORAGETYPE" = "xasm" ];then
	f_buildmsg "Stopping asm instance"        
	${WSWARE}/asmstop.sh 
fi

echo "
DB_NAME 	: $DBNAME
Database User	: $DBUSER
Password	: $DBPASSWD
" | tee  ${WSRLDB}/userinfo

f_end
