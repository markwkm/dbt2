#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

	
l_datagenloc=${WSRLOG}/datagen-loc
# createdir for datagen flatfiles
mkdir -p ${l_datagenloc}
# Run datagen to generate data	
${WSWARE}/datagen -w ${WAREHOUSE} -d ${l_datagenloc} 

# Check for all the datafiles
for l_datafile in ${DATAFILES};do
	if [ ! -f ${l_datagenloc}/${l_datafile}.data ];then
       		echo "failed to create ${l_datagenloc}/${l_datafile}.data "
                exit 1
	fi
done
echo "Finished datagem"

# Load the database 
passwd=$DBUSER/$DBPASSWD
ctrl_file_dir=${WSWARE}/ctl-external
log_dir=${WSRLDB}
cd $ctrl_file_dir

for i in $LOADSQL;do
	perl -p -i -e "s%#LOCATION#%${l_datagenloc}%g" ${i}
	$SEQLPLUS "$DBUSER/$DBPASSWD" @$i
	if [ $? -ne 0 ];then
		echo " loading ${i} failed"
                exit 1
	else
        	echo " Loading ${i} finished"
	fi

done

$SEQLPLUS "$DBUSER/$DBPASSWD" @${WSWARE}/load_commit.sql
exit $?

	
