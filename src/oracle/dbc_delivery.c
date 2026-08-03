/*
		This file is released under the terms of the Artistic License.  Please
   see the file LICENSE, included in this package, for details. Copyright (C)
   2006 Anurag Vora & Oracle Corporation. All rights reserved.
*/

#include <string.h>

#include <oracle_delivery.h>

#include "logging.h"

#define STMT_DELIVERY "CALL delivery (:w_id, :o_carrier_id)"

struct deliveryctx {
	int w_id;
	int o_carrier_id;

	OCIStmt *curd1;

	OCIBind *w_id_bp;
	OCIBind *o_carrier_id_bp;
};

typedef struct deliveryctx deliveryctx;

int init_delivery_txn_oracle(struct db_context_t *dbc) {

	dbc->library.oracle.dctx = (deliveryctx *) malloc(sizeof(deliveryctx));

	if (dbc->library.oracle.dctx == NULL)
		return ERROR;

	/* DELIVERY_1 */
	OCIERROR(
			dbc->library.oracle.errhp,
			OCIHandleAlloc(
					dbc->library.oracle.oracleenv,
					(dvoid **) (&dbc->library.oracle.dctx->curd1),
					OCI_HTYPE_STMT, 0, (dvoid **) 0));
	OCIERROR(
			dbc->library.oracle.errhp,
			OCIStmtPrepare(
					dbc->library.oracle.dctx->curd1, dbc->library.oracle.errhp,
					(text *) STMT_DELIVERY, strlen((char *) STMT_DELIVERY),
					(ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT));

	/* bind variables */
	OCIBND(dbc->library.oracle.dctx->curd1, dbc->library.oracle.dctx->w_id_bp,
		   dbc->library.oracle.errhp, ":w_id",
		   ADR(dbc->library.oracle.dctx->w_id), SIZ(int), SQLT_INT);
	OCIBND(dbc->library.oracle.dctx->curd1,
		   dbc->library.oracle.dctx->o_carrier_id_bp, dbc->library.oracle.errhp,
		   ":o_carrier_id", ADR(dbc->library.oracle.dctx->o_carrier_id),
		   SIZ(int), SQLT_INT);

	return OK;
}

int execute_delivery_oracle(struct db_context_t *dbc, struct delivery_t *data) {
	int rc = OK;

	/* Input variables. */
	dbc->library.oracle.dctx->w_id = data->w_id;
	dbc->library.oracle.dctx->o_carrier_id = data->o_carrier_id;

	int retries = 0;
	int execstatus = 0;
	int errcode = 0;

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE(
			"STMT_DELIVERY CALL DELIVERY(%d, %d);\n",
			dbc->library.oracle.dctx->w_id, data->o_carrier_id);
#endif

retry:
	execstatus = OCIStmtExecute(
			dbc->library.oracle.oraclesvc, dbc->library.oracle.dctx->curd1,
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
