/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 *
 * Based on TPC-C Standard Specification Revision 5.0.
 */

#include <odbc_payment.h>

#ifdef ORACLEODBC
struct paymentctx {
	int w_id;
	int d_id;
	int c_id;
	int c_w_id;
	int c_d_id;
	
	char c_last[C_LAST_LEN+1];

	float h_amount;

	SQLHSTMT curp1;
};

typedef struct paymentctx paymentctx;

int init_payment_txn (struct db_context_t *odbcc)
{
	SQLRETURN rc;
	int i = 1;

	odbcc->pctx = (paymentctx*) malloc(sizeof(paymentctx));

	if (odbcc->pctx == NULL)
		return ERROR;

	/* allocate statement handle */
	rc = SQLAllocHandle(SQL_HANDLE_STMT, odbcc->hdbc, &odbcc->pctx->curp1);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->pctx->curp1);
		return ERROR;
	}

	/* Perpare statement for Payment transaction. */
	rc = SQLPrepare(odbcc->pctx->curp1, (SQLCHAR *)STMT_PAYMENT, SQL_NTS);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->pctx->curp1);
		return ERROR;
	}

	/* Bind variables for Payment transaction. */
	rc = SQLBindParameter(odbcc->pctx->curp1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->pctx->w_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->pctx->curp1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->pctx->curp1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->pctx->d_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->pctx->curp1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->pctx->curp1,
		i++, SQL_PARAM_INPUT_OUTPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->pctx->c_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->pctx->curp1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->pctx->curp1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->pctx->c_w_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->pctx->curp1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->pctx->curp1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->pctx->c_d_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->pctx->curp1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->pctx->curp1,
		i++, SQL_PARAM_INPUT_OUTPUT, SQL_C_CHAR, SQL_VARCHAR, 0, 0,
		odbcc->pctx->c_last, sizeof(odbcc->pctx->c_last), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->pctx->curp1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->pctx->curp1,
		i++, SQL_PARAM_INPUT, SQL_C_DOUBLE, SQL_DOUBLE, 0, 0,
		&odbcc->pctx->h_amount, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->pctx->curp1);
		return ERROR;
	}

	return OK;
}
#endif /* ORACLEODBC */

int execute_payment(struct db_context_t *odbcc, struct payment_t *data) {
	SQLRETURN rc;

#ifdef ORACLEODBC
	/* Input variables. */
	odbcc->pctx->w_id = data->w_id;
	odbcc->pctx->d_id = data->d_id;
	odbcc->pctx->c_id = data->c_id;
	odbcc->pctx->c_w_id = data->c_w_id;
	odbcc->pctx->c_d_id = data->c_d_id;
	strncpy (odbcc->pctx->c_last, data->c_last, C_LAST_LEN+1);
	odbcc->pctx->h_amount = data->h_amount;
#else
	int i = 1;

	/* Perpare statement for Payment transaction. */
	rc = SQLPrepare(
			odbcc->library.odbc.hstmt, (unsigned char *) STMT_PAYMENT, SQL_NTS);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}

	/* Bind variables for Payment transaction. */
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->w_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->d_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT_OUTPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->c_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->c_w_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->c_d_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->c_last, sizeof(data->c_last), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_DOUBLE,
			SQL_DOUBLE, 0, 0, &data->h_amount, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->w_name, sizeof(data->w_name), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->w_street_1, sizeof(data->w_street_1),
			NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->w_street_2, sizeof(data->w_street_2),
			NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->w_city, sizeof(data->w_city), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_CHAR, 0, 0, data->w_state, sizeof(data->w_state), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_CHAR, 0, 0, data->w_zip, sizeof(data->w_zip), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->d_name, sizeof(data->d_name), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->d_street_1, sizeof(data->d_street_1),
			NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->d_street_2, sizeof(data->d_street_2),
			NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->d_city, sizeof(data->d_city), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_CHAR, 0, 0, data->d_state, sizeof(data->d_state), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_CHAR, 0, 0, data->d_zip, sizeof(data->d_zip), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->c_first, sizeof(data->c_first), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_CHAR, 0, 0, data->c_middle, sizeof(data->c_middle), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->c_street_1, sizeof(data->c_street_1),
			NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->c_street_2, sizeof(data->c_street_2),
			NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->c_city, sizeof(data->c_city), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_CHAR, 0, 0, data->c_state, sizeof(data->c_state), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_CHAR, 0, 0, data->c_zip, sizeof(data->c_zip), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_CHAR, 0, 0, data->c_phone, sizeof(data->c_phone), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->c_since, sizeof(data->c_since), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_CHAR, 0, 0, data->c_credit, sizeof(data->c_credit), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_DOUBLE,
			SQL_DOUBLE, 0, 0, &data->c_credit_lim, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_DOUBLE,
			SQL_DOUBLE, 0, 0, &data->c_discount, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_DOUBLE,
			SQL_DOUBLE, 0, 0, &data->c_balance, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_CHAR, 0, 0, data->c_data, sizeof(data->c_data), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
#endif /* ORACLEODBC */

	/* Execute stored procedure. */
	rc = SQLExecute(odbcc->library.odbc.hstmt);
	if (check_odbc_rc(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt, rc) ==
		ERROR) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}

	return OK;
}
