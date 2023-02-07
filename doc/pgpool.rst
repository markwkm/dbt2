pgpool
======

"pgpool is a connection pool server for PostgreSQL. pgpool runs between
PostgreSQL's clients(front ends) and servers(back ends). A PostgreSQL client
can connect to pgpool as if it were a standard PostgreSQL server."

http://pgpool.projects.postgresql.org/

pgpool must be use with Postgresql and the kit is configured to use pgpool by
the --with-pgpool flag with configure.

scripts/pgsql/pgpool.conf is used with pgpool.  backend_host_name must be
changed if the test is being used in a two-tier configuration.
run_workload.sh needs to be passed '-l 9999' otherwise the test will connect
to the database directly instead of using pgpool.  The default port 9999 can
be changed in the pgpool.conf file.

scripts/pgsql/pgsql_profile.in also must be edited so that 'USE_PGPOOL=1'.
configure must also be rerun.
