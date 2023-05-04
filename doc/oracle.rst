Oracle
======

Topics
------
1. Introduction
2. System Requirements
3. Setup
4. Steps for manually run DBT2 Kit
5. Logs
6. Errors and Debugging


Introduction
------------
   	The DBT-2 kit provides an on-line transaction processing (OLTP) workload using oracle database and a set of defined transactions. DBT-2 simulates a workload that represents a wholesale parts supplier operating out of a number of warehouses and their associated sales districts. This kit mainly focuses on three kind of test cases i.e IO,IO_CPU and CPU_ERP,IO testcase mainly imposes load on IO subsystem,CPU_ERP on CPU and IO_CPU on CPU aswell as IO subsystem. This is achieved by varying size of sga paramaters, size of database, io paramaters, and transaction mixes.
	These  transactions basically include entering and delivering orders, recording payments, checking the status of the orders, and monitoring the level of stock at the warehouses.

System Requirements
-------------------

Storage::

    <work-home>        --  10G -- location of logs,results,and server/client configuration scripts
    <archive location> --  5G -- location of archive files
    <storage location> --  9G for  2 warehouses --databse storage location
                       --  18G for 15 warehouses
                       --  36G for 40 warehouses
                       --  72G for 80 warehouses
     /tmp              -- 10MB

for granularity::

    (i.e specifying location for each type of files and tablespace's,instaed of specifying only one storage location for all)
    2-Warehouse: ctrlloc=7.1M    datafiles=3.5G  logloc1=481G   logloc2=481G   tmptsloc=234M  undotsloc=2.8G
    15-Warehouse: ctrlloc=7.1M   datafiles=7.0G  logloc1=3.1G   logloc2=3.1G   tmptsloc=234M  undotsloc=3.0G
    40-Warehouse: ctrlloc=7.1M   datafiles=14G   logloc1=7.9G   logloc2=7.9G   tmptsloc=234M  undotsloc=4.4G
    80-Warehouse: ctrlloc=7.1M   datafiles=25G   logloc1=16G    logloc2=16G    tmptsloc=234M  undotsloc=5.8G

Packages::

    Distribution specific development packages(e.g: gcc,make,binutils,glibc-devel(32 bit and 64 bit))
    sysstat
    bind-utils
    oracle-related package dependencies
    libaio packages
    For gcc version higher than 3.3, compat- gcc for 2.96 or 3.2

Setup
-----

1. Install oracle database
2. Copy dbt2 kit to your work location ( if it is tar file untar it, This should create a directory named dbt2)
3. cd dbt2/scripts/oracle/install

Steps for manually run DBT2 Kit
-------------------------------

1. Kit Setup::

       Setup of dbt2 kit mainly performas following tasks:
       accepts user parameters ,
       creates directries on all nodes,
       generates db create,db build scripts
       generates init ora parameter file,
       generates env file to start client and server,
       generates scripts to start and stop oracle,listener. and then
       copies these scripts to all server and client nodes.

2. How to run setup::

       ./setup or ./setup -responsefile rsp
       where rsp is responsefile which contains all user parameters
       template is available rsp-rac and rsp-sn in <dbt2/scripts/oracle/responsefile> for RAC and single node respectively

       user parameters are:
       TESTCASE=io/io_cpu/cpu_erp          :    type of test
       WORKHOME=<any location>             :    location of work directory for dbt2 kit
       RAC=true/false                      :    true for Rac and false for running on single node
       SERVERS="<hostname>"                :    Name of servers (for rac you can enter more than one server for Single node only one server)
       CLIENTS="<hostname>"                :    Name of clients
       SERVERORAHOME=                      :    server oracle home(location of oracle binaries)
       CLIENTORAHOME=                      :    client oracle home
       WAREHOUSE=2/15/40/80                :    Number of warehouses
       STORAGE TYPE=filesystem/asm         :    Type of storage
       if STORAGE TYPE=filesystem then choose granularity
       GRAN=true/false                     :    true for granularity for database loaction
       if Granularity is true then ,pass locations for each following loaction else no
       LOGFILESLOC1                        :    First Log file location
       LOGFILESLOC2                        :    Second Log file location
       TMPTSLOC                            :    Temporary tablespace location
       UNDOTSLOC                           :    Undo Table space location
       CTRLLOC                             :    Control file location
       if STORAGE TYPE=asm then select type of redundancy
       REDUNDANCY=external/noraml/high     :    Type of redundancy for asm storage
       ASMDISKLIST1=""                     :    asm disks groups for external redundancy
       ASMDISKLIST2=""                     :    asm disk groups for normal redundancy
       ASMDISKLIST3=""                     :    asm disk groups for high redundancy
       ARCHIVE=true/false                  :    true for archiving else false
       ARCHIVELOC=<any location>           :    location for archive files
       DBBLOCKSIZE=2K/4k/8k/16k            :    data block size
       SGA=1                               :    size of SGA in GB
       AIO=true/false                      :    Asynchronous I/O
       DIO=true/false                      :    Direct I/O
       OSSTATS=true/false                  :    True to collect OS statistics for standalone kit
       DRIVER=odbc/oci                     :    type of driver

3. Creating the database for the test run::

       Once setup is done it creates a work directory in WORKHOME(passed during first step) with kitname
       i.e dbt2-work,next to create DataBase move to the following location:
       i.e cd <WORK-HOME/dbt2-work/server/warehouse[number]>

       ./oracle-dbt2.sh -d  --> creates database

4. Test run execution::

       oracle-dbt2.sh  [-r ]--> run kit with default values i.e 100 users and 300 seconds duration

       other optional parameters are
           [-u users]--> Number of users
           [-n testname]--> Testname
           [-t duration]--> Duration in seconds
           [-h ]--> print this mesage
           [-nodb]---> do not start oracle db/asm instance
           [-nolsnr]--> do not start oracle listener
           [-debug]--> For debug on
           [-nocfg]--> Do not change init.ora based on number of users
           [-osstat]--> Do not change init.ora based on number of users

example::

    ./oracle-dbt2.sh -d -r -n mytest -u 300 -t 3600 -osstat
    will create datbase and run kit with test name "mytest", for the duration 3600 seconds with 300 users

Logs
----

::

    <WORK-HOME>/dbt2-work/server/result/testname/analyze    : It contains files related to error during run
    <WORK-HOME>/dbt2-work/server/result/testname/metrics    : It contains result metrics after run for each transactions
    <WORK-HOME>/dbt2-work/server/result/log/datagen-loc     : It contains all data generated during transactions
    <WORK-HOME>/dbt2-work/server/result/log/db-logs         : It contains all database log files
    <WORK-HOME>/dbt2-work/server/result/ora-alert/run-db    : It conatains all trace files generated during run
    <WORK-HOME>/dbt2-work/server/result/ora-alert/create-db : It contains all trace files generated during creation of database

Errors/Debugging
----------------

DB creation Errors: look for::

    <WORK-HOME>/dbt2-work/server/result/log/db-logs
    <WORK-HOME>/dbt2-work/server/result/ora-alert/create-db

Run time Errors: look for::

    <WORK-HOME>/dbt2-work/server/result/ora-alert/run-db
