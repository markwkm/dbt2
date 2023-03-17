/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 */

#include "odbc_integrity.h"

#ifdef ORACLEODBC
struct integrityctx {
	int w_nware;

	SQLHSTMT curi1;
};

typedef struct integrityctx integrityctx;

int init_integrity_txn (struct db_context_t *odbcc)
 {
	SQLRETURN rc;
	int i = 1;

	odbcc->ictx = (integrityctx*) malloc(sizeof(integrityctx));

	if (odbcc->ictx == NULL)
		return ERROR;

	/* allocate statement handle */
	rc = SQLAllocHandle(SQL_HANDLE_STMT, odbcc->hdbc, &odbcc->ictx->curi1);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->ictx->curi1);
		return ERROR;
	}

	/* Perpare statement for the Stock-Level transaction. */
	rc = SQLPrepare(odbcc->ictx->curi1, (SQLCHAR *)STMT_INTEGRITY, SQL_NTS);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->ictx->curi1);
		return ERROR;
	}

	/* Bind variables for the Stock-Levely transaction. */
	rc = SQLBindParameter(odbcc->ictx->curi1,
		i++, SQL_PARAM_OUTPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->ictx->w_nware, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->ictx->curi1);
		return ERROR;
	}

	return OK;
}
#endif /* ORACLEODBC */

int execute_integrity(struct db_context_t *dbc, struct integrity_t *data) {
#ifdef ORACLEODBC
	SQLRETURN rc;

	/* Input variables. */
	int w_id = data->w_id;

	/* Execute Integrity query */
	rc = SQLExecute(odbcc->ictx->curi1);
	if (check_odbc_rc(SQL_HANDLE_STMT, odbcc->ictx->curi1, rc) == ERROR) {   
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->ictx->curi1);
		return ERROR;
	}

	if (odbcc->ictx->w_nware != w_id) {
		LOG_ERROR_MESSAGE("ERROR: Expect W_ID = %d Got W_ID = %d", w_id, odbcc->ictx->w_nware);
		return -1;
	}
#endif /* ORACLEODBC */

	return OK;
}
