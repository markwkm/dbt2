#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_genserverenv()
{
echo "Generating serverenv...." 
echo "
export ORACLE_HOME=${SERVERORAHOME}; 
export PATH=.:${SERVERORAHOME}/bin:/usr/sbin/:$PATH ;
export 	LD_LIBRARY_PATH=\$ORACLE_HOME/lib:\$ORACLE_HOME/rdbms/lib
export SHLIB_PATH=\$ORACLE_HOME/lib:\$ORACLE_HOME/rdbms/libexport
export SEQLPLUS=sqlplus
export oracle_dba=system
export oracle_dba_password=manager
connect_initate_string="/nolog"
export connect_initate_string
export SYS_CONNECTION_STRING=\"connect \/ as sysdba\"
" > "${ISCONFIG}/server.env"

declare -i l_count=1
for i in ${SERVERS};do 
        cp ${ISCONFIG}/server.env ${ISCONFIG}/$i/
        echo "export ORACLE_SID=${SID}$l_count;" >> ${ISCONFIG}/$i/server.env
    	l_count=$l_count+1
done
echo "export ORACLE_SID=${SID};" >> "${ISCONFIG}/server.env"
chmod +x ${ISCONFIG}/server.env
}
