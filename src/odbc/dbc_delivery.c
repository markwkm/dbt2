/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 *
 * Based on TPC-C Standard Specification Revision 5.0.
 */

#include <odbc_delivery.h>

#ifdef ORACLEODBC
struct deliveryctx {
	int w_id;
	int o_carrier_id;

	SQLHSTMT curd1;
};

typedef struct deliveryctx deliveryctx;

int init_delivery_txn (struct db_context_t *odbcc)
{
	SQLRETURN rc;
	int i = 1;

	odbcc->dctx = (deliveryctx*) malloc(sizeof(deliveryctx));

	if (odbcc->dctx == NULL)
		return ERROR;

	/* allocate statement handle */
	rc = SQLAllocHandle(SQL_HANDLE_STMT, odbcc->hdbc, &odbcc->dctx->curd1);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->dctx->curd1);
		return ERROR;
	}

	/* Perpare statement for the Delivery transaction. */
	rc = SQLPrepare(odbcc->dctx->curd1, (SQLCHAR *)STMT_DELIVERY, SQL_NTS);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->dctx->curd1);
		return ERROR;
	}

	/* Bind variables for the Delivery transaction. */
	rc = SQLBindParameter(odbcc->dctx->curd1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->dctx->w_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->dctx->curd1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->dctx->curd1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->dctx->o_carrier_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->dctx->curd1);
		return ERROR;
	}

	return OK;
}
#endif /* ORACLEODBC */

int execute_delivery(struct db_context_t *odbcc, struct delivery_t *data) {
	SQLRETURN rc;

#ifdef ORACLEODBC
	/* Input variables. */
	odbcc->dctx->w_id = data->w_id;
	odbcc->dctx->o_carrier_id = data->o_carrier_id;
#else
	int i = 1;

	/* Perpare statement for the Delivery transaction. */
	rc = SQLPrepare(
			odbcc->library.odbc.hstmt, (unsigned char *) STMT_DELIVERY,
			SQL_NTS);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}

	/* Bind variables for the Delivery transaction. */
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->w_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->o_carrier_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
#endif

	/* Execute stored procedure. */
	rc = SQLExecute(odbcc->library.odbc.hstmt);
	if (check_odbc_rc(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt, rc) ==
		ERROR) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}

	return OK;
}
