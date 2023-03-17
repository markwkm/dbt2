/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 *
 * Based on TPC-C Standard Specification Revision 5.0.
 */

#include <odbc_order_status.h>

#ifdef ORACLEODBC
struct ordstatusctx {
	int c_id;
	int c_w_id;
	int c_d_id;
	char c_last[C_LAST_LEN+1];

	SQLHSTMT curo1;
};

typedef struct ordstatusctx ordstatusctx;

int init_order_status_txn (struct db_context_t *odbcc)
{
	SQLRETURN rc;
	int i = 1;

	odbcc->octx = (ordstatusctx*) malloc(sizeof(ordstatusctx));

	if (odbcc->octx == NULL)
		return ERROR;

	/* allocate statement handle */
	rc = SQLAllocHandle(SQL_HANDLE_STMT, odbcc->hdbc, &odbcc->octx->curo1);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->octx->curo1);
		return ERROR;
	}

	/* Perpare statement for New Order transaction. */
	rc = SQLPrepare(odbcc->octx->curo1, (SQLCHAR *)STMT_ORDER_STATUS, SQL_NTS);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->octx->curo1);
		return ERROR;
	}

	/* Bind variables for New Order transaction. */
	rc = SQLBindParameter(odbcc->octx->curo1,
		i++, SQL_PARAM_INPUT_OUTPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->octx->c_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->octx->curo1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->octx->curo1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->octx->c_w_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->octx->curo1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->octx->curo1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->octx->c_d_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->octx->curo1);
		return ERROR;
	}

	return OK;
}
#endif /* ORACLEODBC */

int execute_order_status(
		struct db_context_t *odbcc, struct order_status_t *data) {
	SQLRETURN rc;

#ifdef ORACLEODBC
	/* Input variables. */
	odbcc->octx->c_id = data->c_id;
	odbcc->octx->c_w_id = data->c_w_id;
	odbcc->octx->c_d_id = data->c_d_id;
	strncpy (odbcc->octx->c_last, data->c_last, C_LAST_LEN+1);
#else
	int i = 1;
	int j;

	/* Perpare statement for New Order transaction. */
	rc = SQLPrepare(
			odbcc->library.odbc.hstmt, (unsigned char *) STMT_ORDER_STATUS,
			SQL_NTS);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}

	/* Bind variables for New Order transaction. */
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
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->c_last, sizeof(data->c_last), NULL);
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
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->o_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->o_carrier_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->o_entry_d, sizeof(data->o_entry_d), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->o_ol_cnt, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	for (j = 0; j < O_OL_CNT_MAX; j++) {
		rc = SQLBindParameter(
				odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_SLONG,
				SQL_INTEGER, 0, 0, &data->order_line[j].ol_supply_w_id, 0,
				NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
			return ERROR;
		}
		rc = SQLBindParameter(
				odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_SLONG,
				SQL_INTEGER, 0, 0, &data->order_line[j].ol_i_id, 0, NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
			return ERROR;
		}
		rc = SQLBindParameter(
				odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_SLONG,
				SQL_INTEGER, 0, 0, &data->order_line[j].ol_quantity, 0, NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
			return ERROR;
		}
		rc = SQLBindParameter(
				odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_DOUBLE,
				SQL_DOUBLE, 0, 0, &data->order_line[j].ol_amount, 0, NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
			return ERROR;
		}
		rc = SQLBindParameter(
				odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
				SQL_VARCHAR, 0, 0, data->order_line[j].ol_delivery_d,
				sizeof(data->order_line[j].ol_delivery_d), NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
			return ERROR;
		}
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
