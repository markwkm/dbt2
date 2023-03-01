/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 */

#include <_semaphore.h>

extern int db_conn_sleep;
extern int db_connections;
extern sem_t db_worker_count;
extern int dbms;
extern time_t *last_txn;
extern int *worker_count;

int db_threadpool_init();
