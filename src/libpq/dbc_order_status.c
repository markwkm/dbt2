/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 */

#include <stdio.h>
#include <string.h>
#include <time.h>
#include <wchar.h>

#include "common.h"
#include "libpq_order_status.h"
#include "logging.h"

#define UDF_ORDER_STATUS "SELECT * FROM order_status($1, $2, $3, $4)"

int execute_order_status_libpq(
		struct db_context_t *dbc, struct order_status_t *data) {
	PGresult *res;
	const char *paramValues[4];
	int paramLengths[4] = {
			sizeof(uint32_t), sizeof(uint32_t), sizeof(uint32_t), 0};
	const int paramFormats[4] = {1, 1, 1, 1};
	char c_last[4 * (C_LAST_LEN + 1)];

	uint32_t c_id;
	uint32_t c_w_id;
	uint32_t c_d_id;

	int i;

	c_id = htonl((uint32_t) data->c_id);
	c_w_id = htonl((uint32_t) data->c_w_id);
	c_d_id = htonl((uint32_t) data->c_d_id);
	wcstombs(c_last, data->c_last, 4 * (C_LAST_LEN + 1));

#ifdef DEBUG
	LOG_ERROR_MESSAGE(
			"OS c_id %d c_w_id %d c_d_id %d c_last %s", data->c_id,
			data->c_w_id, data->c_d_id, c_last);
#endif /* DEBUG */

	paramValues[0] = (char *) &c_id;
	paramValues[1] = (char *) &c_w_id;
	paramValues[2] = (char *) &c_d_id;
	paramValues[3] = c_last;

	paramLengths[3] = strlen(c_last);

	/* Start a transaction block. */
	res = PQexec(dbc->library.libpq.conn, "BEGIN");
	if (!res || PQresultStatus(res) != PGRES_COMMAND_OK) {
		LOG_ERROR_MESSAGE("%s", PQerrorMessage(dbc->library.libpq.conn));
		if (PQresultStatus(res) == PGRES_FATAL_ERROR &&
			strcmp("no connection to the server\n",
				   PQerrorMessage(dbc->library.libpq.conn)) == 0) {
			PQclear(res);
			return RECONNECT;
		}
		PQclear(res);
		return ERROR;
	}
	PQclear(res);

	res = PQexecParams(
			dbc->library.libpq.conn, UDF_ORDER_STATUS, 4, NULL, paramValues,
			paramLengths, paramFormats, 1);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK) {
		LOG_ERROR_MESSAGE("OS %s", PQerrorMessage(dbc->library.libpq.conn));
		if (PQresultStatus(res) == PGRES_FATAL_ERROR &&
			strcmp("no connection to the server\n",
				   PQerrorMessage(dbc->library.libpq.conn)) == 0) {
			PQclear(res);
			return RECONNECT;
		}
		PQclear(res);
		return ERROR;
	}
	data->o_ol_cnt = PQntuples(res);
	if (data->o_ol_cnt > O_OL_CNT_MAX) {
		data->o_ol_cnt = O_OL_CNT_MAX;
	}
	for (i = 0; i < data->o_ol_cnt; i++) {
		data->order_line[i].ol_i_id = libpq_get_int32(res, i, 0);
		data->order_line[i].ol_supply_w_id = libpq_get_int32(res, i, 1);
		data->order_line[i].ol_quantity =
				(int) libpq_get_float4(res, i, 2);
		data->order_line[i].ol_amount = libpq_get_float4(res, i, 3);
		libpq_copy_text(
				data->order_line[i].ol_delivery_d,
				sizeof(data->order_line[i].ol_delivery_d), res, i, 4);
	}
	if (PQntuples(res) > 0) {
		data->c_id = libpq_get_int32(res, 0, 5);
		libpq_copy_text(data->c_first, sizeof(data->c_first), res, 0, 6);
		libpq_copy_text(data->c_middle, sizeof(data->c_middle), res, 0, 7);
		if (!PQgetisnull(res, 0, 8)) {
			mbstowcs(data->c_last, PQgetvalue(res, 0, 8), C_LAST_LEN + 1);
		}
		data->c_balance = libpq_get_float8(res, 0, 9);
		data->o_id = libpq_get_int32(res, 0, 10);
		data->o_carrier_id = libpq_get_int32(res, 0, 11);
		libpq_copy_text(
				data->o_entry_d, sizeof(data->o_entry_d), res, 0, 12);
	}
#ifdef DEBUG
	for (i = 0; i < PQntuples(res); i++) {
		int j;

		for (j = 0; j < PQnfields(res); j++) {
			switch (j) {
			case 0:
			case 1:
			case 5:
			case 10:
			case 11:
				LOG_ERROR_MESSAGE(
						"OS[%d] %s = %d", i, PQfname(res, j),
						libpq_get_int32(res, i, j));
				break;
			case 2:
			case 3:
				LOG_ERROR_MESSAGE(
						"OS[%d] %s = %f", i, PQfname(res, j),
						libpq_get_float4(res, i, j));
				break;
			case 9:
				LOG_ERROR_MESSAGE(
						"OS[%d] %s = %f", i, PQfname(res, j),
						libpq_get_float8(res, i, j));
				break;
			default:
				LOG_ERROR_MESSAGE(
						"OS[%d] %s = %s", i, PQfname(res, j),
						PQgetvalue(res, i, j));
				break;
			}
		}
	}
#endif /* DEBUG */
	PQclear(res);

	return OK;
}
