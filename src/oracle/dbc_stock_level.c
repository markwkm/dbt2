/*
		This file is released under the terms of the Artistic License.  Please
   see the file LICENSE, included in this package, for details. Copyright (C)
   2006 Anurag Vora & Oracle Corporation. All rights reserved.
*/

#include "oracle_stock_level.h"

#include "logging.h"

#define STMT_STOCK_LEVEL                                                       \
	"CALL stock_level (:w_id, :d_id, :threshold, :low_stock)"

struct stockctx {
	int w_id;
	int d_id;
	int threshold;
	int low_stock;

	OCIStmt *curs1;

	OCIBind *w_id_bp;
	OCIBind *d_id_bp;
	OCIBind *threshold_bp;
	OCIBind *low_stock_bp;
};

typedef struct stockctx stockctx;

int init_stock_level_txn_oracle(struct db_context_t *dbc) {
	dbc->library.oracle.sctx = (stockctx *) malloc(sizeof(stockctx));

	if (dbc->library.oracle.sctx == NULL)
		return ERROR;

	/* STOCK_LEVEL_1 */
	OCIERROR(
			dbc->library.oracle.errhp,
			OCIHandleAlloc(
					dbc->library.oracle.oracleenv,
					(dvoid **) (&dbc->library.oracle.sctx->curs1),
					OCI_HTYPE_STMT, 0, (dvoid **) 0));
	OCIERROR(
			dbc->library.oracle.errhp,
			OCIStmtPrepare(
					dbc->library.oracle.sctx->curs1, dbc->library.oracle.errhp,
					(text *) STMT_STOCK_LEVEL,
					strlen((char *) STMT_STOCK_LEVEL), (ub4) OCI_NTV_SYNTAX,
					(ub4) OCI_DEFAULT));

	/* bind variables */
	OCIBND(dbc->library.oracle.sctx->curs1, dbc->library.oracle.sctx->w_id_bp,
		   dbc->library.oracle.errhp, ":w_id",
		   ADR(dbc->library.oracle.sctx->w_id), SIZ(int), SQLT_INT);
	OCIBND(dbc->library.oracle.sctx->curs1, dbc->library.oracle.sctx->d_id_bp,
		   dbc->library.oracle.errhp, ":d_id",
		   ADR(dbc->library.oracle.sctx->d_id), SIZ(int), SQLT_INT);
	OCIBND(dbc->library.oracle.sctx->curs1,
		   dbc->library.oracle.sctx->threshold_bp, dbc->library.oracle.errhp,
		   ":threshold", ADR(dbc->library.oracle.sctx->threshold), SIZ(int),
		   SQLT_INT);
	OCIBND(dbc->library.oracle.sctx->curs1,
		   dbc->library.oracle.sctx->low_stock_bp, dbc->library.oracle.errhp,
		   ":low_stock", ADR(dbc->library.oracle.sctx->low_stock), SIZ(int),
		   SQLT_INT);

	return OK;
}

int execute_stock_level_oracle(
		struct db_context_t *dbc, struct stock_level_t *data) {
	int rc = OK;

	/* Input variables. */
	dbc->library.oracle.sctx->w_id = data->w_id;
	dbc->library.oracle.sctx->d_id = data->d_id;
	dbc->library.oracle.sctx->threshold = data->threshold;

	int retries = 0;
	int execstatus = 0;
	int errcode = 0;

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE(
			"STMT_STOCK_LEVEL call stock_level(%d, %d, %d, %d);\n",
			dbc->library.oracle.sctx->w_id, dbc->library.oracle.sctx->d_id,
			dbc->library.oracle.sctx->threshold,
			dbc->library.oracle.sctx->low_stock);
#endif

retry:
	execstatus = OCIStmtExecute(
			dbc->library.oracle.oraclesvc, dbc->library.oracle.sctx->curs1,
			dbc->library.oracle.errhp, 1, 0, 0, 0,
			OCI_COMMIT_ON_SUCCESS | OCI_DEFAULT);

	if ((execstatus != OCI_NO_DATA) && (execstatus != OCI_SUCCESS)) {
		errcode = OCIERROR(dbc->library.oracle.errhp, execstatus);
		if ((errcode == NOT_SERIALIZABLE) || (errcode == RECOVERR) ||
			(errcode == SNAPSHOT_TOO_OLD) || (errcode == NOT_SAFE_REPLAY) ||
			(errcode == COLUMN_VALUE_NULL)) {
			OCITransCommit(
					dbc->library.oracle.oraclesvc, dbc->library.oracle.errhp,
					OCI_DEFAULT);
			retries++;
			goto retry;
		} else {
			return ERROR;
		}
	}
	if (execstatus == OCI_NO_DATA) {
		return ERROR;
	}
#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE(
			"STMT_STOCK_LEVEL result: %d\n",
			dbc->library.oracle.sctx->low_stock);
#endif

	return rc;
}
