#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_genlistenerctl()
{
echo "Generating listenerstart.sh...."
echo "

if [ \"x\$1\" == \"x\" ]; then
	LISTENERNAME=\"LISTENER\"
else
	LISTENERNAME=\$1
fi

. ${SERVERENV}
export TNS_ADMIN=${WSCONFIG} 
echo ORACLE_SID : \$ORACLE_SID
echo TNS_ADMIN : \$TNS_ADMIN

lsnrctl stop \$LISTENERNAME
lsnrctl start \$LISTENERNAME

echo "Please wait for the service comes up..."
sleep 70
lsnrctl status \$LISTENERNAME
lsnrctl serv \$LISTENERNAME
"  > ${ISWARE}/listenerstart.sh

echo "Generating listenerstop.sh...."
echo "


if [ \"x\$1\" == \"x\" ]; then
        LISTENERNAME=\"LISTENER\"
else
        LISTENERNAME=\$1
fi

. ${SERVERENV}
export TNS_ADMIN="${WSCONFIG}" 
echo $ORACLE_SID
echo $TNS_ADMIN
echo $TWO_TASK

lsnrctl stop \$LISTENERNAME

"  > ${ISWARE}/listenerstop.sh

}
