/*
		This file is released under the terms of the Artistic License.  Please
   see the file LICENSE, included in this package, for details. Copyright (C)
   2006 Anurag Vora & Oracle Corporation. All rights reserved.
*/

#include <oracle_order_status.h>

#include "logging.h"

#define STMT_ORDER_STATUS "CALL order_status (:c_id, :c_w_id, :c_d_id, :c_last)"

struct ordstatusctx {
	int c_id;
	int c_w_id;
	int c_d_id;
	char c_last[C_LAST_LEN + 1];

	OCIStmt *curo1;

	OCIBind *c_id_bp;
	OCIBind *c_w_id_bp;
	OCIBind *c_d_id_bp;
	OCIBind *c_last_bp;
};

typedef struct ordstatusctx ordstatusctx;

int init_order_status_txn_oracle(struct db_context_t *dbc) {
	dbc->library.oracle.octx = (ordstatusctx *) malloc(sizeof(ordstatusctx));

	if (dbc->library.oracle.octx == NULL)
		return ERROR;

	/* ORDER_STATUS_1 */
	OCIERROR(
			dbc->library.oracle.errhp,
			OCIHandleAlloc(
					dbc->library.oracle.oracleenv,
					(dvoid **) (&dbc->library.oracle.octx->curo1),
					OCI_HTYPE_STMT, 0, (dvoid **) 0));
	OCIERROR(
			dbc->library.oracle.errhp,
			OCIStmtPrepare(
					dbc->library.oracle.octx->curo1, dbc->library.oracle.errhp,
					(text *) STMT_ORDER_STATUS,
					strlen((char *) STMT_ORDER_STATUS), (ub4) OCI_NTV_SYNTAX,
					(ub4) OCI_DEFAULT));

	/* bind variables */
	OCIBND(dbc->library.oracle.octx->curo1, dbc->library.oracle.octx->c_id_bp,
		   dbc->library.oracle.errhp, ":c_id",
		   ADR(dbc->library.oracle.octx->c_id), SIZ(int), SQLT_INT);
	OCIBND(dbc->library.oracle.octx->curo1, dbc->library.oracle.octx->c_w_id_bp,
		   dbc->library.oracle.errhp, ":c_w_id",
		   ADR(dbc->library.oracle.octx->c_w_id), SIZ(int), SQLT_INT);
	OCIBND(dbc->library.oracle.octx->curo1, dbc->library.oracle.octx->c_d_id_bp,
		   dbc->library.oracle.errhp, ":c_d_id",
		   ADR(dbc->library.oracle.octx->c_d_id), SIZ(int), SQLT_INT);
	OCIBND(dbc->library.oracle.octx->curo1, dbc->library.oracle.octx->c_last_bp,
		   dbc->library.oracle.errhp, ":c_last",
		   ADR(dbc->library.oracle.octx->c_last),
		   SIZ(dbc->library.oracle.octx->c_last), SQLT_STR);

	return OK;
}

int execute_order_status_oracle(
		struct db_context_t *dbc, struct order_status_t *data) {
	int rc = OK;

	/* Input variables. */
	dbc->library.oracle.octx->c_id = data->c_id;
	dbc->library.oracle.octx->c_w_id = data->c_w_id;
	dbc->library.oracle.octx->c_d_id = data->c_d_id;
	strncpy(dbc->library.oracle.octx->c_last, data->c_last, C_LAST_LEN + 1);

	int retries = 0;
	int execstatus = 0;
	int errcode = 0;

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE(
			"STMT_ORDER_STATUS call order_status(%d, %d, %d, '%s');\n",
			dbc->library.oracle.octx->c_id, dbc->library.oracle.octx->c_w_id,
			dbc->library.oracle.octx->c_d_id, dbc->library.oracle.octx->c_last);
#endif
retry:
	execstatus = OCIStmtExecute(
			dbc->library.oracle.oraclesvc, dbc->library.oracle.octx->curo1,
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

	return rc;
}
