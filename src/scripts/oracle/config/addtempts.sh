#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################
# Create temporary with name $1 ,name of file $2 and size $3
echo "Creating temporary tablespace $1 of size $3 ...." 
$SEQLPLUS $DBUSER/$DBPASSWD <<!
   spool ${WSRLDB}/createts_$1.log
   set echo on
   drop tablespace $1 including contents;
   create temporary tablespace $1 tempfile '$2' size $3 reuse extent management local uniform size $4;
   set echo off
   spool off
   exit ;
!
