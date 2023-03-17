#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_gendbstart()
{
echo "Generating dbstart.sh.... "
echo "
.  ${SERVERENV}
sqlplus $connect_initate_string<<!
$SYS_CONNECTION_STRING
spool ${WSRLDB}/dbstartup.log
shutdown abort;
startup pfile="\$1"
spool off
exit sql.sqlcode
!
" > ${ISWARE}/dbstart.sh
}

f_gendbstop()
{
echo "Generating dbstop.sh...."
echo "
.  ${SERVERENV}
sqlplus $connect_initate_string<<!
$SYS_CONNECTION_STRING
spool ${WSRLDB}/dbstop.log
shutdown "\$1"
spool off
exit sql.sqlcode
!
" > ${ISWARE}/dbstop.sh
}



f_gendbctrl()
{
f_gendbstart
f_gendbstop
}
