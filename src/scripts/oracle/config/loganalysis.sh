#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_loganalysis()
{
#anlyse the log/run
#Analyzing logs during run for both normal and destructive and normal run.
echo "Analysing the logs"

declare -i l_count=0

for i in $CLIENTS
do
        scp  $USER@$i:${WCLOG}/error.log ${WSRANALYZE}/"$i"error.log
done

}

f_loganalysis $*
