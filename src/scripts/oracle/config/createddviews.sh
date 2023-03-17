#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

. ${SERVERENV}

sqlplus $connect_initate_string << !

$SYS_CONNECTION_STRING

spool ${WSRLDB}/createddviews.log



@$ORACLE_HOME/rdbms/admin/standard
@$ORACLE_HOME/rdbms/admin/dbmsstdx

rem dbms_registry
rem @$ORACLE_HOME/rdbms/admin/catr
@$ORACLE_HOME/rdbms/admin/catalog
@$ORACLE_HOME/rdbms/admin/catproc


connect system/manager
@$ORACLE_HOME/sqlplus/admin/pupbld

REM
REM Oracle 
REM

REM to create Real Application Cluster-related views and tables
REM @$ORACLE_HOME/rdbms/admin/catclust

spool off
!

