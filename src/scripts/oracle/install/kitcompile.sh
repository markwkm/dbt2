#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_kitcompile()
{
for i in $SERVERS;do
	echo "Compiling datagen sources  on $i...."
	ssh -l $USER $i  "export ORACLE_HOME=$SERVERORAHOME ; cd  ${WSWARE}/src ; make -f Makefile.${DRIVER} datagen; "
	if [ $? -ne 0 ];then
		echo "Compile datagen sources  on $i failed...." |tee ${WORKHOME}/setup_fail
                exit -1
        else
                echo "Compile datagen sources  on $i passed...."
        fi
	ssh -l $USER $i "cd  ${WSWARE}/src ; cp bin/datagen ${WSWARE}"
done
test "x$DELAY" = "xtrue" && CFLAGS="-DWITH_DELAY" 

for i in $CLIENTS;do
	echo "Compiling driver sources  on $i...."
	ssh -l $USER $i "export ORACLE_HOME=$CLIENTORAHOME ;export CFLAGS="$CFLAGS"; cd ${WCSCRIPTS}/src ; make -f Makefile.${DRIVER} driver ; "
	if [ $? -ne 0 ];then
                echo "Compile driver sources  on $i failed...." |tee ${WORKHOME}/setup_fail
                exit -1
        else
                echo "Compile driver sources  on $i passed...."
        fi
	ssh -l $USER $i "cd  ${WCSCRIPTS}/src ; cp bin/driver ${WCSCRIPTS}"
done
}

