/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 */

#include "common.h"
#include "logging.h"
#include "mysql_payment.h"

#include <stdio.h>

int execute_payment_mysql(struct db_context_t *dbc, struct payment_t *data) {
	char stmt[512];
	char c_last[4 * (C_LAST_LEN + 1)];

	MYSQL_RES *result;
	MYSQL_ROW row;

	wcstombs(c_last, data->c_last, 4 * (C_LAST_LEN + 1));

	/* Create the query and execute it. */
	sprintf(stmt, "call payment(%d, %d, %d, %d, %d, '%s', %f)", data->w_id,
			data->d_id, data->c_id, data->c_w_id, data->c_d_id, c_last,
			data->h_amount);

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE("execute_payment stmt: %s\n", stmt);
#endif

	if (mysql_query(dbc->library.mysql.mysql, stmt)) {
		LOG_ERROR_MESSAGE(
				"mysql reports SQL STMT: %s ERROR: %d %s", stmt,
				mysql_errno(dbc->library.mysql.mysql),
				mysql_error(dbc->library.mysql.mysql));
		return ERROR;
	}

	/*
	 * The stored procedure returns the output data as a 28 column
	 * result set.
	 */
	do {
		result = mysql_store_result(dbc->library.mysql.mysql);
		if (result == NULL) {
			continue;
		}
		row = mysql_fetch_row(result);
		if (row == NULL || mysql_num_fields(result) != 28) {
			mysql_free_result(result);
			continue;
		}
		if (row[0]) {
			snprintf(data->w_name, sizeof(data->w_name), "%s", row[0]);
		}
		if (row[1]) {
			snprintf(data->w_street_1, sizeof(data->w_street_1), "%s", row[1]);
		}
		if (row[2]) {
			snprintf(data->w_street_2, sizeof(data->w_street_2), "%s", row[2]);
		}
		if (row[3]) {
			snprintf(data->w_city, sizeof(data->w_city), "%s", row[3]);
		}
		if (row[4]) {
			snprintf(data->w_state, sizeof(data->w_state), "%s", row[4]);
		}
		if (row[5]) {
			snprintf(data->w_zip, sizeof(data->w_zip), "%s", row[5]);
		}
		if (row[6]) {
			snprintf(data->d_name, sizeof(data->d_name), "%s", row[6]);
		}
		if (row[7]) {
			snprintf(data->d_street_1, sizeof(data->d_street_1), "%s", row[7]);
		}
		if (row[8]) {
			snprintf(data->d_street_2, sizeof(data->d_street_2), "%s", row[8]);
		}
		if (row[9]) {
			snprintf(data->d_city, sizeof(data->d_city), "%s", row[9]);
		}
		if (row[10]) {
			snprintf(data->d_state, sizeof(data->d_state), "%s", row[10]);
		}
		if (row[11]) {
			snprintf(data->d_zip, sizeof(data->d_zip), "%s", row[11]);
		}
		if (row[12]) {
			data->c_id = atoi(row[12]);
		}
		if (row[13]) {
			snprintf(data->c_first, sizeof(data->c_first), "%s", row[13]);
		}
		if (row[14]) {
			snprintf(data->c_middle, sizeof(data->c_middle), "%s", row[14]);
		}
		if (row[15]) {
			mbstowcs(data->c_last, row[15], C_LAST_LEN + 1);
		}
		if (row[16]) {
			snprintf(data->c_street_1, sizeof(data->c_street_1), "%s", row[16]);
		}
		if (row[17]) {
			snprintf(data->c_street_2, sizeof(data->c_street_2), "%s", row[17]);
		}
		if (row[18]) {
			snprintf(data->c_city, sizeof(data->c_city), "%s", row[18]);
		}
		if (row[19]) {
			snprintf(data->c_state, sizeof(data->c_state), "%s", row[19]);
		}
		if (row[20]) {
			snprintf(data->c_zip, sizeof(data->c_zip), "%s", row[20]);
		}
		if (row[21]) {
			snprintf(data->c_phone, sizeof(data->c_phone), "%s", row[21]);
		}
		if (row[22]) {
			snprintf(data->c_since, sizeof(data->c_since), "%s", row[22]);
		}
		if (row[23]) {
			snprintf(data->c_credit, sizeof(data->c_credit), "%s", row[23]);
		}
		if (row[24]) {
			data->c_credit_lim = atof(row[24]);
		}
		if (row[25]) {
			data->c_discount = atof(row[25]);
		}
		if (row[26]) {
			data->c_balance = atof(row[26]);
		}
		if (row[27]) {
			snprintf(data->c_data, sizeof(data->c_data), "%s", row[27]);
		}
		mysql_free_result(result);
	} while (mysql_next_result(dbc->library.mysql.mysql) == 0);

	return OK;
}
