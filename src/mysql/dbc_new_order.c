/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 */

#include "common.h"
#include "logging.h"
#include "mysql_new_order.h"

#include <stdio.h>
#include <string.h>

int execute_new_order_mysql(
		struct db_context_t *dbc, struct new_order_t *data) {
	char stmt[512];
	int rc;
	int line;
	int num_fields;

	MYSQL_RES *result;
	MYSQL_ROW row;

	/* Create the query and execute it. */
	sprintf(stmt,
			"call new_order(%d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d,\
                                 %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d,\
                                 %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d,\
                          %d, %d, @rc)",
			data->w_id, data->d_id, data->c_id, data->o_all_local,
			data->o_ol_cnt, data->order_line[0].ol_i_id,
			data->order_line[0].ol_supply_w_id, data->order_line[0].ol_quantity,
			data->order_line[1].ol_i_id, data->order_line[1].ol_supply_w_id,
			data->order_line[1].ol_quantity, data->order_line[2].ol_i_id,
			data->order_line[2].ol_supply_w_id, data->order_line[2].ol_quantity,
			data->order_line[3].ol_i_id, data->order_line[3].ol_supply_w_id,
			data->order_line[3].ol_quantity, data->order_line[4].ol_i_id,
			data->order_line[4].ol_supply_w_id, data->order_line[4].ol_quantity,
			data->order_line[5].ol_i_id, data->order_line[5].ol_supply_w_id,
			data->order_line[5].ol_quantity, data->order_line[6].ol_i_id,
			data->order_line[6].ol_supply_w_id, data->order_line[6].ol_quantity,
			data->order_line[7].ol_i_id, data->order_line[7].ol_supply_w_id,
			data->order_line[7].ol_quantity, data->order_line[8].ol_i_id,
			data->order_line[8].ol_supply_w_id, data->order_line[8].ol_quantity,
			data->order_line[9].ol_i_id, data->order_line[9].ol_supply_w_id,
			data->order_line[9].ol_quantity, data->order_line[10].ol_i_id,
			data->order_line[10].ol_supply_w_id,
			data->order_line[10].ol_quantity, data->order_line[11].ol_i_id,
			data->order_line[11].ol_supply_w_id,
			data->order_line[11].ol_quantity, data->order_line[12].ol_i_id,
			data->order_line[12].ol_supply_w_id,
			data->order_line[12].ol_quantity, data->order_line[13].ol_i_id,
			data->order_line[13].ol_supply_w_id,
			data->order_line[13].ol_quantity, data->order_line[14].ol_i_id,
			data->order_line[14].ol_supply_w_id,
			data->order_line[14].ol_quantity);

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE("execute_new_order stmt: %s\n", stmt);
#endif

	if (mysql_query(dbc->library.mysql.mysql, stmt)) {

		LOG_ERROR_MESSAGE(
				"mysql reports: SQL: %s,  ERROR: %d %s", stmt,
				mysql_errno(dbc->library.mysql.mysql),
				mysql_error(dbc->library.mysql.mysql));
		return ERROR;
	}

	/*
	 * The stored procedures return the output data as result sets: one
	 * 5 column set per order line from new_order_2() then a 7 column
	 * set from new_order().  A transaction that rolls back stops
	 * producing result sets where the error occurred.
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
		if (num_fields == 5 && line < O_OL_CNT_MAX) {
			if (row[0]) {
				data->order_line[line].i_price = atof(row[0]);
			}
			if (row[1]) {
				snprintf(
						data->order_line[line].i_name,
						sizeof(data->order_line[line].i_name), "%s", row[1]);
			}
			if (row[2]) {
				data->order_line[line].s_quantity = atoi(row[2]);
			}
			if (row[3]) {
				data->order_line[line].ol_amount = atof(row[3]);
			}
			if (row[4]) {
				data->order_line[line].brand_generic = row[4][0];
			}
			++line;
		} else if (num_fields == 7) {
			if (row[0]) {
				data->w_tax = atof(row[0]);
			}
			if (row[1]) {
				data->d_tax = atof(row[1]);
			}
			if (row[2]) {
				data->o_id = atoi(row[2]);
			}
			if (row[3]) {
				snprintf(data->c_last, sizeof(data->c_last), "%s", row[3]);
			}
			if (row[4]) {
				snprintf(data->c_credit, sizeof(data->c_credit), "%s", row[4]);
			}
			if (row[5]) {
				data->c_discount = atof(row[5]);
			}
			if (row[6]) {
				data->total_amount = atof(row[6]);
			}
		}
		mysql_free_result(result);
	} while (mysql_next_result(dbc->library.mysql.mysql) == 0);

	rc = ERROR;

	if (mysql_query(dbc->library.mysql.mysql, "select @rc")) {
		LOG_ERROR_MESSAGE(
				"mysql reports: %d %s", mysql_errno(dbc->library.mysql.mysql),
				mysql_error(dbc->library.mysql.mysql));
	} else {
		if ((result = mysql_store_result(dbc->library.mysql.mysql))) {
			if ((row = mysql_fetch_row(result)) && (row[0])) {
				data->rollback = atoi(row[0]);
				if (data->rollback) {
					LOG_ERROR_MESSAGE(
							"NEW_ORDER ROLLBACK RC %d\n", data->rollback);
				}
				rc = OK;
			} else {
				fprintf(stderr, "Error: %s\n",
						mysql_error(dbc->library.mysql.mysql));
			}
			mysql_free_result(result);
		}
	}

	return rc;
}
