SQLite
======

To create a database::

    dbt2-sqlite-build-db -g -w 1 -d /tmp/dbt2-w1 -f /tmp/dbt2data

To run a test::

    dbt2-run-workload -a sqlite -p /tmp/dbt2-w1 -c 1 -d 120 -w 1 -n \
            -o /tmp/results

The `-p` parameter must be passed to the `dbt2-run-workload` script to specify
where the SQLite database files are.
