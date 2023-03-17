#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

echo "Adding undo tablespace $1 of size $3 ..."

$SEQLPLUS $DBUSER/$DBPASSWD <<!
   spool ${WSRLDB}/createts_$1.log
   set echo on

   drop tablespace $1 including contents;
   create undo tablespace $1 datafile '$2' size $3 reuse autoextend on next $4
   maxsize unlimited ;

   set echo off
   spool off
   exit ;
!

