#!/bin/bash 
#set -x
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

usage()
{

echo " Usage:
        setup.sh  -responsefile --> To use response file
                  -debug	--> For debug on
                  -h 		--> print this mesage"
}


while [ $# -gt 0 ]
do
	case $1 in
	
        	-responsefile) 	RSPFILE=$2
				shift 2
				;;
	       	-debug) 	set -x 
				shift 1
				;;
	        -h | -help) 	usage
				exit
				;;
		*)		usage
				exit
				;;
	esac
done

# This script will install, generate all server, client scripts.
echo 
echo "
#########################################################
			DBT2
#########################################################
Welcome to dbt2 

Setup/Configure step 	
" 	
echo 

cd `dirname $0`
SCRIPTDIR="."
. ${SCRIPTDIR}/tmpscript.sh
. ${SCRIPTDIR}/createdir.sh     
. ${SCRIPTDIR}/geninitora.sh      
. ${SCRIPTDIR}/genrunoracle.sh    
. ${SCRIPTDIR}/genasmctrl.sh    
. ${SCRIPTDIR}/gendbctrl.sh     
. ${SCRIPTDIR}/genlistenerctrl.sh  
. ${SCRIPTDIR}/genserverenv.sh    
. ${SCRIPTDIR}/user_handle.sh
. ${SCRIPTDIR}/genclientenv.sh  
. ${SCRIPTDIR}/gendbscripts.sh  
. ${SCRIPTDIR}/genlistenerora.sh   
. ${SCRIPTDIR}/gentnsnamesora.sh  
. ${SCRIPTDIR}/copycs.sh
. ${SCRIPTDIR}/kitcompile.sh
. ${SCRIPTDIR}/genodbcconfig.sh
#####################################################################################

# Take the user input
f_userhandle $RSPFILE 

. ${WORKHOME}/tmp/user.env

cp testsetup.env ${WORKHOME}/tmp/testsetup.env
. ${WORKHOME}/tmp/testsetup.env

# Create directory on all client /server nodes.
f_createdir

# Generate init.ora for create , load and run
f_geninitora

# Generate servers env file
f_genserverenv
. ${ISCONFIG}/server.env		

# Generate listener.ora for all server nodes
f_genlistenerora
	
# Generate clientenv 
f_genclientenv 
	
# Generate tnsnames.ora for client
f_gentnsnamesora 
	
# Generate asm start/stop, create disk group, remove disk group script 
f_asmctrl

# Generate db start/stop scrtipt 
f_gendbctrl

# Generate listner start/stop script 
f_genlistenerctl  

# Generate createdb.sh 
f_gencreatedb

# Generate create table/view/index/tablespaces/user scripts 
f_gendbscripts

# Generate user interface script to create database, generate load, load database and run the test.
f_genrunoracle

# generate odbc configfiles
f_genodbcconfig	

# Copy server related files to all server machines
f_copyserver
	
# Copy client realted files to all client machines.
f_copyclient

# Compike driver(client),datagen(to generate data)
f_kitcompile

touch ${WORKHOME}/setup_done

#remove tmp directory after install completes
rm -rf ${ITMPDIR} 

set +x
echo
echo "End of dbt2 Setup." 

echo
echo "To Run dbt2 Tests on Oracle Database:" 
echo "-------------------------------------"
echo "
1. On machine $MASTERNODE 
	cd $WSWARE 

2. Use oracle-dbt2.sh script to create oracle database 
   and run oracle dbt2 test.
  	eg:
        	To create database run,
        	./oracle-dbt2.sh -d

		To run the test with 300 users and for 3600
		seconds,	
		./oracle-dbt2.sh -r -n mytest -t 3600 -u 300
		
		To see all options available 
		./oracle-dbt2 -h
"

if [ `echo ${ORACLE_VERSION} | awk -F"." '{print $1}'` -ge 11 ];then
        echo "For 11G, mount /dev/shm with size of SGA and set r/w permissions for `id -u -n` user . 
	      eg:  mount none -t tmpfs /dev/shm -osize=${SGA}g
		   chown `id -u -n` -R /dev/shm 	
" 

fi

