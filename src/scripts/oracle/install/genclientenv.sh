#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_genclientenv()
{
echo "Generating clientenv...." 
if [ "x${DRIVER}" = "xodbc" ];then
	echo " export LD_LIBRARY_PATH=$CLIENTORAHOME " > ${ICCONFIG}/client.env
else
	echo "export ORACLE_HOME=${CLIENTORAHOME}" > ${ICCONFIG}/client.env
	echo "export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$ORACLE_HOME/rdbms/lib" >> ${ICCONFIG}/client.env
fi
echo "
export  TNS_ADMIN="${WCCONFIG}"
export TWO_TASK="${SERVICENAME}"
export PATH=.:$CLIENTORAHOME/bin:/usr/sbin/:$PATH 
#export MALLOC_CHECK_=0
" >> ${ICCONFIG}/client.env
}

