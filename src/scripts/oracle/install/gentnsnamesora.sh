#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_gentnsnamesora()
{

# Gnerating tnsnames.ora for all client nodes
echo "Generating tnsnames.ora...."
echo "

"${TNSALIAS}"=
 (DESCRIPTION=
"> ${ICCONFIG}/tnsnames.ora
if [ "x${RAC}" = "xtrue" ];then
        for i in ${SERVERSVIP}; do
                echo "  (ADDRESS=(PROTOCOL=tcp)(HOST="${i}")(PORT=${PORTNUM}))" >> ${ICCONFIG}/tnsnames.ora
        done
else
        echo "  (ADDRESS=(PROTOCOL=tcp)(HOST="${SERVERS}")(PORT=${PORTNUM}))" >> ${ICCONFIG}/tnsnames.ora
fi
echo "
  (LOAD_BALANCE = yes)
  (FAILOVER = on)
  (CONNECT_DATA=
        (SERVICE_NAME="${SERVICENAME}")
        (failover_mode=
           (type=select)
           (method=basic)
           (retries=30)
           (delay=5))))
" >> ${ICCONFIG}/tnsnames.ora
}

