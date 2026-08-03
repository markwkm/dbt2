/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 */

#include "common.h"
#include "logging.h"
#include "mysql_order_status.h"

#include <stdio.h>

int execute_order_status_mysql(
		struct db_context_t *dbc, struct order_status_t *data) {
	char stmt[128];
	char c_last[4 * (C_LAST_LEN + 1)];
	int line;
	int num_fields;

	MYSQL_RES *result;
	MYSQL_ROW row;

	wcstombs(c_last, data->c_last, 4 * (C_LAST_LEN + 1));

	/* Create the query and execute it. */
	sprintf(stmt, "call order_status(%d, %d, %d, '%s')", data->c_id,
			data->c_w_id, data->c_d_id, c_last);

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE("execute_order_status stmt: %s\n", stmt);
#endif
	if (mysql_query(dbc->library.mysql.mysql, stmt)) {
		LOG_ERROR_MESSAGE(
				"mysql reports: SQL STMT %s ERROR: %d %s", stmt,
				mysql_errno(dbc->library.mysql.mysql),
				mysql_error(dbc->library.mysql.mysql));
		return ERROR;
	}

	/*
	 * The stored procedure returns the output data as result sets: a
	 * 9 column set for the customer and order followed by one 5 column
	 * set per order line.
	 */
	line = 0;
	do {
		result = mysql_store_result(dbc->library.mysql.mysql);
		if (result == NULL) {
			continue;
		}
		num_fields = mysql_num_fields(result);
		row = mysql_fetch_row(result);
		if (row == NULL) {
			mysql_free_result(result);
			continue;
		}
		if (num_fields == 9) {
			if (row[0]) {
				data->c_id = atoi(row[0]);
			}
			if (row[1]) {
				snprintf(data->c_first, sizeof(data->c_first), "%s", row[1]);
			}
			if (row[2]) {
				snprintf(data->c_middle, sizeof(data->c_middle), "%s", row[2]);
			}
			if (row[3]) {
				mbstowcs(data->c_last, row[3], C_LAST_LEN + 1);
			}
			if (row[4]) {
				data->c_balance = atof(row[4]);
			}
			if (row[5]) {
				data->o_id = atoi(row[5]);
			}
			if (row[6]) {
				data->o_carrier_id = atoi(row[6]);
			}
			if (row[7]) {
				snprintf(
						data->o_entry_d, sizeof(data->o_entry_d), "%s", row[7]);
			}
		} else if (num_fields == 5 && line < O_OL_CNT_MAX) {
			if (row[0]) {
				data->order_line[line].ol_i_id = atoi(row[0]);
			}
			if (row[1]) {
				data->order_line[line].ol_supply_w_id = atoi(row[1]);
			}
			if (row[2]) {
				data->order_line[line].ol_quantity = atoi(row[2]);
			}
			if (row[3]) {
				data->order_line[line].ol_amount = atof(row[3]);
			}
			if (row[4]) {
				snprintf(
						data->order_line[line].ol_delivery_d,
						sizeof(data->order_line[line].ol_delivery_d), "%s",
						row[4]);
			}
			++line;
		}
		mysql_free_result(result);
	} while (mysql_next_result(dbc->library.mysql.mysql) == 0);
	data->o_ol_cnt = line;

	return OK;
}
