#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

l_users=100 
l_duration=300
TESTNAME="mytest"
l_nolsnr="false"
l_nodb="false"
l_nosp="false"
cd `dirname $0`
ENVDIR="../config"

usage()
{

echo " Usage:
	oracle-dbt2.sh	[-d ]--> To create database 
			[-r ]--> To run the test
			[-u users]--> Number of users
			[-n testname]--> Testname
			[-t duration]--> Duration in seconds
			[-h ]--> print this mesage 
			[-nodb]---> do not start oracle db/asm instance
			[-nolsnr]--> do not start oracle listener 
			[-debug]--> For debug on 
			[-nocfg]--> Do not change init.ora based on number of users
			[-osstat]--> To collect os-statistics
			[-nosp]--> To disable statspack collection"
exit
}

#for testname based tests : different result directory
f_createdir_testname()
{
for i in $SERVERS;do
	ssh -l ${USER} $i "rm -rf $WSRANALYZE $WSRMETRICS ; mkdir -p $WSRANALYZE $WSRMETRICS "
done
for i in $CLIENTS
do
	ssh -l ${USER} $i "rm -rf $WCLOG ; mkdir -p $WCLOG "
done
}
	
# Configure run.ora based on user passed parameters	
f_cfgrunora()
{
l_runora=${WSCONFIG}/run.ora
l_processes=`echo "${l_users} * 1.6 + 150" | bc -l | cut -d "." -f1` 
l_ses=`echo "${l_processes} * 2" | bc `
for i in $SERVERS;do	
	ssh -l $USER $i "perl -p -i -e "s%^processes=[0-9]*%processes=$l_processes%g" ${l_runora} "
	ssh -l $USER $i "perl -p -i -e "s%sessions=[0-9]*%sessions=$l_ses%g" ${l_runora} "
done
}


if [ $# -lt 1 ]
then
	usage 
else
	while [ $# -gt 0 ]
	do
		case $1 in 
			-d)
				l_createdb="true"
				echo "Create database.... "
				shift 1	
				;;
			-r)
				l_run="true" 
				echo "Run test.... "
				shift 1	
				;;
			-u)
				l_users=$2  
				shift 2
				;;	
			-n)
				export TESTNAME=$2
				echo "Test name $TESTNAME "
				shift 2
				;;
			-t)
				l_duration=$2
				echo "For duration $l_duration "
				shift 2
				;;
			-nolsnr)
				l_nolsnr=true
				echo "Test will not start oracle listener "
				shift 1 
				;;
			-nodb)
				l_nodb=true
				echo "Test will not start oracle instance "
				shift 1
				;;
			-nosp)
				l_nosp=true
				echo "Test will not collect statspack "
				shift 1
				;;
	                -debug) 
				set -x 
                                shift 1
                                ;;
			-nocfg)
				l_nocfg=true
				shift 1
				;;	
			-osstat)
				l_osstat=true
				shift 1
				;;	
			* )
				usage 
				;;
		esac
	done


fi

. ${ENVDIR}/user.env
. ${ENVDIR}/testsetup.env
. ${ENVDIR}/server.env

l_users=`echo "${l_users} * ${NUMOFSERVERS} / ${NUMOFCLIENTS}" | bc -l | cut -d "." -f1`
test -z  ${l_nocfg} && f_cfgrunora 

test "x$l_osstat" = "xtrue" && ${WSWARE}/os-stats.sh start

if [ "x${l_createdb}" = "xtrue" ];then
	#Create the database
	${WSWARE}/build_db.sh 	
	if [ -f  "${WORKHOME}/dbcre_done" ];then
		echo "Db creation Completed Successfully..."
	else
		echo "Db creation Failed."
		exit -1
	fi	
fi

if [ "x${l_run}" = "xtrue" ];then
	f_createdir_testname 

	# Run the dbt-2 test
	echo "Running $TESTNAME with $l_users users for $l_duration seconds... "
	${WSWARE}/run_db.sh $l_users $l_duration $l_nodb $l_nolsnr $l_nosp 
	
	# Validate the run
	echo "Validating run...."
	${WSWARE}/validate.sh

	# Log analysis
	${WSWARE}/loganalysis.sh

	# Collecting matrics	
	${WSWARE}/collectmetrics.sh

	# Print the result
	${WSWARE}/result.sh 
fi
test "x$l_osstat" = "xtrue" && ${WSWARE}/os-stats.sh stop
set +x 
