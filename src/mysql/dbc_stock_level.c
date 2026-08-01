/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 */

#include "common.h"
#include "logging.h"
#include "mysql_stock_level.h"

#include <stdio.h>
#include <stdlib.h>

int execute_stock_level_mysql(
		struct db_context_t *dbc, struct stock_level_t *data) {
	char stmt[512];
	int rc = ERROR;
	MYSQL_RES *result;
	MYSQL_ROW row;

	/* Create the query and execute it. */
	sprintf(stmt, "call stock_level(%d, %d, %d, @low_stock)", data->w_id,
			data->d_id, data->threshold);

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE("execute_stock_level stmt: %s\n", stmt);
#endif

	if (mysql_query(dbc->library.mysql.mysql, stmt)) {
		LOG_ERROR_MESSAGE(
				"mysql reports: %d %s", mysql_errno(dbc->library.mysql.mysql),
				mysql_error(dbc->library.mysql.mysql));
		return ERROR;
	}

	/* Read back the transaction's output parameter. */
	if (mysql_query(dbc->library.mysql.mysql, "select @low_stock")) {
		LOG_ERROR_MESSAGE(
				"mysql reports: %d %s", mysql_errno(dbc->library.mysql.mysql),
				mysql_error(dbc->library.mysql.mysql));
	} else {
		if ((result = mysql_store_result(dbc->library.mysql.mysql))) {
			if ((row = mysql_fetch_row(result)) && (row[0])) {
				data->low_stock = atoi(row[0]);
				rc = OK;
			} else {
				LOG_ERROR_MESSAGE(
						"mysql reports: %d %s",
						mysql_errno(dbc->library.mysql.mysql),
						mysql_error(dbc->library.mysql.mysql));
			}
			mysql_free_result(result);
		}
	}

	return rc;
}
