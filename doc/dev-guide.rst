---------------
Developer Guide
---------------

This document is for detailing any related to the development of this test kit.

Building the Kit
================

CMake is build system used for this kit.  A `Makefile` is provided to
automate some of the tasks.

Building for debugging::

    make debug

Building for release::

    make release

Building source packages::

    make package

See the **AppImage** section for details on building an AppImage.  There are
additional requirements for the `appimage` target in the `Makefile`.
Alternatively, the kit provides scripts in the *tools* diretory to create a
container that can create an AppImage.

Testing the Kit
===============

The CMake testing infrastructure is used with shUnit2 to provide some testing.
shUnit2 must be in the PATH.

Running the complete test suite, after building the kit for debugging::

    make test

The tests can also be run directly from the build directory, where `ctest`
offers finer control::

    cd build/debug
    ctest
    ctest -R datagen_stock
    ctest -LE integration
    ctest --output-on-failure
    ctest -R transaction_sqlite -V

The `-V` option shows each test's complete output while
`--output-on-failure` only shows the output of tests that fail.  `ctest`
arguments can be passed through `make test` with e.g. `ARGS="-V"`.  Every
test's full output is also written to `Testing/Temporary/LastTest.log` in
the build directory whether verbose output is enabled or not.

Tests whose additional requirements are not met report as skipped: the
post-process test needs `sqlite3` or R installed, and the integration tests
need the DBMS to have been available when the kit was built.

datagen
-------

Tests are provided to verify that partitioning does not generate different data
than if the data was not partitioned.  There are some data that is generated
with the time stamp of when the data is created, so those columns are ignored
when comparing data since they are not likely to be the same time stamps.

post-process
------------

A test is provided to make sure that the post-process output continues to work
with multiple mix files as well as with various statistical analysis packages.

integration
-----------

A test per database management system builds a small database and executes
each of the five transactions through `dbt2-transaction-test`, verifying the
stored procedures or client side SQL against that system.  These tests are
labeled `integration` and report as skipped when the database system is
unavailable.  MySQL, Oracle, PostgreSQL, and SQLite are currently covered.
The MySQL and PostgreSQL tests run a private server on a socket in
their temporary directories, so they need the server binaries in
addition to the client programs but no running server.  One test each exercises the pl/pgsql stored
functions, the pl/C stored functions, and the client side SQL
implementation.  The pl/C functions are built and loaded without
being installed, which additionally needs the server development
headers, make, and PostgreSQL 18 or later, and that test skips when
they are unavailable.

An Oracle server cannot run as a throwaway process in a temporary
directory, so the Oracle test connects as the user `dbt`, password
`dbt`, to an existing database, or manages one itself, and needs
`sqlplus` and `sqlldr` in the path.  The test drops and recreates
the dbt2 tables and stored procedures in that account's schema each
run.  The `DBT2ORACLE` environment variable (an EZConnect string)
names the database; when it is not set the test probes Oracle
Database Free's fixed local address `//localhost:1521/FREEPDB1` and
uses it if the `dbt` account answers.  When nothing answers and the
host holds an Oracle Database Free software home, the test starts
the FREE database and creates the dbt account if the database
exists but is not running (the official container images ship it
created but stopped), creates the database from the software home's
seed template when it does not exist, which takes about ten
minutes, and leaves it running for later runs to find through the
probe.  Database management commands run
as the oracle software owner: directly when the test runs as
oracle, through `su` when it runs as root, and otherwise through
`su` with the fixed oracle account password the official container
images set.  Because the schema is shared, only one run at a time
may use a given database.  For example::

    DBT2ORACLE=//dbhost:1521/FREEPDB1 ctest -R transaction_oracle -V

AppImage
========

AppImages are only for Linux based systems:

    https://appimage.org/

The AppImageKit AppImage can be downloaded from:

    https://github.com/AppImage/AppImageKit/releases

It is recommended to build AppImages on older distributions:

    https://docs.appimage.org/introduction/concepts.html#build-on-old-systems-run-on-newer-systems

At the time of this document, CentOS 7 is the one of the oldest supported Linux
distributions with the oldest libc version.

The logo used is the number "2" from the Freeware Metal On Metal Font.

See the `README.rst` in the `tools/` directory for an example of creating
an AppImage with a Podman container.

Building the AppImage
---------------------

The AppImages builds a custom minimally configured PostgreSQL build to reduce
library dependency requirements.  Part of this reason is to make it easier to
include libraries with compatible licences.  At least version PostgreSQL 11
should be used for the `pg_type_d.h` header file.

At the time of this document, PostgreSQL 11 was configured with the following
options::

    ./configure --without-ldap --without-readline --without-zlib \
          --without-gssapi --with-openssl

Don't forget that both `PATH` and `LD_LIBRARY_PATH` may need to be set
appropriately depending on where the custom build of PostgreSQL is installed.
