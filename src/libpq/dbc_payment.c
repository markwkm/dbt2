/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 */

#include <stdio.h>
#include <string.h>
#include <wchar.h>

#include "common.h"
#include "libpq_payment.h"
#include "logging.h"

#define UDF_PAYMENT "SELECT * FROM payment($1, $2, $3, $4, $5, $6, $7)"

int execute_payment_libpq(struct db_context_t *dbc, struct payment_t *data) {
	PGresult *res;
	const char *paramValues[7];
	const int paramFormats[7] = {1, 1, 1, 1, 1, 1, 1};
	int paramLengths[7] = {sizeof(uint32_t), sizeof(uint32_t), sizeof(uint32_t),
						   sizeof(uint32_t), sizeof(uint32_t), 0,
						   sizeof(uint32_t)};
	char c_last[4 * (C_LAST_LEN + 1)];

	uint32_t w_id;
	uint32_t d_id;
	uint32_t c_id;
	uint32_t c_w_id;
	uint32_t c_d_id;
	uint32_t lh_amount;

	union {
		float f;
		uint32_t i;
	} h_amount;

#ifdef DEBUG
	int i, j;
#endif /* DEBUG */

	w_id = htonl((uint32_t) data->w_id);
	d_id = htonl((uint32_t) data->d_id);
	c_id = htonl((uint32_t) data->c_id);
	c_w_id = htonl((uint32_t) data->c_w_id);
	c_d_id = htonl((uint32_t) data->c_d_id);
	h_amount.f = data->h_amount;
	lh_amount = htonl((uint32_t) h_amount.i);
	wcstombs(c_last, data->c_last, 4 * (C_LAST_LEN + 1));

#ifdef DEBUG
	LOG_ERROR_MESSAGE(
			"P w_id %d d_id %d c_id %d c_w_id %d c_d_id %d "
			"c_last %s h_amount %f",
			data->w_id, data->d_id, data->c_id, data->c_w_id, data->c_d_id,
			c_last, data->h_amount);
#endif /* DEBUG */

	paramValues[0] = (char *) &w_id;
	paramValues[1] = (char *) &d_id;
	paramValues[2] = (char *) &c_id;
	paramValues[3] = (char *) &c_w_id;
	paramValues[4] = (char *) &c_d_id;
	paramValues[5] = c_last;
	paramValues[6] = (char *) &lh_amount;

	paramLengths[5] = strlen(c_last);

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
			dbc->library.libpq.conn, UDF_PAYMENT, 7, NULL, paramValues,
			paramLengths, paramFormats, 1);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK) {
		LOG_ERROR_MESSAGE("P %s", PQerrorMessage(dbc->library.libpq.conn));
		if (PQresultStatus(res) == PGRES_FATAL_ERROR &&
			strcmp("no connection to the server\n",
				   PQerrorMessage(dbc->library.libpq.conn)) == 0) {
			PQclear(res);
			return RECONNECT;
		}
		PQclear(res);
		return ERROR;
	}
	if (PQntuples(res) > 0) {
		libpq_copy_text(
				data->w_street_1, sizeof(data->w_street_1), res, 0, 0);
		libpq_copy_text(
				data->w_street_2, sizeof(data->w_street_2), res, 0, 1);
		libpq_copy_text(data->w_city, sizeof(data->w_city), res, 0, 2);
		libpq_copy_text(data->w_state, sizeof(data->w_state), res, 0, 3);
		libpq_copy_text(data->w_zip, sizeof(data->w_zip), res, 0, 4);
		libpq_copy_text(
				data->d_street_1, sizeof(data->d_street_1), res, 0, 5);
		libpq_copy_text(
				data->d_street_2, sizeof(data->d_street_2), res, 0, 6);
		libpq_copy_text(data->d_city, sizeof(data->d_city), res, 0, 7);
		libpq_copy_text(data->d_state, sizeof(data->d_state), res, 0, 8);
		libpq_copy_text(data->d_zip, sizeof(data->d_zip), res, 0, 9);
		libpq_copy_text(data->c_first, sizeof(data->c_first), res, 0, 10);
		libpq_copy_text(data->c_middle, sizeof(data->c_middle), res, 0, 11);
		if (!PQgetisnull(res, 0, 12)) {
			mbstowcs(data->c_last, PQgetvalue(res, 0, 12), C_LAST_LEN + 1);
		}
		libpq_copy_text(
				data->c_street_1, sizeof(data->c_street_1), res, 0, 13);
		libpq_copy_text(
				data->c_street_2, sizeof(data->c_street_2), res, 0, 14);
		libpq_copy_text(data->c_city, sizeof(data->c_city), res, 0, 15);
		libpq_copy_text(data->c_state, sizeof(data->c_state), res, 0, 16);
		libpq_copy_text(data->c_zip, sizeof(data->c_zip), res, 0, 17);
		libpq_copy_text(data->c_phone, sizeof(data->c_phone), res, 0, 18);
		libpq_copy_text(data->c_since, sizeof(data->c_since), res, 0, 19);
		libpq_copy_text(data->c_credit, sizeof(data->c_credit), res, 0, 20);
		data->c_credit_lim = libpq_get_float8(res, 0, 21);
		data->c_discount = libpq_get_float4(res, 0, 22);
		data->c_balance = libpq_get_float8(res, 0, 23);
		libpq_copy_text(data->c_data, sizeof(data->c_data), res, 0, 24);
		libpq_copy_text(data->h_date, sizeof(data->h_date), res, 0, 25);
		data->c_id = libpq_get_int32(res, 0, 26);
		libpq_copy_text(data->w_name, sizeof(data->w_name), res, 0, 27);
		libpq_copy_text(data->d_name, sizeof(data->d_name), res, 0, 28);
	}
#ifdef DEBUG
	for (i = 0; i < PQntuples(res); i++) {
		for (j = 0; j < PQnfields(res); j++) {
			switch (j) {
			case 21:
			case 23:
				LOG_ERROR_MESSAGE(
						"P[%d] %s = %f", i, PQfname(res, j),
						libpq_get_float8(res, i, j));
				break;
			case 22:
				LOG_ERROR_MESSAGE(
						"P[%d] %s = %f", i, PQfname(res, j),
						libpq_get_float4(res, i, j));
				break;
			case 26:
				LOG_ERROR_MESSAGE(
						"P[%d] %s = %d", i, PQfname(res, j),
						libpq_get_int32(res, i, j));
				break;
			default:
				LOG_ERROR_MESSAGE(
						"P[%d] %s = %s", i, PQfname(res, j),
						PQgetvalue(res, i, j));
				break;
			}
		}
	}
#endif /* DEBUG */
	PQclear(res);

	return OK;
}
