/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 *
 * Based on TPC-C Standard Specification Revision 5.0.
 */

#include "odbc_stock_level.h"

#ifdef ORACLEODBC
struct stockctx {
	int w_id;
	int d_id;
	int threshold;
	int low_stock;

	SQLHSTMT curs1;
};

typedef struct stockctx stockctx;

int init_stock_level_txn (struct db_context_t *odbcc)
{
	SQLRETURN rc;
	int i = 1;

	odbcc->sctx = (stockctx*) malloc(sizeof(stockctx));

	if (odbcc->sctx == NULL)
		return ERROR;

	/* allocate statement handle */
	rc = SQLAllocHandle(SQL_HANDLE_STMT, odbcc->hdbc, &odbcc->sctx->curs1);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->sctx->curs1);
		return ERROR;
	}

	/* Perpare statement for the Stock-Level transaction. */
	rc = SQLPrepare(odbcc->sctx->curs1, (SQLCHAR *)STMT_STOCK_LEVEL, SQL_NTS);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->sctx->curs1);
		return ERROR;
	}

	/* Bind variables for the Stock-Levely transaction. */
	rc = SQLBindParameter(odbcc->sctx->curs1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->sctx->w_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->sctx->curs1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->sctx->curs1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->sctx->d_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->sctx->curs1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->sctx->curs1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->sctx->threshold, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->sctx->curs1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->sctx->curs1,
		i++, SQL_PARAM_OUTPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->sctx->low_stock, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->sctx->curs1);
		return ERROR;
	}

	return OK;
}
#endif /* ORACLEODBC */

int execute_stock_level(
		struct db_context_t *odbcc, struct stock_level_t *data) {
	SQLRETURN rc;

#ifdef ORACLEODBC
	/* Input variables. */
	odbcc->sctx->w_id = data->w_id;
	odbcc->sctx->d_id = data->d_id;
	odbcc->sctx->threshold = data->threshold;
#else
	int i = 1;

	/* Perpare statement for the Stock-Level transaction. */
	rc = SQLPrepare(
			odbcc->library.odbc.hstmt, (unsigned char *) STMT_STOCK_LEVEL,
			SQL_NTS);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}

	/* Bind variables for the Stock-Levely transaction. */
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
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->threshold, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->low_stock, 0, NULL);
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
