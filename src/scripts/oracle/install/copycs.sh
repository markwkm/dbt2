#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_copyserver()
{
for i in $SERVERS;do
	echo "Copying Server files to $i:${WSWARE}...."
	scp ${ISWARE}/* $USER@$i:${WSWARE}/
	scp -r $SORACLE/ctl-external ${WSWARE}/
	scp -r $SRCKIT/storedproc/oracle $USER@$i:${WSWARE}/
	scp -r ${SRCKIT}/src $USER@$i:${WSWARE}/
done
for i in $SERVERS;do
	echo "Copying Server config files to $i:$WSCONFIG...."
	scp ${ITMPDIR}/user.env ${ITMPDIR}/testsetup.env ${ISCONFIG}/*.env ${ISCONFIG}/*.ora $USER@$i:$WSCONFIG/
	scp ${ISCONFIG}/sqlnet.ora $USER@$i:$SERVERORAHOME/network/admin
done
if [ "x$RAC" = "xtrue" ];then	
	for i in $SERVERS;do
		scp ${ISCONFIG}/$i/* $USER@$i:$WSCONFIG/
	done
fi
for i in $SERVERS;do
	ssh -l $USER $i "cd $WSERVER ; chmod +x -R *  ; "
done
}

f_copyclient()
{
for i in $CLIENTS;do
	echo "Copying Client files to $i...."
	scp ${ICCONFIG}/* $USER@$i:${WCCONFIG}/
	scp ${ICCONFIG}/sqlnet.ora $USER@$i:$CLIENTORAHOME/network/admin/
	scp -r ${SRCKIT}/src $USER@$i:${WCSCRIPTS}/
	if [ "x${DRIVER}" = "xodbc" ];then
		echo "Copying Client .odbc.ini to $i:/home/$USER...."
		scp ${ICCONFIG}/.odbc.ini $USER@$i:/home/$USER
	fi
	ssh -l $USER $i "cd $WCLIENT ; chmod +x -R *  ; "
done
}
