#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_gendbscripts()
{
	echo "Generating dbscripts...."
	# Copy template createts.sh to install directory
	cp ${SCONFIGDIR}/createts${WAREHOUSE}.sh ${ISWARE}/createts.sh
	l_createts=${ISWARE}/createts.sh
	declare -i l_count=1

	for i in $SERVERS;do
		echo "addundots.sh roll_${l_count} $UNDOTSLOC/roll_${l_count}_0 996M 128K>roll_${l_count}_1.out 2>&1 & " >> ${l_createts};l_count=$l_count+1
	done
	echo "mv *.out ${WSRLDB}" >> ${l_createts}

	# Copy addts.sh to install directory
	cp ${SCONFIGDIR}/addts.sh ${ISWARE}/addts.sh 
	# Copy addundots.sh to install directory
	cp ${SCONFIGDIR}/addundots.sh ${ISWARE}/addundots.sh
	# Copy createddview.sh to install directory
	cp ${SCONFIGDIR}/createddviews.sh ${ISWARE}/createddviews.sh
	# Copy addts_temp.sh to install directory 
	cp ${SCONFIGDIR}/addts_temp${WAREHOUSE}.sh ${ISWARE}/addts_temp.sh
	# Copy addtempts.sh to install directory
	cp ${SCONFIGDIR}/addtempts.sh ${ISWARE}/addtempts.sh 
	
	NUMCPU=`cat /proc/cpuinfo  |grep -c "processor"`
	export SYS_ROLLBACK4BUILD=60
	export FREELIST_GROUP=4
	export NUMLOADER=10

	INTRANS=`expr ${NUMCPU} \* ${NUMOFSERVERS} \* 100 / 25`
	test "${RAC}" != "true" && INTRANS=`expr ${NUMCPU} \* 100 / 25`	
	test "${INTRANS}" -gt 100 && INTRANS=100
	test $NUMLOADER -gt $WAREHOUSE && NUMLOADER=$WAREHOUSE
	export dop=$NUMLOADER

	# Tables
	f_createwarehouse 
	f_createdistrict
	f_createcustomer
	f_createhistory
	f_createorders
	f_createnew_order
	f_createorder_line
	f_createstock
	f_createitem

	# Indexes
	f_createiwarehouse
	f_createidistrict
	f_createicustomer1
	f_createicustomer2
	f_createistock
	f_createiorder1
	f_createiorder2
	f_createiitem

	# generate scripts to start/stop
	f_createusertemp
	f_shut
	f_startb
	f_createuser
	f_analyze
	f_enable_archivelog
	f_gencommit
	f_statspack

}

f_statspack()
{
echo "generating statspack scripts...."

echo "
. ${SERVERENV}

sqlplus perfstat/perfstat << !

spool ${WSRLOG}/sp_before.log

variable snap_before number;

begin :snap_before := statspack.snap; end;
/
print snap_before
spool off
!
"  > ${ISWARE}/sp_before.sh

echo "
. ${SERVERENV}

sqlplus perfstat/perfstat << !

spool ${WSRLOG}/sp_after.log

variable snap_after number;

begin
:snap_after := statspack.snap;
end;
/

print snap_after

define begin_snap=START_SNAP

define end_snap=:snap_after

define report_name=sp_dbt2

@$ORACLE_HOME/rdbms/admin/spreport
spool off
!
"  > ${ISWARE}/sp_after-template.sh
}

f_gencommit()
{
echo "generating load_commit.sql...."
echo "
spool ${WSRLDB}/load_commit.log;
set echo on;
commit ;
set echo off;
spool off;
exit sql.sqlcode;
" > ${ISWARE}/load_commit.sql
}

f_enable_archivelog()
{
echo "generating enable_archivelog.sh...."
echo "
. ${SERVERENV}
sqlplus \"/ as sysdba\" << !
spool ${WSRLDB}/enable_archivelog.log
set echo on
shutdown
startup pfile=${WSCONFIG}/create.ora mount
alter database archivelog;
rem alter database noarchivelog;
archive log list
shutdown
spool off
set echo off
exit sql.sqlcode
!
 "  > ${ISWARE}/enable_archivelog.sh

}

f_analyze()
{
echo "generating analyze.sql..."
echo "
spool ${WSRLDB}/analyze.log;
set echo on;
connect "${DBUSER}"/"${DBPASSWD}";
ANALYZE TABLE stock ESTIMATE STATISTICS;
ANALYZE TABLE customer ESTIMATE STATISTICS;
ANALYZE TABLE orders ESTIMATE STATISTICS;
ANALYZE TABLE order_line ESTIMATE STATISTICS;
ANALYZE TABLE history ESTIMATE STATISTICS;
ANALYZE TABLE district ESTIMATE STATISTICS;
ANALYZE TABLE item ESTIMATE STATISTICS;
ANALYZE TABLE WAREHOUSE ESTIMATE STATISTICS;
ANALYZE TABLE new_order ESTIMATE STATISTICS;
ANALYZE index iWAREHOUSE ESTIMATE STATISTICS;
ANALYZE index idistrict ESTIMATE STATISTICS;
ANALYZE index iitem ESTIMATE STATISTICS;
ANALYZE index icustomer1 ESTIMATE STATISTICS;
ANALYZE index icustomer2 ESTIMATE STATISTICS;
ANALYZE index istock ESTIMATE STATISTICS;
ANALYZE index iorder1 ESTIMATE STATISTICS;
ANALYZE index iorder2 ESTIMATE STATISTICS;
set echo off;
spool off;
exit sql.sqlcode; " > ${ISWARE}/analyze.sql
}

f_createuser()
{
echo "generating createuser.sql..."
echo "
spool ${WSRLDB}/createuser.log;
set echo on;
create user ${DBUSER} identified by ${DBPASSWD};
grant dba to $DBUSER;
set echo off;
spool off;
exit sql.sqlcode ;
" > ${ISWARE}/createuser.sql
echo "
#!/bin/bash
$SEQLPLUS  $oracle_dba/$oracle_dba_password @createuser > ${WSRLDB}/createuser2.log 2>&1
if test $? -ne 0
then
  exit 1;
else
  exit 0;
fi
 " > ${ISWARE}/createuser.sh
}

f_startb()
{
echo "generating startb.sql..."
echo "
. ${SERVERENV}
$SEQLPLUS $connect_initate_string << !
$SYS_CONNECTION_STRING
spool ${WSRLDB}/startb.log
set echo on
startup pfile=${WSCONFIG}/create.ora open
spool off
set echo off
exit sql.sqlcode
!
" > ${ISWARE}/startb.sh
}

f_shut()
{
echo "generating shut.sql..."
echo "
spool ${WSRLDB}/shut.log;
connect / as sysdba
set echo on;
alter system switch logfile;
alter system switch logfile;
shutdown immediate;
set echo off;
spool off;
exit sql.sqlcode;
 " > ${ISWARE}/shut.sql
echo "
#!/bin/bash
$SEQLPLUS $oracle_dba/$oracle_dba_password @shut > shut2.log 2>&1
if test $? -ne 0
then
  exit 1;
else
  exit 0;
fi
 " > ${ISWARE}/shut.sh
}

f_createiorder2()
{
echo "generating createiorder2.sql..."
echo "
spool ${WSRLDB}/createiorder2.log;
set echo on;
drop index iorder2;
set timing on;
create unique index iorder2 on orders (o_w_id, o_d_id, o_c_id, o_id)
  local
  (" > ${ISWARE}/createiorder2.sql
i=0
s1=`expr ${WAREHOUSE} / ${NUMOFSERVERS} + 1`
p=${s1}
s=`expr $s1 - 1`
end=`expr ${NUMOFSERVERS} - 2`
while [ $i -le ${end} ]
do
	echo "partition iordr2_${i} tablespace iordr2_0," >> ${ISWARE}/createiorder2.sql
	i=`expr $i + 1`
	p=`expr ${p} + ${s}`
done
echo "partition iordr2_${i} tablespace iordr2_0" >> ${ISWARE}/createiorder2.sql
echo ")
  initrans    ${INTRANS}
  parallel    8
  pctfree    25
  storage ( freelists 22 freelist groups ${FREELIST_GROUP} );
spool off;
set echo off;
exit sql.sqlcode;
">>${ISWARE}/createiorder2.sql

}

f_createiorder1()
{
echo "generating createiorder1.sql..."
echo "
spool ${WSRLDB}/createiorder1.log;
set echo on;
drop index iorder1;
set timing on;
create unique index iorder1 on orders (o_w_id, o_d_id, o_id)
  local
  (" > ${ISWARE}/createiorder1.sql
i=0
s1=`expr ${WAREHOUSE} / ${NUMOFSERVERS} + 1`
p=${s1}
s=`expr $s1 - 1`
end=`expr ${NUMOFSERVERS} - 2`
while [ $i -le ${end} ]
do
	echo "partition iordr1_${i} tablespace iordr1_0," >> ${ISWARE}/createiorder1.sql
	i=`expr $i + 1`
	p=`expr ${p} + ${s}`
done
echo "partition iordr1_${i} tablespace iordr1_0" >> ${ISWARE}/createiorder1.sql
echo ")
  initrans    ${INTRANS}
  parallel    8
  pctfree    1
  storage ( freelists 22 freelist groups ${FREELIST_GROUP} );
spool off;
set echo off;
exit sql.sqlcode;
">>${ISWARE}/createiorder1.sql

}

f_createistock()
{
echo "generating createistock.sql..."
cat <<EOF > ${ISWARE}/createistock.sql
spool ${WSRLDB}/createistock.log;
set echo on;
drop index istock;
set timing on;
create unique index istock on stock (s_i_id, s_w_id)
  initrans    ${INTRANS}
  parallel    $dop
  pctfree    1
  storage ( freelists 22 freelist groups ${FREELIST_GROUP} )
  tablespace    istok_0;
spool off;
set echo off;
exit sql.sqlcode;
EOF
}

f_createicustomer2()
{
echo "generating createicustomer2.sql..."
echo "
spool ${WSRLDB}/createicustomer2.log;
set echo on;
drop index icustomer2;
set timing on;
create unique index icustomer2 on customer (c_last, c_w_id, c_d_id, c_first, c_id)
  initrans    ${INTRANS}
  parallel    $dop
  pctfree    1
  nologging
  storage ( freelists 22 freelist groups ${FREELIST_GROUP} )
  tablespace    icust2_0;
spool off;
set echo off;
exit sql.sqlcode;
">${ISWARE}/createicustomer2.sql

}

f_createicustomer1()
{
echo "generating createicustomer1.sql..."
echo "
spool ${WSRLDB}/createicustomer1.log;
set echo on;
drop index icustomer1;
set timing on;
create unique index icustomer1 on customer (c_w_id, c_d_id, c_id)
  initrans    ${INTRANS}
  parallel    $dop
  pctfree    1
  nologging
  storage ( freelists 22 freelist groups ${FREELIST_GROUP} )
  tablespace    icust1_0;
spool off;
set echo off;
exit sql.sqlcode;
">${ISWARE}/createicustomer1.sql

}

f_createiitem()
{
echo "generating createiitem.sql..."
cat <<EOF > ${ISWARE}/createiitem.sql
spool ${WSRLDB}/createiitem.log;
set echo on;
drop index iitem;
set timing on;
create unique index iitem on item (i_id)
  initrans    ${INTRANS}
  parallel    4
  pctfree    5
  storage ( freelists 22 freelist groups ${FREELIST_GROUP} )
  tablespace    iitem_0;
spool off;
set echo off;
exit sql.sqlcode;
EOF

}

f_createidistrict(){
echo "generating createidistrict.sql..."
echo "
spool ${WSRLDB}/createidistrict.log;
set echo on;
drop index idistrict;
set timing on;
create unique index idistrict on district (d_w_id, d_id)
  local
  (" > ${ISWARE}/createidistrict.sql
i=0
s1=`expr ${WAREHOUSE} / ${NUMOFSERVERS} + 1`
p=${s1}
s=`expr $s1 - 1`
end=`expr ${NUMOFSERVERS} - 2`
while [ $i -le ${end} ]
do
	echo "partition idist_${i} tablespace idist_0," >> ${ISWARE}/createidistrict.sql
	i=`expr $i + 1`
	p=`expr ${p} + ${s}`
done

echo "partition idist_${i} tablespace idist_0" >> ${ISWARE}/createidistrict.sql

echo ")
  initrans    ${INTRANS}
  parallel    8
  pctfree    5
  storage ( freelists 22 freelist groups ${FREELIST_GROUP} );
spool off;
set echo off;
exit sql.sqlcode;
">>${ISWARE}/createidistrict.sql
}


f_createiwarehouse()
{
echo "generating createiwarehouse.sql..."
echo "
spool ${WSRLDB}/createiwarehouse.log;
set echo on;
drop index iwarehouse;
set timing on;
create unique index iwarehouse on warehouse (w_id)
  local
  ("> ${ISWARE}/createiwarehouse.sql
i=0
s1=`expr ${WAREHOUSE} / ${NUMOFSERVERS} + 1`
p=${s1}
s=`expr $s1 - 1`
end=`expr ${NUMOFSERVERS} - 2`
while [ $i -le ${end} ]
do
	echo "partition iware_${i} tablespace iware_0," >>${ISWARE}/createiwarehouse.sql
	i=`expr $i + 1`
	p=`expr ${p} + ${s}`
done

echo "partition iware_${i} tablespace iware_0" >>${ISWARE}/createiwarehouse.sql
echo ")
  initrans    ${INTRANS}
  parallel    8
  pctfree    1
  storage ( freelists 22 freelist groups ${FREELIST_GROUP} );
spool off;
set echo off;
exit sql.sqlcode
">>${ISWARE}/createiwarehouse.sql

}

f_createitem(){
echo "generating createitem.sql..."
cat << EOF > ${ISWARE}/createitem.sql
spool ${WSRLDB}/createitem.log;
set echo on;
drop table item;
set timing on;
create table item (
        i_id            number(6,0),
        i_im_id         number,
        i_name          varchar2(24),
        i_price         number,
        i_data          varchar2(50)
)
storage ( buffer_pool keep freelists 22 freelist groups ${FREELIST_GROUP} )
tablespace    item_0
initrans   ${INTRANS}
pctfree    5;
spool off;
set echo off;
exit sql.sqlcode;
EOF

}

f_createstock(){
echo "generating createstock.sql..."
cat <<EOF > ${ISWARE}/createstock.sql
spool ${WSRLDB}/createstock.log;
set echo on;
drop table stock;
set timing on;
create table stock (
        s_i_id          number(6,0),
        s_w_id          number(5,0),
        s_quantity      number,
        s_dist_01       char(24),
        s_dist_02       char(24),
        s_dist_03       char(24),
        s_dist_04       char(24),
        s_dist_05       char(24),
        s_dist_06       char(24),
        s_dist_07       char(24),
        s_dist_08       char(24),
        s_dist_09       char(24),
        s_dist_10       char(24),
        s_ytd           number,
        s_order_cnt     number,
        s_remote_cnt    number,
        s_data          varchar2(50)
)
storage ( buffer_pool keep freelists 22 freelist groups ${FREELIST_GROUP} )
tablespace    stok_0
initrans   ${INTRANS}
pctfree    5;
spool off;
set echo off;
exit sql.sqlcode;
EOF
}

f_createorder_line()
{
echo "generating createorder_line.sql..."
echo "
spool ${WSRLDB}/createorder_line.log;
set echo on;
drop table order_line;
set timing on;
create table order_line (
        ol_o_id         number,
        ol_d_id         number,
        ol_w_id         number,
        ol_number       number,
        ol_i_id         number,
        ol_supply_w_id  number,
        ol_delivery_d   date,
        ol_quantity     number,
        ol_amount       number,
        ol_dist_info    char(24),
        constraint iorder_line primary key (ol_w_id, ol_d_id, ol_o_id, ol_number)
)
  organization index
  partition by range(ol_w_id)
  (" > ${ISWARE}/createorder_line.sql
i=0
s1=`expr ${WAREHOUSE} / ${NUMOFSERVERS} + 1`
p=${s1}
s=`expr $s1 - 1`
end=`expr ${NUMOFSERVERS} - 2`
while [ $i -le ${end} ]
do
echo "partition ordl_${i} values less than (${p})
      tablespace ordl_0," >> ${ISWARE}/createorder_line.sql
	i=`expr $i + 1`
	p=`expr ${p} + ${s}`
done
echo "partition ordl_${i} values less than (maxvalue)
      tablespace ordl_0" >> ${ISWARE}/createorder_line.sql
echo ")
  initrans   ${INTRANS}
  pctfree    5
  storage ( freelists 22 freelist groups ${FREELIST_GROUP} );
spool off;
set echo off;
exit sql.sqlcode;
" >> ${ISWARE}/createorder_line.sql
}

f_createnew_order()
{
echo "generating createnew_order.sql..."
echo "
spool ${WSRLDB}/createnew_order.log;
set echo on;
drop table new_order;
set timing on;
create table new_order (
        no_o_id         number,
        no_d_id         number,
        no_w_id         number,
        constraint inew_order primary key (no_w_id, no_d_id, no_o_id)
)
  organization index
  partition by range(no_w_id)
  (" > ${ISWARE}/createnew_order.sql

i=0
s1=`expr ${WAREHOUSE} / ${NUMOFSERVERS} + 1`
p=${s1}
s=`expr $s1 - 1`
end=`expr ${NUMOFSERVERS} - 2`
while [ $i -le ${end} ]
do
echo "partition nord_${i} values less than (${p})
      tablespace nord_0," >> ${ISWARE}/createnew_order.sql
	i=`expr $i + 1`
	p=`expr ${p} + ${s}`
done
echo "partition nord_${i} values less than (maxvalue)
      tablespace nord_0" >> ${ISWARE}/createnew_order.sql
echo ")
  initrans   ${INTRANS}
  pctfree    5
  storage ( freelists 22 freelist groups ${FREELIST_GROUP} );
spool off;
set echo off;
exit sql.sqlcode;
">>${ISWARE}/createnew_order.sql

}

f_createorders()
{
echo "generating createorders.sql..."
echo "
spool ${WSRLDB}/createorders.log;
set echo on;
drop table orders;
set timing on;
create table orders (
        o_id            number,
        o_d_id          number,
        o_w_id          number,
        o_c_id          number,
        o_entry_d       date,
        o_carrier_id    number,
        o_ol_cnt        number,
        o_all_local     number
)
  partition by range(o_w_id)
  (" > ${ISWARE}/createorders.sql
i=0
s1=`expr ${WAREHOUSE} / ${NUMOFSERVERS} + 1`
p=${s1}
s=`expr $s1 - 1`
end=`expr ${NUMOFSERVERS} - 2`
while [ $i -le ${end} ]
do
echo "partition ordr_${i} values less than (${p})
      tablespace ordr_0," >> ${ISWARE}/createorders.sql
	i=`expr $i + 1`
	p=`expr ${p} + ${s}`
done

echo "partition ordr_${i} values less than (maxvalue)
      tablespace ordr_0" >> ${ISWARE}/createorders.sql
echo ")
  initrans   ${INTRANS}
  pctfree    5
  storage ( freelists 22 freelist groups ${FREELIST_GROUP} );
spool off;
set echo off;
exit sql.sqlcode;
" >> ${ISWARE}/createorders.sql
}

f_createhistory()
{
echo "generating createhistory.sql..."
echo "
spool ${WSRLDB}/createhistory.log;
set echo on;
drop table history;
set timing on;
create table history (
        h_c_id          number,
        h_c_d_id        number,
        h_c_w_id        number,
        h_d_id          number,
        h_w_id          number,
        h_date          date,
        h_amount        number,
        h_data          varchar2(24)
)
  partition by range(h_w_id)
  (" > ${ISWARE}/createhistory.sql
i=0
s1=`expr ${WAREHOUSE} / ${NUMOFSERVERS} + 1`
p=${s1}
s=`expr $s1 - 1`
end=`expr ${NUMOFSERVERS} - 2`
while [ $i -le ${end} ]
do
echo "partition hist_${i} values less than (${p})
      tablespace hist_0," >> ${ISWARE}/createhistory.sql
	i=`expr $i + 1`
	p=`expr ${p} + ${s}`
done
echo "partition hist_${i} values less than (maxvalue)
      tablespace hist_0" >>${ISWARE}/createhistory.sql
echo ")
  initrans  ${INTRANS}
  pctfree    5
  storage ( freelists 22 freelist groups ${FREELIST_GROUP} );
spool off;
set echo off;
exit sql.sqlcode;
" >> ${ISWARE}/createhistory.sql
}

f_createcustomer()
{
echo "generating createcustomer.sql..."
echo "
spool ${WSRLDB}/createcustomer.log;
set echo on;
drop table customer;
set timing on;
create table customer (
        c_id            number(5,0),
        c_d_id          number(2,0),
        c_w_id          number(5,0),
        c_first         varchar2(16),
        c_middle        char(2),
        c_last          varchar2(16),
        c_street_1      varchar2(20),
        c_street_2      varchar2(20),
        c_city          varchar2(20),
        c_state         char(2),
        c_zip           char(9),
        c_phone         char(16),
        c_since         date,
        c_credit        char(2),
        c_credit_lim    number,
        c_discount      number,
        c_balance       number,
        c_ytd_payment   number,
        c_payment_cnt   number,
        c_delivery_cnt  number,
        c_data          varchar2(500)
)
storage ( buffer_pool recycle freelists 22 freelist groups ${FREELIST_GROUP} )
tablespace    cust_0
initrans   ${INTRANS}
pctfree    5;
spool off;
set echo off;
exit sql.sqlcode;
" >> ${ISWARE}/createcustomer.sql
}

f_createdistrict(){
echo "generating createdistrict.sql..."
echo "
spool ${WSRLDB}/createdistrict.log;
set echo on;
drop table district;
set timing on;
create table district (
        d_id            number(2,0),
        d_w_id          number(5,0),
        d_name          varchar2(10),
        d_street_1      varchar2(20),
        d_street_2      varchar2(20),
        d_city          varchar2(20),
        d_state         char(2),
        d_zip           char(9),
        d_tax           number,
        d_ytd           number,
        d_next_o_id     number
)
  partition by range(d_w_id)
  (" > ${ISWARE}/createdistrict.sql
i=0
s1=`expr ${WAREHOUSE} / ${NUMOFSERVERS} + 1`
p=${s1}
s=`expr $s1 - 1`
end=`expr ${NUMOFSERVERS} - 2`
while [ $i -le ${end} ]
do
echo "partition dist_${i} values less than (${p})
      tablespace dist_0," >> ${ISWARE}/createdistrict.sql
	i=`expr $i + 1`
	p=`expr ${p} + ${s}`
done
echo "partition dist_${i} values less than (maxvalue)
      tablespace dist_0" >> ${ISWARE}/createdistrict.sql
echo ")
  initrans   ${INTRANS}
  pctfree    99
  pctused    0
  storage (  freelists 22 freelist groups ${FREELIST_GROUP} );
spool off;
set echo off;
exit sql.sqlcode;
" >> ${ISWARE}/createdistrict.sql
}

f_createwarehouse(){
echo "generating createwarehouse.sql..."
echo "
spool ${WSRLDB}/createwarehouse.log;
set echo on;
drop table warehouse;
set timing on;
create table warehouse(
        w_id            number(5,0),
        w_name          varchar2(10),
        w_street_1      varchar2(20),
        w_street_2      varchar2(20),
        w_city          varchar2(20),
        w_state         char(2),
        w_zip           char(9),
        w_tax           number,
        w_ytd           number
)
  partition by range(w_id)
  ("> ${ISWARE}/createwarehouse.sql
i=0
s1=`expr ${WAREHOUSE} / ${NUMOFSERVERS} + 1`
p=${s1}
s=`expr $s1 - 1`
end=`expr ${NUMOFSERVERS} - 2`
while [ $i -le ${end} ]
do
echo "partition ware_${i} values less than (${p})
      tablespace ware_0," >> ${ISWARE}/createwarehouse.sql
	i=`expr $i + 1`
	p=`expr ${p} + ${s}`
done
echo "partition ware_${i} values less than (maxvalue)
      tablespace ware_0" >> ${ISWARE}/createwarehouse.sql
echo ")
  initrans   ${INTRANS}
  pctfree    98
  pctused    0
  storage (  freelists 22 freelist groups ${FREELIST_GROUP} );
spool off;
set echo off;
exit sql.sqlcode;
">>${ISWARE}/createwarehouse.sql
}

f_createusertemp()
{
echo "generating usertemp.sql..."
echo "
spool ${WSRLDB}/usertemp.log;
set echo on;
alter user ${DBUSER} temporary tablespace temp_0;
set echo off;
spool off;
exit sql.sqlcode;
" >> ${ISWARE}/usertemp.sql
echo  "
#!/bin/bash
$SEQLPLUS $oracle_dba/$oracle_dba_password @usertemp > ${WSRLDB}/usertemp2.log 2>&1
if test $? -ne 0
then
  exit 1;
else
  exit 0;
fi
 " > ${ISWARE}/usertemp.sh

}

f_gencreatedb()
{
# Generate script to create database.
echo "Generating createdb.sh...."
maxinstances=1; test "$RAC" = "true" && maxinstances=${NUMOFSERVERS}
LOGSIZE=`echo "$WAREHOUSE * 50 + 20 " | bc`
maxdatafiles=120
cat <<EOF > ${ISWARE}/createdb.sh
. ${SERVERENV}
$SEQLPLUS $connect_initate_string << !
$SYS_CONNECTION_STRING
spool ${WSRLDB}/createdb.log
set echo on
shutdown abort
startup pfile=${WSCONFIG}/create.ora nomount
create database ${DBNAME}
	controlfile reuse
	maxdatafiles $maxdatafiles
	maxinstances $maxinstances
	datafile  '$DATAFILESLOC/system_001' size 1600M reuse autoextend on
	logfile ('$LOGFILESLOC1/log_11.1', '$LOGFILESLOC2/log_11.2') size ${LOGSIZE}M reuse,
	('$LOGFILESLOC1/log_12.1', '$LOGFILESLOC2/log_12.2') size ${LOGSIZE}M reuse
	undo tablespace undo_sys_ts datafile
	'$UNDOTSLOC/undo_sys_ts.dbf' size 800M reuse autoextend on
	sysaux datafile '$DATAFILESLOC/aux.df' size 1000M reuse autoextend on; 
EOF
	declare -i l_tmp=2
	while [ $l_tmp -le $NUMOFSERVERS ]
	do
		cat  <<EOF >> ${ISWARE}/createdb.sh
		alter database add logfile thread $l_tmp ('$LOGFILESLOC1/log_${l_tmp}1.1', '$LOGFILESLOC2/log_${l_tmp}1.2') size ${LOGSIZE}M reuse, ('$LOGFILESLOC1/log_${l_tmp}2.1', '$LOGFILESLOC2/log_${l_tmp}2.2') size ${LOGSIZE}M reuse;
		alter database enable public thread ${l_tmp};

EOF
		l_tmp=$l_tmp+1
	done
	cat  <<EOF >> ${ISWARE}/createdb.sh
	spool off
	set echo off
	exit sql.sqlcode
	!
EOF
}

