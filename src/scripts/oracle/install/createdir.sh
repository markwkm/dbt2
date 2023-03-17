#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_createdirres(){

if [ $1 -ne 0 ];then
        echo "Create $2 directories failed on $3...." | tee  ${WORKHOME}/setup_fail 
        exit -1
else
        echo "Create $2 directories passed on $3...."
fi

}

f_createdir()
{

# Create directory on current node for install
echo "Creating Install Directories...." 
mkdir -p $ISWARE $ISCONFIG $ICCONFIG $ICSCRIPTS
f_createdirres $? "install" `hostname`

# Create directory on all servers
for i in $SERVERS;do
	echo "Creating Server Work Directories  on $i...." 
	ssh -l $USER $i "mkdir -p $WSWARE $WSCONFIG  $WSRLDB $WSRALERT $WSRACREATE $WSRARUN " 
	f_createdirres $? "Server Work" $i
	echo "Creating install  Directories $i...." 
	mkdir -p ${ISCONFIG}/$i
	f_createdirres $? "install" $i
done

# Create directory on all clients
for i in $CLIENTS;do
	echo "Creating Client Work Directories  on $i...."
	ssh -l $USER $i "mkdir -p $WCCONFIG $WCSCRIPTS "
	f_createdirres $? "Client Work" $i
done
}
