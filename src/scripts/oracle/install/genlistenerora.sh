#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

# Script to generate listener.ora

f_genlistenerora()
{
echo "Generating listener.ora.... " 
echo "
$LISTENERNAME =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS_LIST =
        (ADDRESS = (PROTOCOL = IPC)(KEY = $IPCKEY))
        (ADDRESS = (PROTOCOL = TCP)(HOST = VIPNAME)(PORT = $PORTNUM)(QUEUESIZE=20))
      )
    )
  )

SID_LIST_$LISTENERNAME =
  (SID_LIST =
    (SID_DESC =
      (SID_NAME = PLSExtProc)
      (ORACLE_HOME = $SERVERORAHOME)
      (PROGRAM = extproc)
    )
    (SID_DESC =
      (ORACLE_HOME = $SERVERORAHOME)
      (SID_NAME = INSTANCENAME)
    )
  )
INBOUND_CONNECT_TIMEOUT_$LISTENERNAME=0
STARTUP_WAIT_TIME_$LISTENERNAME=0
CONNECT_TIMEOUT_$LISTENERNAME=10
TRACE_LEVEL_$LISTENERNAME=OFF
TRACE_DIRECTORY_$LISTENERNAME=$WSRLDB
TRACE_FILE_$LISTENERNAME=$LISTENERNAME.trc
LOG_DIRECTORY_$LISTENERNAME=$WSRLDB
LOG_FILE_$LISTENERNAME=$LISTENERNAME.log
" > ${ISCONFIG}/listener.ora

echo "sqlnet.inbound_connect_timeout = 0" >  ${ISCONFIG}/sqlnet.ora
echo "sqlnet.inbound_connect_timeout = 0" > ${ICCONFIG}/sqlnet.ora
#echo "log_directory_server = ${WSRLDB}" >> ${ISCONFIG}/sqlnet.ora
#echo "log_directory_client = ${WCCONFIG}" >> ${ICCONFIG}/sqlnet.ora

l_listenerora=${ISCONFIG}/listener.ora

if [ "x${RAC}" = "xtrue" ];then
       	declare -i l_count=1
        for i in $SERVERS;do
		# Copy listener.ora to each nodes config dir
               	cp ${l_listenerora} ${ISCONFIG}/$i
		find_replace_strings	"INSTANCENAME"	"$INSTANCENAME${l_count}"	${ISCONFIG}/$i/listener.ora
		l_vip=`echo $SERVERSVIP | cut -d" " -f$l_count`
		find_replace_strings       "VIPNAME"	"$l_vip"	${ISCONFIG}/$i/listener.ora
                l_count=$l_count+1
       done
fi
find_replace_strings       "INSTANCENAME"          "$INSTANCENAME"      "${l_listenerora}"
find_replace_strings       "VIPNAME"               "$SERVERS"      "${l_listenerora}"
}

