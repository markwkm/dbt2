#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_genodbcconfig(){

test "x${DRIVER}" != "xodbc" && return 0

echo "Generating .odbc.ini...."
echo "
[TestDBDSN]
ServerName = $TNSALIAS
Application Attributes = T
Attributes = W
BatchAutocommitMode = IfAllSuccessful
CloseCursor = T
DisableDPM = F
DisableMTS = T
Driver = ODBC_in_cl102b
DSN = TestDBDSN
EXECSchemaOpt =
EXECSyntax = T
Failover = T
FailoverDelay = 10
FailoverRetryCount = 10
FetchBufferSize = 64000
ForceWCHAR = F
Lobs = T
Longs = T
MetadataIdDefault = F
QueryTimeout = T
ResultSets = T
SQLGetData extensions = F
Translation DLL =
Translation Option = 0
UserID = $USER
" > ${ICCONFIG}/.odbc.ini

#echo "
#[ODBC]
#Trace           = No
#TraceFile               = /tmp/sql.log
#ForceTrace              = No
#Pooling         = No
#
#[ODBC_in_cl102b]
#Description             = Oracle 10gR2 ODBC driver.
#Driver          = $CLIENTORAHOME
#Setup           =
#FileUsage               =
#CPTimeout               =
#CPReuse         =
#"
#> ${ICCONFIG}/odbcinst.ini
}
