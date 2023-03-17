#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################
f_userhandle()
{
#	. ./user.env
#	mkdir -p ${WORKHOME}/tmp/
#	cp user.env ${WORKHOME}/tmp/user.env
#	return 0;

	USER=`id -un`
	rsp=$1;
	mkdir -p ../../../src/bin
	if [ $? -ne 0 ]
        then
                echo " failed to create bin dir "
                exit -1
        fi

	test  -f "${rsp}" && . "${rsp}"
	if [ -z "$TESTCASE" ]
	then
		echo "select testcase type "
        	select TESTCASE in "io" "io_cpu" "cpu_erp"  
        	do
        		[[ "$TESTCASE" != "" ]] && break
   		done
	fi
	echo "choosen TestCase type = $TESTCASE"

	if [ -z "$WORKHOME" ] 
	then
        	echo "Enter workhome:"
        	read WORKHOME
		if [ "x$WORKHOME" = "x" ];then
                        echo "please enter workhome location "
                        exit -1;
                fi
	fi
	mkdir -p $WORKHOME
	if [ $? -ne 0 ]
        then
	        echo " failed to create ${WORKHOME} "
		exit -1
        fi
	test  -f ${WORKHOME}/setup_done  && rm -f ${WORKHOME}/setup_done
	test -f ${WORKHOME}/setup_fail && rm -f $WORKHOME/setup_fail

	f_perm $WORKHOME

	echo "Workhome choosen is = ${WORKHOME}"

        if [ -z "$RAC" ]
        then
		echo "Is this RAC? "
                select RAC in "true" "false"
                do
                        [[ "$RAC" != "" ]] && break
                done
        fi
        echo "choosen RAC = $RAC "

	if [ "x$RAC" = "xtrue" ]
	then 
               	echo "Enter the systems for servers separated by space "
	else
		echo "Enter the system for server "
	fi

       	if [ -z "$SERVERS" ]
       	then
               	read SERVERS
		if [ "x$SERVERS" = "x" ];then
                        echo "please enter systems for servers "
                        exit -1;
                fi
	fi
	echo "choosen servers = $SERVERS"

	CMDOPTS="-o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no"


        for i in ${SERVERS}
        do
                ping -c 1 -w 3 $i 1> /dev/null
		l_result=$?
                if [ ${l_result} -ne 0 ]
                then
                        echo " $i not reachable " | tee -a $WORKHOME/setup_fail
                        exit -1 
                fi
		ssh -l ${USER} ${CMDOPTS} $i " echo ssh-setup "
		if [ $? -ne 0 ]
		then
			echo "Please Setup Passwordless ssh for ${USER} user " | tee -a $WORKHOME/setup_fail
                        exit -1
		fi
		ssh -l ${USER} ${CMDOPTS} $i " if [ ! -d ${WORKHOME} ]; then mkdir -p ${WORKHOME}; fi "
		if [ $? -ne 0 ]
		then
			echo " failed to create ${WORKHOME} on $i " | tee -a $WORKHOME/setup_fail 
			exit -1
		fi
        done
	NUMOFSERVERS=`echo $SERVERS | awk '{ print NF }'`
	echo "Number of servers = $NUMOFSERVERS"
	MASTERNODE=`echo $SERVERS |awk '{print $1}'`

        if [ -z "$CLIENTS" ]
        then
                echo "Enter the systems for clients separated by space "
                read CLIENTS
		if [ "x$CLIENTS" = "x" ];then
                        echo "please enter systems for clients "
                        exit -1;
                fi
        fi
	echo "choosen clients = $CLIENTS"

        for i in ${CLIENTS}
        do
		ping -c 1 -w 3 $i 1> /dev/null
                l_result=$?
                if [ ${l_result} -ne 0 ]
                then
                        echo " not able to ping $i " | tee -a $WORKHOME/setup_fail
                        exit -1 
                fi
		ssh -l ${USER} ${CMDOPTS} $i " echo ssh-setup "
		if [ $? -ne 0 ]
		then
			echo "Please Setup Passwordless ssh for ${USER} user " | tee -a $WORKHOME/setup_fail
                        exit -1

		fi
		ssh -l ${USER}  ${CMDOPTS} $i " if [ ! -d ${WORKHOME} ]; then mkdir -p ${WORKHOME}; fi "
                if [ $? -ne 0 ]
                then
                        echo " failed to create ${WORKHOME} on $i " | tee -a $WORKHOME/setup_fail
                        exit -1
                fi
	done
        NUMOFCLIENTS=`echo $CLIENTS | awk '{ print NF }'`
	echo "Number of clients = $NUMOFCLIENTS"
	
	f_chkspace "${WORKHOME}" "10485760" "$MASTERNODE" 

	for i in  $SERVERS $CLIENTS
	do
		f_chkspace "${WORKHOME}" "1048576" "$i" 
	done
	
	echo "Checking passwordless ssh...."
	f_chkforssh

	echo "Checking passwordless scp...."
	f_chkforscp

	echo "Checking user id ...."
	f_chkforid


        if [ -z "$SERVERORAHOME" ]
        then
	        echo "Enter server oracle home "
                read SERVERORAHOME
		if [ "x$SERVERORAHOME" = "x" ];then
                        echo "please enter server oracle home "
                        exit -1;
                fi
        fi
	for i in $SERVERS  
	do
		ssh -l ${USER} ${CMDOPTS} $i " test -f ${SERVERORAHOME}/bin/sqlplus "
		if [ $? -eq 0 ];
       		then
       	        	export ORACLE_HOME=${SERVERORAHOME} 
                	export ORACLE_VERSION=`ssh -l ${USER} ${CMDOPTS} $i " export ORACLE_HOME=\${SERVERORAHOME} ; ${SERVERORAHOME}/bin/sqlplus -V"`
			export ORACLE_VERSION=`echo $ORACLE_VERSION | awk '/Release/ {print $3}'`
        	else
			echo "oracle home doesn't exist" | tee -a $WORKHOME/setup_fail
			exit -1		
		fi
	done
	echo "oracle version = $ORACLE_VERSION"
	echo "Server oracle home = $SERVERORAHOME"
        if [ -z "$CLIENTORAHOME" ]
        then
        	echo "Enter client oracle home "
#        	Note:it should be insta client home for odbc implimentation"
                read CLIENTORAHOME
		if [ "x$CLIENTORAHOME" = "x" ];then
                        echo "please enter client oracle home "
                        exit -1;
                fi
        fi
	echo "Client oracle home = $CLIENTORAHOME"
        
	if [ -z "$WAREHOUSE" ]
        then
		echo "select number of warehouses"
                select WAREHOUSE in "2" "15" "40" "80"
                do
                        [[ "$WAREHOUSE" != "" ]] && break
                done
        fi
        echo "number of Warehouses = $WAREHOUSE"	
	
        if [ -z "$STORAGETYPE" ]
        then
		echo "select storage type"
                select STORAGETYPE in "filesystem"  "asm"
                do
                        [[ "$STORAGETYPE" != "" ]] && break
                done
        fi
        echo "choosen storage type = $STORAGETYPE"

	if [ "x$STORAGETYPE" = "xfilesystem" ]
	then
		if [ -z "$DATAFILESLOC" ]
		then
        		echo "Enter storage location for db files"
			read DATAFILESLOC
			if [ "x$DATAFILESLOC" = "x" ]
	                then
        	                echo "please enter storage location for db files"
                	        exit -1;
	                fi
		fi

		f_crdir $MASTERNODE $DATAFILESLOC
		datafiles_size=`f_getsize ${WAREHOUSE} 1`
		echo "datafiles_size=$datafiles_size"

		if [ -z "$GRAN" ]
		then
			echo "Do you want to specify more granularity for db related files ?"
			select GRAN in "true"  "false"
			do
                        	[[ "$GRAN" != "" ]] && break
                	done
		fi
		if [ "x$GRAN" = "xtrue" ]
		then	
			if [ -z "$LOGFILESLOC1" ]
	                then
        	                echo "Enter storage location for log group1"
        	                echo "Default: $DATAFILESLOC"
                	        read LOGFILESLOC1
				test -z "$LOGFILESLOC1" && LOGFILESLOC1=$DATAFILESLOC ;
			fi
			if [ $LOGFILESLOC1 != $DATAFILESLOC ]
			then	
				f_crdir $MASTERNODE $LOGFILESLOC1		
				l_size=`f_getsize ${WAREHOUSE} 2`		
				datafiles_size=`expr $datafiles_size - $l_size`
				f_checkall "$LOGFILESLOC1" $l_size 	
			fi
				
			if [ -z "$LOGFILESLOC2" ]
	                then
        	                echo "Enter storage location for log group2"
        	                echo "Default: $DATAFILESLOC"
                	        read LOGFILESLOC2
				test -z "$LOGFILESLOC2" && LOGFILESLOC2=$DATAFILESLOC ;
			fi		
			if [ $LOGFILESLOC2 != $DATAFILESLOC ]
			then
				f_crdir $MASTERNODE $LOGFILESLOC2		
				l_size=`f_getsize ${WAREHOUSE} 3`		
				datafiles_size=`expr $datafiles_size - $l_size`
				f_checkall "$LOGFILESLOC2" $l_size 	
			fi
			
			if [ -z "$TMPTSLOC" ]
	                then
        	                echo "Enter storage location for temp tablespace"
        	                echo "Default: $DATAFILESLOC"
                	        read TMPTSLOC
				test -z "$TMPTSLOC" && TMPTSLOC=$DATAFILESLOC ;
			fi
			if [ $TMPTSLOC != $DATAFILESLOC ]
                        then	
				f_crdir $MASTERNODE $TMPTSLOC	
				l_size=`f_getsize ${WAREHOUSE} 4`		
				datafiles_size=`expr $datafiles_size - $l_size`
				f_checkall "$TMPTSLOC" $l_size 	
				
			fi
			if [ -z "$UNDOTSLOC" ]
	                then
        	                echo "Enter storage location for undo tablespace"
        	                echo "Default: $DATAFILESLOC"
                	        read UNDOTSLOC
				test -z "$UNDOTSLOC" && UNDOTSLOC=$DATAFILESLOC ;
			fi
			if [ $UNDOTSLOC != $DATAFILESLOC ]
                        then		
				f_crdir $MASTERNODE $UNDOTSLOC
				l_size=`f_getsize ${WAREHOUSE} 5`		
				datafiles_size=`expr $datafiles_size - $l_size`
				f_checkall "$UNDOTSLOC" $l_size 	
			fi
			if [ -z "$CTRLLOC" ]
                        then
                                echo "Enter storage location for control file"
                                echo "Default: $DATAFILESLOC"
                                read CTRLLOC
                                test -z "$CTRLLOC" && CTRLLOC=$DATAFILESLOC ;
                        fi
                        if [ $CTRLLOC != $DATAFILESLOC ]
                        then
                                f_crdir $MASTERNODE $CTRLLOC
                                l_size=`f_getsize ${WAREHOUSE} 6`
                                datafiles_size=`expr $datafiles_size - $l_size`
                                f_checkall "$CTRLLOC" $l_size
                        fi

		else
			CTRLLOC=$DATAFILESLOC ;
			UNDOTSLOC=$DATAFILESLOC ;
			TMPTSLOC=$DATAFILESLOC ;
			LOGFILESLOC2=$DATAFILESLOC; 
			LOGFILESLOC1=$DATAFILESLOC; 
		fi
		f_checkall "$DATAFILESLOC" $datafiles_size

		ssh -l ${USER} ${CMDOPTS} $MASTERNODE " if [ ! -d ${DATAFILESLOC} ]; then mkdir -p ${DATAFILESLOC}; fi "
                if [ $? -ne 0 ]
                then
                        echo " failed to create ${DATAFILESLOC} on $MASTERNODE " | tee -a $WORKHOME/setup_fail
                        exit -1
                fi
        fi	
	
	if [ "x$STORAGETYPE" = "xasm" ]
        then
		# asm group name
		export ASMGROUPNAME="asmgrp${WAREHOUSE}"

		if [ -z "$REDUNDANCY" ]
		then
			echo "select redundancy "
			select REDUNDANCY in "external"  "normal" "high"
        	        do
                	        [[ "$REDUNDANCY" != "" ]] && break
	                done
		fi
		echo "choosen Redundancy = $REDUNDANCY"
	
		if [ "x$REDUNDANCY" = "xexternal" ]
		then
			if [ -z "$ASMDISKLIST1" ]
			then
				echo "Enter one set of disks (separated by space) "
        			read ASMDISKLIST1
				if [ "x$ASMDISKLIST1" = "x" ];then
                                        echo "please enter one set of disks (separated by space)"
                                        exit -1
                                fi

			fi
			echo "ASM disks for external Redundancy = $ASMDISKLIST1"
		fi

		if [ "x$REDUNDANCY" = "xnormal" ]
               	then
		        if [ -z "$ASMDISKLIST1" ]
		        then
                		echo "Enter disks for fail group1 (separated by space) "
		                read ASMDISKLIST1
				if [ "x$ASMDISKLIST1" = "x" ];then
                                        echo "please enter one set of disks (separated by space)"
                                        exit -1
                                fi

			fi
			if [ -z "$ASMDISKLIST2" ]	
			then
	               	   	echo "Enter disks for fail group2 (separated by space) "
				read ASMDISKLIST2
				if [ "x$ASMDISKLIST2" = "x" ];then
                                        echo "please enter disks for fail group2 (separated by space)"
                                        exit -1
                                fi
			fi
			echo "Fail group1 ASM disks for normal Redundancy = $ASMDISKLIST1"
			echo "Fail group2 ASM disks for normal Redundancy = $ASMDISKLIST2"
               	fi
		if [ "x$REDUNDANCY" = "xhigh" ]
               	then
			if [ -z "$ASMDISKLIST1" ]
			then
	                       	echo "Enter disks for fail group1 (separated by space) "
        	               	read ASMDISKLIST1
				if [ "x$ASMDISKLIST1" = "x" ];then
                                        echo "please enter one set of disks (separated by space)"
                                        exit -1
                                fi

			fi		
			if [ -z "$ASMDISKLIST2" ]
			then
	                       	echo "Enter disks for fail group2 (separated by space) "
				read ASMDISKLIST2
				if [ "x$ASMDISKLIST2" = "x" ];then
                                        echo "please enter disks for fail group2 (separated by space)"
                                        exit -1
                                fi

			fi
			if [ -z "$ASMDISKLIST3" ]
			then
	                       	echo "Enter disks for fail group3 (separated by space) "
        	               	read ASMDISKLIST3
				if [ "x$ASMDISKLIST3" = "x" ];then
                                        echo "please enter disks for fail group3 (separated by space)"
                                        exit -1
                                fi

			fi
			echo "Fail group1 ASM disks for high Redundancy = $ASMDISKLIST1"
			echo "Fail group2 ASM disks for high Redundancy = $ASMDISKLIST2"
			echo "Fail group3 ASM disks for high Redundancy = $ASMDISKLIST3"
               	fi
	
		NUM_ASMDISKS1=`echo $ASMDISKLIST1 | awk '{ print NF }'`	
		echo "number of asmdisks for fail group1 = $NUM_ASMDISKS1"
		NUM_ASMDISKS2=`echo $ASMDISKLIST2 | awk '{ print NF }'`	
		echo "number of asmdisks for fail group2 = $NUM_ASMDISKS2"
		NUM_ASMDISKS3=`echo $ASMDISKLIST3 | awk '{ print NF }'`	
		echo "number of asmdisks for fail group3 = $NUM_ASMDISKS3"
		DATAFILESLOC="+${ASMGROUPNAME}"
		CTRLLOC=$DATAFILESLOC ;
		UNDOTSLOC=$DATAFILESLOC ;
		TMPTSLOC=$DATAFILESLOC ;
		LOGFILESLOC2=$DATAFILESLOC; 
		LOGFILESLOC1=$DATAFILESLOC; 
	fi

        if [ -z "$ARCHIVE" ]
        then
		echo "select archive "
                select ARCHIVE in "true" "false"
                do
                        [[ "$ARCHIVE" != "" ]] && break
                done
        fi
        echo "choosen Archive = $ARCHIVE"

        if [ "x$ARCHIVE" = "xtrue" ]
        then
                if [ -z "$ARCHIVELOC" ]
                then
                        echo "Enter Archive location"
                        read ARCHIVELOC
			if [ "x$ARCHIVELOC" = "x" ]; then
                                echo "please enter Archive location "
                                exit -1;
                        fi

                fi
		for i in ${SERVERS}
                do
                        ssh -l ${USER} ${CMDOPTS} $i " if [ ! -d ${ARCHIVELOC} ]; then mkdir -p ${ARCHIVELOC}; fi "
                        if [ $? -ne 0 ]
                        then
                                echo " failed to create ${ARCHIVELOC} on $i " | tee -a $WORKHOME/setup_fail
                                exit -1
                        fi

			echo "checking permission and space on archive location"
	                f_perm "$ARCHIVELOC" 
        	        f_chkspace "$ARCHIVELOC" "5242880" "$MASTERNODE"
                done
		echo "choosen Archive location = $ARCHIVELOC"
        fi

        if [ -z "$DBBLOCKSIZE" ]
        then
		echo "select database block size "
                select DBBLOCKSIZE in "2048" "4096" "8192" "16384"
                do
                        [[ "$DBBLOCKSIZE" != "" ]] && break
                done
        fi
        echo "Database block size = $DBBLOCKSIZE"

        if [ -z "$SGA" ]
        then
		declare -i SGA
                echo "Enter sga in gb "
                read SGA
		if [ $SGA = 0 ]
                then
                        echo "enter integer value for sga\n" | tee -a $WORKHOME/setup_fail
                        exit -1
                fi
		echo "SGA=$SGA"
        fi

        if [ -z "$AIO" ]
        then
		echo "Async IO (AIO) ?"
                select AIO in "true" "false"
                do
                        [[ "$AIO" != "" ]] && break
                done
        fi
        echo "choosen AIO = $AIO"

        if [ -z "$DIO" ]
        then
		echo "Direct IO (DIO) ? "
                select DIO in "true" "false"
                do
                        [[ "$DIO" != "" ]] && break
                done
        fi
        echo "choosen DIO = $DIO"

        if [ "x$RAC" = "xtrue" ] 
        then
		l_crspath=` ssh -l ${USER} ${CMDOPTS} $MASTERNODE " ps -eo command |grep crsd.bin|grep -v grep | grep -v defunct"`
		l_crspath=`echo $l_crspath | awk '{print $1}' `

                if [ ! -z "$l_crspath" ]
                then
                        l_crsbin=`dirname $l_crspath`
                        CLUSTERWAREHOME=`dirname $l_crsbin`
                fi
                if [ -z "$CLUSTERWAREHOME" ]
                then
                	echo "Enter clusterware home "
                        read CLUSTERWAREHOME
			if [ "x$CLUSTERWAREHOME" = "x" ];then
                                echo "please enter clusterware home location "
                                exit -1;
                        fi
                fi
		echo "clusterware home = $CLUSTERWAREHOME"

                if [ -z "$SERVERVIP" ]
                then
			ssh -l ${USER} ${CMDOPTS} $MASTERNODE " test -f ${CLUSTERWAREHOME}/bin/olsnodes"

			if [ $? -eq 0 ];then
				for i in `ssh -l ${USER} ${CMDOPTS} $MASTERNODE "${CLUSTERWAREHOME}/bin/olsnodes -i " | awk '{print $2}' `;do	
        			SERVERVIP="$SERVERVIP $i"
				done
                        fi
                fi
		if [ `echo $SERVERVIP | grep -c none ` -gt 0 ]
		then
			SERVERVIP="$SERVERS"
		fi
		echo "servervip of choosen servers = $SERVERVIP"
		if [ `echo $SERVERVIP | grep -ic Error ` -gt 0 ]
                then
                        echo "WARNING:  server vip not set correctly"
                fi

        fi
	
        if [ -z "$DRIVER" ]
        then
		echo "Driver to use ? "
                select DRIVER in "odbc" "oci"
                do
                        [[ "$DRIVER" != "" ]] && break
                done
        fi
        echo "choosen Driver = $DRIVER"

	mkdir -p ${WORKHOME}/tmp/
	if [ $? -ne 0 ]
        then
                echo " failed to create ${WORKHOME}/tmp " | tee -a $WORKHOME/setup_fail
                exit -1
        fi

	echo "#!/bin/bash
	export ORACLE_VERSION="$ORACLE_VERSION"

	# during run so remove from geninit.ora
	export USERS=100
	export USER=$USER
	export TESTCASE=$TESTCASE
	export OLT_FLAG=$OLT_FLAG
	export WORKHOME=$WORKHOME
	export STORAGETYPE=$STORAGETYPE
	export WAREHOUSE=$WAREHOUSE
	export ARCHIVE=$ARCHIVE
	export ARCHIVELOC=$ARCHIVELOC
	export DBBLOCKSIZE=$DBBLOCKSIZE
	export SGA=$SGA
	export GRAN=$GRAN
	export AIO=$AIO
	export DIO=$DIO
	export DURATION=$DURATION
	export SERVERS=\"$SERVERS\"
	export CLIENTS=\"$CLIENTS\"
	export SERVERORAHOME=$SERVERORAHOME
	export CLIENTORAHOME=$CLIENTORAHOME
	export RAC=$RAC
	export CLUSTERWAREHOME=$CLUSTERWAREHOME
	export SERVERSVIP=\"$SERVERVIP\"
	export DRIVER=$DRIVER
	export REDUNDANCY=$REDUNDANCY
	export ASMDISKLIST1=\"$ASMDISKLIST1\"
        export ASMDISKLIST2=\"$ASMDISKLIST2\"
        export ASMDISKLIST3=\"$ASMDISKLIST3\"
	export NUM_ASMDISKS1=$NUM_ASMDISKS1
	export NUM_ASMDISKS2=$NUM_ASMDISKS2
	export NUM_ASMDISKS3=$NUM_ASMDISKS3
	export DELAY=$DELAY
	export DATAFILESLOC=$DATAFILESLOC
	export UNDOTSLOC=$UNDOTSLOC
	export TMPTSLOC=$TMPTSLOC
	export LOGFILESLOC2=$LOGFILESLOC2
	export LOGFILESLOC1=$LOGFILESLOC1
	export CTRLLOC=$CTRLLOC
	export ASMGROUPNAME=$ASMGROUPNAME
	export NO_SLEEP=$NO_SLEEP
	export MTARGET=$MTARGET
	export NUMOFSERVERS=$NUMOFSERVERS
	export NUMOFCLIENTS=$NUMOFCLIENTS  "  > ${WORKHOME}/tmp/user.env

	echo "user_handle completed " 
	return 0
}

f_checkall()
{
	l_allnodes="$SERVERS $CLIENTS"
	l_loc=$1
	l_spc=$2
	echo "checking permission on $l_loc ... "
	f_perm "$l_loc"

	f_chkspace "$l_loc" "$l_spc" "$MASTERNODE"
	if [ "x$RAC" = "xtrue" ]
	then
		echo "checking for shared location ..."
		f_chkforshared "$l_loc"
	fi
}

f_perm ()
{
        l_perdir=$1
        case "$l_perdir" in
        "" )
                echo "Please enter the value..."
        ;;
        * )
                if test -d "$l_perdir"
                then
                        perm=`touch ${l_perdir}/mytouch 2>&1`
                        case $perm in
                        "" )
                        ;;
                        * )
                                echo " directory is not writable." | tee -a $WORKHOME/setup_fail
				exit -1
                        ;;
                        esac
			rm -f ${l_perdir}/mytouch
                else
                        echo "$l_perdir is not a directory" | tee -a $WORKHOME/setup_fail
			exit -1
                fi
        ;;
        esac
}

f_chkforssh()
{
        declare -i l_count=1
        CMDOPTS="-o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no"
	l_allnodes="$SERVERS $CLIENTS"

        for i in ${l_allnodes}
        do
                declare -i l_counter=1
                for j in ${l_allnodes}
                do
                        ssh $i -l ${USER} ${CMDOPTS} ssh $j  -l ${USER} ${CMDOPTS} echo "X" > /dev/null
                        l_result=$?
                        if [ ${l_result} -ne 0 ]
                        then
                                echo "from $i to $j failed " | tee -a $WORKHOME/setup_fail
        			exit -1
                        fi
                        l_counter=${l_counter}+1 
                done
                l_count=${l_count}+1 
        done
}

f_chkforscp()
{
        l_srcloc=${WORKHOME}/touch_src
        touch $l_srcloc
        l_destloc="${WORKHOME}"
        declare -i l_count=1
        CMDOPTS="-o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no"

        l_allnodes="$SERVERS $CLIENTS"

        for i in ${l_allnodes}
        do
                declare -i l_counter=1
                for j in ${l_allnodes}
                do
                        scp  ${l_srcloc} ${USER}@$j:${l_destloc}/touch_dest 1> /dev/null
                        l_result=$?
                        if [ ${l_result} -ne 0 ]
                        then
                                echo "from $i to $j failed " | tee -a $WORKHOME/setup_fail
                                exit -1 
                        fi
                        l_counter=${l_counter}+1 
                done
                l_count=${l_count}+1 
        done
        for i in ${l_allnodes}
        do
                ssh $i -l ${USER} ${CMDOPTS} rm -f $l_destloc/touch_dest $l_destloc/touch_src
        done
        rm -f ${WORKHOME}/touch_src
}

f_chkforid()
{
        CMDOPTS="-o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no"
        l_allnodes="$SERVERS $CLIENTS"
        declare -i l_counter=0

        for j in ${l_allnodes}
        do
                ssh $j  -l ${USER} ${CMDOPTS} id | awk '{print $1, $2}' > ${WORKHOME}/id${l_counter}
                l_result=$?
                if [ ${l_result} -ne 0 ]
                then
                        echo " ssh failed " | tee -a $WORKHOME/setup_fail
                        exit -1 
                fi
                l_counter=${l_counter}+1 
        done
        l_counter=${l_counter}-1 
        until [ $l_counter -eq 0 ]
        do
                l_a=${l_counter}
                l_b=`expr ${l_counter} - 1`
                diff ${WORKHOME}/id$l_a ${WORKHOME}/id$l_b
                l_result=$?
                if [ $l_result -ne 0 ]
                then
                        echo "Different id's for user ${USER} across nodes" | tee -a $WORKHOME/setup_fail
                        exit -1
                fi
                l_counter=${l_counter}-1 
        done
        rm -rf ${WORKHOME}/id*
}

f_chkforshared()
{
        declare -i l_count=1
        CMDOPTS="-o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no"
	l_loc=$1

        l_allnodes="$SERVERS"

        for i in ${l_allnodes}
        do
		ssh $i -l ${USER} ${CMDOPTS} touch $l_loc/mytouch
		l_result=$?
                if [ ${l_result} -ne 0 ]
                then
 	                echo "shared loc $l_loc not writable from $i " | tee -a $WORKHOME/setup_fail
                        exit -1 
		fi
                declare -i l_counter=1
                for j in ${l_allnodes}
                do
                        ssh $j  -l ${USER} ${CMDOPTS} ls $l_loc/mytouch 1> /dev/null
                        l_result=$?
                        if [ ${l_result} -ne 0 ]
                        then
                                echo "storage loc $l_loc is not shared across $i and $j " | tee -a $WORKHOME/setup_fail 
                                exit -1 
			fi
                        l_counter=${l_counter}+1 
                done
                l_count=${l_count}+1 
		ssh $i -l ${USER} ${CMDOPTS} rm -f $l_loc/mytouch
        done
}
f_chkspace()
{
	test "x$DBSPACECHK" = "xfalse" && return 0; 
        l_chkdir=$1
	l_spc=$2
	l_node=$3
	echo "checking space $l_spc on $l_node for $l_chkdir ..."
        for j in `ssh -l ${USER}  ${CMDOPTS} $l_node df -k ${l_chkdir} | tr -s " " ":" | cut -d: -f4 | tail -1`
	do
		if [ $j -lt $l_spc ]
	     	then
        	 	echo "$l_chkdir does not have space $l_spc on $i" | tee -a $WORKHOME/setup_fail
             		echo "available space is $j Kbytes.." | tee -a $WORKHOME/setup_fail
	           	exit -1
		fi
	done
}
f_crdir()
{
		l_node=$1
		l_loc=$2	
		
                ssh -l ${USER} ${CMDOPTS} $l_node " if [ ! -d $l_loc ]; then mkdir -p ${l_loc}; fi "
		if [ $? -ne 0 ]
                then
                	echo " failed to create ${l_loc} on $i " | tee -a $WORKHOME/setup_fail
                        exit -1
		fi
}
f_getsize ()
{
        wh=$1
        col=$2
        case $wh in
                15 ) row=2
                ;;
                40 ) row=3
                ;;
                80 ) row=4
                ;;
                * ) row=1
                ;;
        esac
        size=`cat templatesize | cut -d":" -f$col  |head -$row | tail -1 `
        echo $size
	return $size
}
