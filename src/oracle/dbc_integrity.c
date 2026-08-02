/*
		This file is released under the terms of the Artistic License.  Please
   see the file LICENSE, included in this package, for details. Copyright (C)
   2006 Anurag Vora & Oracle Corporation. All rights reserved.
*/

#include <oracle_integrity.h>

#include "logging.h"

#define STMT_INTEGRITY "SELECT count(*) FROM warehouse"

struct integrityctx {
	int w_nware;

	OCIStmt *curi1;

	OCIDefine *w_nware_dp;
};

typedef struct integrityctx integrityctx;

int init_integrity_txn_oracle(struct db_context_t *dbc) {
	dbc->library.oracle.ictx = (integrityctx *) malloc(sizeof(integrityctx));

	if (dbc->library.oracle.ictx == NULL)
		return ERROR;

	/* STMT_INTEGRITY */
	OCIERROR(
			dbc->library.oracle.errhp,
			OCIHandleAlloc(
					dbc->library.oracle.oracleenv,
					(dvoid **) (&dbc->library.oracle.ictx->curi1),
					OCI_HTYPE_STMT, 0, (dvoid **) 0));
	OCIERROR(
			dbc->library.oracle.errhp,
			OCIStmtPrepare(
					dbc->library.oracle.ictx->curi1, dbc->library.oracle.errhp,
					(text *) STMT_INTEGRITY, strlen((char *) STMT_INTEGRITY),
					(ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT));

	/* bind variables */
	/* none */

	/* define variables */
	OCIDEFINE(
			dbc->library.oracle.ictx->curi1,
			dbc->library.oracle.ictx->w_nware_dp, dbc->library.oracle.errhp, 1,
			ADR(dbc->library.oracle.ictx->w_nware), SIZ(int), SQLT_INT);

	return OK;
}

int execute_integrity_oracle(
		struct db_context_t *dbc, struct integrity_t *data) {
	int rc = OK;

	/* Input variables. */
	int w_id = data->w_id;

	int retries = 0;
	int execstatus = 0;
	int errcode = 0;

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE("STMT_INTEGRITY query: %s\n", STMT_INTEGRITY);
#endif

retry:
	execstatus = OCIStmtExecute(
			dbc->library.oracle.oraclesvc, dbc->library.oracle.ictx->curi1,
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
		/* No rows in ware !*/
		LOG_ERROR_MESSAGE("ERROR: W_ID is NULL for query w_id: %d\n", w_id);
		return ERROR;
	}

	//  dbc->library.oracle.ictx->w_nware in the result
	if (dbc->library.oracle.ictx->w_nware != w_id) {
		LOG_ERROR_MESSAGE(
				"ERROR: Expect W_ID = %d Got W_ID = %d", w_id,
				dbc->library.oracle.ictx->w_nware);
		return ERROR;
	}

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE(
			"STMT_INTEGRITY result: %d\n", dbc->library.oracle.ictx->w_nware);
#endif
	return rc;
}
