#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################


sqlplus "/ as sysdba" << !
   spool ${WSRLDB}/create_sp.log
   set echo on
   define default_tablespace='sp_0'
   define temporary_tablespace='temp_0'
   @$ORACLE_HOME/rdbms/admin/spcreate
   perfstat
   set echo off
   spool off
   exit ;
!
