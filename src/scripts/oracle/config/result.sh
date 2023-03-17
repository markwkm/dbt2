#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_result()
{
echo
echo "------------------------------"
echo "Test Completed." 
echo "For Results :"
mkdir -p ${WORKHOME}/$TESTNAME
if [ -f "${WSRLOG}/$TESTNAME/run_stop" ];	then
	echo "Test Failed"
	cp ${WSRLOG}/$TESTNAME/run_stop ${WORKHOME}/$TESTNAME/run_fail
	rm -f ${WSRLOG}/$TESTNAME/run_stop
else
	touch ${WORKHOME}/$TESTNAME/run_done
fi
echo
echo "Refer ${WSRANALYZE} for run logs. "
echo "Refer ${WSRMETRICS} for metrics."
echo "------------------------------"
	
}

f_result $*
