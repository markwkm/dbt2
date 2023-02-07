----------
User Guide
----------

Introduction
============

This document provides instructions on how to set up and use the Open Source
Development Lab's Database Test 2 (DBT-2) test kit.

The database management systems that are currently supported are:

* PostgreSQL
* SQLite

Databases management systems that have worked in the past but are not current:

* MySQL
* SAP DB

Documentation for the database management systems that are not currently
working remain in the documentation.

Setup
=====

This section covers the steps of retrieving and installing a database and the
DBT-2 test kit source code.  The test kit supports SAP DB and PostgreSQL.

Retrieving and Installing the Kit
---------------------------------

SAP DB
~~~~~~

After installing SAP DB create the user id *sapdb*, assigning the user to group
*sapdb*.

Create the database stats collection tool, x_cons, by executing the
following::

    cp -p /opt/sapdb/indep_prog/bin/x_server /opt/sapdb/indep_prog/bin/x_cons

The test kit requires unixODBC drivers to connect with SAP DB.  The driver
can be retrieved at: http://www.unixodbc.org/unixODBC-2.2.3.tar.gz

After gunzipping the directory unixODBC-2.2.3, cd to the directory and (as
root) install by running::

    ./configure
    make standalone
    make install

PostgreSQL
~~~~~~~~~~

The DBT-2 test kit has been ported to work with PostgreSQL starting with
version 7.3.  It has be updated to work with later version and backwards
compatibility may vary.  Source code for PostgreSQL can be obtained from their
website at: http://www.postgresql.org/

To install PostgreSQL::

    ./configure --prefix=<installation dir>
    make
    make install

Prior to PostgreSQL 8.0 this additional make command is required to ensure the
server include files get installed::

    make install-all-headers

When testing PostgreSQL in a multi-tier system configuration verify the
database has been configuration to accept TCP/IP connections.  For example, the
`listen_addresses` parameter must be set to listen for connections on the
appropriate interfaces.  Remote connections must also be allowed in the
`pg_hba.conf` file.  The simplest (and insecure) way would be to trust all
connections on all interfaces.

Also prior to PostgreSQL 8.0, pg_autovacuum should be installed.  If installing
from source, it is located in the `contrib/pg_autovacuum` directory.

The following subsections have additional PostgreSQL version specific notes.

**v7.3**

With PostgreSQL 7.3, it needs to be built with a change in pg_config.h.in where
INDEX_MAX_KEYS must be set to 64.  Be sure to make this change before running
the configure script for PostgreSQL.

**v7.4**

With PostgreSQL 7.4, it needs to be built with a change in
`src/include/pg_config_manual.h` where INDEX_MAX_KEYS must be set to 64.

Edit the parameter in postgresql.conf that says "tcpip_socket = false",
uncomment, set to true, and restart the daemon.

**v8.0**

For PostgreSQL 8.0 and later, run `configure` with the
`--enable-thread-safety` to avoid SIGPIPE handling for the multi-thread
DBT-2 client program.  This is a significant performance benefit.


DBT-2 Test Kit Source
---------------------

The latest stable version of the kit can be found on SourceForge at:
http://sourceforge.net/projects/osdldbt

Compiling the Test Kit
----------------------

**PostgreSQL**

In the top level directory, `dbt2/`, run::

    make release DBMS=pgsql
    cd builds/release
    make install

After installing PostgreSQL, the DBT-2 stored functions need to be compiled and
installed::

    cd storedproc/pgsql/c
    make
    make install

The 'make install' command will need to be run by the owner of the
database installation.

**SAP DB**

In the top level directory, `dbt2/`, run::

    make release DBMS=sapdb
    cd builds/release
    make install

Environment Configuration
=========================

The section explains how to configure various parts of the system before a
test can be executed.

ODBC
----

An `.odbc.ini` file must reside in the home directory of the user
attempting to run the program.  The format of the file is::

    [alias]
    ServerDB = database_name
    ServerNode = address
    Driver = /opt/sapdb/interfaces/odbc/lib/libsqlod.so
    Description = any text

For example::

    [dbt2]
    ServerDB = DBT2
    ServerNode = 192.168.0.1
    Driver = /opt/sapdb/interfaces/odbc/lib/libsqlod.so
    Description = OSDL DBT-2

is a valid `.odbc.ini` file where dbt2 can be used as the server name to
connect to the database.  Note that the location of _libsqlod.so_ may vary
depending on how your database is installed on your system.

Multi-tier System Testing
-------------------------

The DBT-2 scripts support a 2-tier system configuration where the driver and
client components are run on one tier and the database management system is
running on a separate tier.

The user environment on each system needs to have the same environment
variables defined.  See the database specific examples in the 'examples/'
directory ( e.g. `dbt2_profile`) in order for the scripts to work properly.
For example::

    DBT2PORT=5432; export DBT2PORT
    DBT2DBNAME=dbt2; export DBT2DBNAME
    DBT2PGDATA=/tmp/pgdata; export DBT2PGDATA

An optional environment variable can be set to specify a different location for
the transaction logs (pg_xlog):: 

    DBT2XLOGDIR=/tmp/pgxlogdbt2; export DBT2XLOGDIR

The environment variables must be defined in `~/.ssh/environment` file on each
system.  For example::

    DBT2PORT=5432
    DBT2DBNAME=dbt2
    DBT2PGDATA=/tmp/pgdata
    PATH=/usr/local/bin:/usr/bin:/bin:/opt/bin

Also password-less ssh keys needs to be set up to keep the scripts simple, the
kit needs to be installed in the same location on each system.  Each user must
also have sudo privileges, also without requiring a password.

The ssh server on each system needs to allow user environment processing.  This
is because by default ssh usually has a limited set of environment variables
set.  For example, `/usr/local/bin` is usually not in the path when using ssh
to execute commands locally.  This is disabled by default.  To enable, make the
following change to the sshd config file (typically `/etc/ssh/sshd_config`) and
restart the sshd server::

    PermitUserEnvironment yes

Building the Database
---------------------

The following sections explain how to build the database.  In a multi-tier
system configuration, these scripts must be run on the database systems tier.

PostgreSQL
~~~~~~~~~~

The following command will create a 1 warehouse database in the PGDATA location
specified in the user's environment::

    dbt2-pgsql-build-db -w 1

By default the table data is streamed into the database as opposed to loading
it from files.  See the usage help for additional options::

    dbt2-pgsql-build-db -h

SAP DB
~~~~~~

The script dbt2/scripts/sapdb/create_db_sample.sh must be edited to
configure the SAP DB devspaces.  The param_adddevspaces commands need to be
changed to match your system configuration.  Similarly, the backup_media_put
commands also need to be changed to match your system configuration.  The
script assumes the instance name to be `DBT2`.  Change the line `SID=DBT2`
if you need to change the instance name (in this an all the scripts).  Many
other SAP DB parameters (e.g. MAXCPU) will need to be adjusted based on your
system.

As user sapdb, execute the following script, in dbt2/scripts/sapdb, to
generate the database from scratch (which will execute
create_db_sample.sh)::

    ./db_setup.sh <warehouses> <outputdir>

where <warehouses> is the number of warehouses to build for and
<outputdir> is the directory in which the data files will be generated.
This script will create the data files, create the database, the tables, load
the database, create indexes, update database statistics, load the stored
procedures, and backup the database.  This script assumes the instance name is
`DBT2` so you need to edit the line ''SID=DBT2'' if you need to change the
instance name.

Although the create script starts the remote communication server, it is a
good idea to include the same thing in your system startup scripts
/etc/rc.local::

    # start remote communication server:
    x_server start > /dev/null 2>&1:

There is an option for ''migration'' that needs to be documented, or else
removed from the create_db.sh scripts.

It is higly recommended for performance that you use raw partitions for the
LOG and DATA files.  Here is a sample of the adddevices when using 1 LOG (the
limit is one)  of 1126400 -8k pages and 5 raw DATA devices of 2044800 -8k
pages each::

    param_adddevspace 1 LOG  /dev/raw/raw1 R 1126400
    param_adddevspace 1 DATA /dev/raw/raw2 R 204800
    param_adddevspace 2 DATA /dev/raw/raw3 R 204800
    param_adddevspace 3 DATA /dev/raw/raw4 R 204800
    param_adddevspace 4 DATA /dev/raw/raw5 R 204800
    param_adddevspace 5 DATA /dev/raw/raw6 R 204800

SQLite
~~~~~~

The following command will create a 1 warehouse database in the file location
`/tmp/dbt2-w1` and use the directory `/tmp/dbt2data` to create the table data::

    dbt2-sqlite-build-db -g -w 1 -d /tmp/dbt2-w1 -f /tmp/dbt2data

Running the Test Kit
--------------------

The shell script `dbt2-run-workload` is used to execute a test.  For
example::

    dbt2-run-workload <-a rdbms> <-d sec> <-w #> <-o output_directory> \
                      <-c #>
                      [-ktd sec] [-ktn sec] [-kto sec] [-ktp sec] [-kts sec] \
                      [-ttd ms] [-ttn ms] [-tto ms] [-ttp ms] [-tts ms] [-tpw #] \
                      [-z comment] [-n]

::

    |====================================================================
    |-a   |Specify the RDBMS to test. [mysql,pgsql,sapdb,sqlite]
    |-c   |Specify the number of database connections to open.
    |-d   |Duration to execute test in seconds.
    |-n   |Execute all transactions without think or keying time.
    |-o   |The directory to create for the test results.
    |-ktd |Keying time for the District transaction, default 2.
    |-ktn |Keying time for the New-Order transaction, default 18.
    |-kto |Keying time for the Order-Status transaction, default 2.
    |-ktp |Keying time for the Payment transaction, default 3.
    |-kts |Keying time for the Stock-Level transaction, default 2.
    |-ttd |Think time for the District transaction, default 5000.
    |-ttn |Think time for the New-Order transaction, default 12000.
    |-tto |Think time for the Order-Status transaction, default 10000.
    |-ttp |Think time for the Payment transaction, default 12000.
    |-tts |Think time for the Stock-Level transaction, default 5000.
    |-tpw |The number of terminals to emulate per driver.
    |-w   |The total number of warehouses in the database.
    |-z   |Save any comments about this test run.
    |====================================================================

Executing with multiple tiers
-----------------------------

To execute the test in a multi-tier configuration pass the `-H <address>` flag
to the `dbt2-run-workload` script.  The address can be a hostname or IP
address.

Multi-process driver execution
------------------------------

Default behavior for the driver is to create 10 threads per warehouse under a
single process.  The `-b #` flag can be passed to the `dbt2-run-workload`
script to specify how many warehouses to be created per process.  The script
will calculate how many driver processes to start.

SQLite
------

The `-p` parameter must be passed to the `dbt2-run-workload` script to specify.
Based on the previous example `-p /tmp/dbt2-w1` would be used.

Test Results
============

Under the output directory, specified by the dbt2-run-workload script's `-o`
flag, there are another set of subdirectories and files.

::

    |===============================================================
    |client/           |Output and error logging for dbt2-client
    |db/               |DB stats, OS stats of DB system, db log file
    |driver/           |Output and error logging for dbt2-driver
    |mix.log           |Aggregated transaction response time data
    |perf-annotate.txt |Linux perf annotated source
    |perf.data         |Raw Linux perf data
    |perf-report.txt   |Linux perf report
    |perf-trace.txt    |Linux perf trace
    |readme.txt        |Test details
    |report.txt        |Transaction response time stats
    |report.txt        |Transaction response time stats
    |===============================================================

The Linux perf files are only created if the `-r` flag is used with
`dbt2-run-workload` to collect that data.

The readme.txt displays the comment for the test, uname  information, changes
in kernel parameters from the previous test, and database version information.

HTML Report
-----------

An HTML report with charts and links to the many of the files in the results
directory can be created by running the following command::

    dbt2-generate-report -i <directory>

Where `<directory>` is the path specified by the `-o` flag when running
`dbt2-run-workload`.  This will create an `index.html` file in the
`<directory>`.

SAP DB Results
--------------

Each output files starting with m_*.out, refers to a monitor table in the
SAP DB database.  For example::

    |=============================================================================
    |m_cache.out |MONITOR_CACHE contains information about the operations
                  performed on the different caches.
    |m_lock.out  |MONITOR_LOCK contains information on the database's
                  lock management operations.
    |m_pages.out |MONITOR_PAGES contains information on page accesses.
    |m_trans.out |MONITOR_TRANS contains information on database transaction.
    |m_load.out  |MONITOR_LOAD contains information on the executed SQL
                  statements and access methods.
    |m_log.out   |MONITOR_LOG contains information on the database
                  logging operations.
    |m_row.out   |MONITOR_ROW contains information on operations at the row level.
    |=============================================================================

Additional database locking statistics are collected in lockstats.csv.  The
data and log devspaces statistics are collected in datadev0.txt, datadev1.txt,
logdev0.txt, and logdev1.txt, respectively.
