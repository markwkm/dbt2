/*
		This file is released under the terms of the Artistic License.  Please
   see the file LICENSE, included in this package, for details. Copyright (C)
   2006 Anurag Vora & Oracle Corporation. All rights reserved.
*/

#include <oracle_new_order.h>

#include "logging.h"

#define STMT_NEW_ORDER                                                         \
	"CALL neworder (:w_id, :d_id, :c_id, :o_all_local, :o_ol_cnt, "            \
	":ol_i_id1, :ol_supply_w_id1, :ol_quantity1, "                             \
	":ol_i_id2, :ol_supply_w_id2, :ol_quantity2, "                             \
	":ol_i_id3, :ol_supply_w_id3, :ol_quantity3, "                             \
	":ol_i_id4, :ol_supply_w_id4, :ol_quantity4, "                             \
	":ol_i_id5, :ol_supply_w_id5, :ol_quantity5, "                             \
	":ol_i_id6, :ol_supply_w_id6, :ol_quantity6, "                             \
	":ol_i_id7, :ol_supply_w_id7, :ol_quantity7, "                             \
	":ol_i_id8, :ol_supply_w_id8, :ol_quantity8, "                             \
	":ol_i_id9, :ol_supply_w_id9, :ol_quantity9, "                             \
	":ol_i_id10, :ol_supply_w_id10, :ol_quantity10, "                          \
	":ol_i_id11, :ol_supply_w_id11, :ol_quantity11, "                          \
	":ol_i_id12, :ol_supply_w_id12, :ol_quantity12, "                          \
	":ol_i_id13, :ol_supply_w_id13, :ol_quantity13, "                          \
	":ol_i_id14, :ol_supply_w_id14, :ol_quantity14, "                          \
	":ol_i_id15, :ol_supply_w_id15, :ol_quantity15)"

struct nordctx {
	int w_id;
	float w_tax;

	int d_id;
	int c_id;
	int o_all_local;
	int o_ol_cnt;

	int ol_i_id[O_OL_CNT_MAX];
	int ol_supply_w_id[O_OL_CNT_MAX];
	int ol_quantity[O_OL_CNT_MAX];

	OCIStmt *curn1;

	OCIBind *w_id_bp;
	OCIBind *d_id_bp;
	OCIBind *c_id_bp;
	OCIBind *o_all_local_bp;
	OCIBind *o_ol_cnt_bp;
	OCIBind *ol_i_id_bp[O_OL_CNT_MAX];
	OCIBind *ol_supply_w_id_bp[O_OL_CNT_MAX];
	OCIBind *ol_quantity_bp[O_OL_CNT_MAX];
};

typedef struct nordctx nordctx;

int init_nord_txn_oracle(struct db_context_t *dbc) {
	int i = 0;
	char ol_i_id[11];
	char ol_supply_w_id[18];
	char ol_quantity[15];
	dbc->library.oracle.nctx = (nordctx *) malloc(sizeof(nordctx));

	if (dbc->library.oracle.nctx == NULL)
		return ERROR;

	/* STMT_NEW_ORDER */
	OCIERROR(
			dbc->library.oracle.errhp,
			OCIHandleAlloc(
					dbc->library.oracle.oracleenv,
					(dvoid **) (&dbc->library.oracle.nctx->curn1),
					OCI_HTYPE_STMT, 0, (dvoid **) 0));
	OCIERROR(
			dbc->library.oracle.errhp,
			OCIStmtPrepare(
					dbc->library.oracle.nctx->curn1, dbc->library.oracle.errhp,
					(text *) STMT_NEW_ORDER, strlen((char *) STMT_NEW_ORDER),
					(ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT));

	/* bind variables */
	OCIBND(dbc->library.oracle.nctx->curn1, dbc->library.oracle.nctx->w_id_bp,
		   dbc->library.oracle.errhp, ":w_id",
		   ADR(dbc->library.oracle.nctx->w_id), SIZ(int), SQLT_INT);
	OCIBND(dbc->library.oracle.nctx->curn1, dbc->library.oracle.nctx->d_id_bp,
		   dbc->library.oracle.errhp, ":d_id",
		   ADR(dbc->library.oracle.nctx->d_id), SIZ(int), SQLT_INT);
	OCIBND(dbc->library.oracle.nctx->curn1, dbc->library.oracle.nctx->c_id_bp,
		   dbc->library.oracle.errhp, ":c_id",
		   ADR(dbc->library.oracle.nctx->c_id), SIZ(int), SQLT_INT);
	OCIBND(dbc->library.oracle.nctx->curn1,
		   dbc->library.oracle.nctx->o_all_local_bp, dbc->library.oracle.errhp,
		   ":o_all_local", ADR(dbc->library.oracle.nctx->o_all_local), SIZ(int),
		   SQLT_INT);
	OCIBND(dbc->library.oracle.nctx->curn1,
		   dbc->library.oracle.nctx->o_ol_cnt_bp, dbc->library.oracle.errhp,
		   ":o_ol_cnt", ADR(dbc->library.oracle.nctx->o_ol_cnt), SIZ(int),
		   SQLT_INT);
	for (i = 0; i < O_OL_CNT_MAX; i++) {
		sprintf(ol_i_id, ":ol_i_id%d", i + 1);
		sprintf(ol_supply_w_id, ":ol_supply_w_id%d", i + 1);
		sprintf(ol_quantity, ":ol_quantity%d", i + 1);

		OCIBND(dbc->library.oracle.nctx->curn1,
			   dbc->library.oracle.nctx->ol_i_id_bp[i],
			   dbc->library.oracle.errhp, ol_i_id,
			   ADR(dbc->library.oracle.nctx->ol_i_id[i]), SIZ(int), SQLT_INT);
		OCIBND(dbc->library.oracle.nctx->curn1,
			   dbc->library.oracle.nctx->ol_supply_w_id_bp[i],
			   dbc->library.oracle.errhp, ol_supply_w_id,
			   ADR(dbc->library.oracle.nctx->ol_supply_w_id[i]), SIZ(int),
			   SQLT_INT);
		OCIBND(dbc->library.oracle.nctx->curn1,
			   dbc->library.oracle.nctx->ol_quantity_bp[i],
			   dbc->library.oracle.errhp, ol_quantity,
			   ADR(dbc->library.oracle.nctx->ol_quantity[i]), SIZ(int),
			   SQLT_INT);
	}

	return OK;
}

int execute_new_order_oracle(
		struct db_context_t *dbc, struct new_order_t *data) {
	int j = 0;
	int rc = OK;

	/* Input variables. */
	dbc->library.oracle.nctx->w_id = data->w_id;
	dbc->library.oracle.nctx->d_id = data->d_id;
	dbc->library.oracle.nctx->c_id = data->c_id;
	dbc->library.oracle.nctx->o_all_local = data->o_all_local;
	dbc->library.oracle.nctx->o_ol_cnt = data->o_ol_cnt;

	/* Loop through the last set of parameters. */
	for (j = 0; j < O_OL_CNT_MAX; j++) {
		dbc->library.oracle.nctx->ol_i_id[j] = data->order_line[j].ol_i_id;
		dbc->library.oracle.nctx->ol_supply_w_id[j] =
				data->order_line[j].ol_supply_w_id;
		dbc->library.oracle.nctx->ol_quantity[j] =
				data->order_line[j].ol_quantity;
	}

	int retries = 0;
	int execstatus = 0;
	int errcode = 0;

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE(
			"STMT_NEW_ORDER input call neworder(%d, %d, %d, %d, %d, \
					 	%d, %d, %d, \
					 	%d, %d, %d, \
					 	%d, %d, %d, \
					 	%d, %d, %d, \
					 	%d, %d, %d, \
					 	%d, %d, %d, \
					 	%d, %d, %d, \
					 	%d, %d, %d, \
					 	%d, %d, %d, \
					 	%d, %d, %d, \
					 	%d, %d, %d, \
					 	%d, %d, %d, \
					 	%d, %d, %d, \
					 	%d, %d, %d, \
					 	%d, %d, %d);",
			dbc->library.oracle.nctx->w_id, dbc->library.oracle.nctx->d_id,
			dbc->library.oracle.nctx->c_id,
			dbc->library.oracle.nctx->o_all_local,
			dbc->library.oracle.nctx->o_ol_cnt,
			dbc->library.oracle.nctx->ol_i_id[0],
			dbc->library.oracle.nctx->ol_supply_w_id[0],
			dbc->library.oracle.nctx->ol_quantity[0],
			dbc->library.oracle.nctx->ol_i_id[1],
			dbc->library.oracle.nctx->ol_supply_w_id[1],
			dbc->library.oracle.nctx->ol_quantity[1],
			dbc->library.oracle.nctx->ol_i_id[2],
			dbc->library.oracle.nctx->ol_supply_w_id[2],
			dbc->library.oracle.nctx->ol_quantity[2],
			dbc->library.oracle.nctx->ol_i_id[3],
			dbc->library.oracle.nctx->ol_supply_w_id[3],
			dbc->library.oracle.nctx->ol_quantity[3],
			dbc->library.oracle.nctx->ol_i_id[4],
			dbc->library.oracle.nctx->ol_supply_w_id[4],
			dbc->library.oracle.nctx->ol_quantity[4],
			dbc->library.oracle.nctx->ol_i_id[5],
			dbc->library.oracle.nctx->ol_supply_w_id[5],
			dbc->library.oracle.nctx->ol_quantity[5],
			dbc->library.oracle.nctx->ol_i_id[6],
			dbc->library.oracle.nctx->ol_supply_w_id[6],
			dbc->library.oracle.nctx->ol_quantity[6],
			dbc->library.oracle.nctx->ol_i_id[7],
			dbc->library.oracle.nctx->ol_supply_w_id[7],
			dbc->library.oracle.nctx->ol_quantity[7],
			dbc->library.oracle.nctx->ol_i_id[8],
			dbc->library.oracle.nctx->ol_supply_w_id[8],
			dbc->library.oracle.nctx->ol_quantity[8],
			dbc->library.oracle.nctx->ol_i_id[9],
			dbc->library.oracle.nctx->ol_supply_w_id[9],
			dbc->library.oracle.nctx->ol_quantity[9],
			dbc->library.oracle.nctx->ol_i_id[10],
			dbc->library.oracle.nctx->ol_supply_w_id[10],
			dbc->library.oracle.nctx->ol_quantity[10],
			dbc->library.oracle.nctx->ol_i_id[11],
			dbc->library.oracle.nctx->ol_supply_w_id[11],
			dbc->library.oracle.nctx->ol_quantity[11],
			dbc->library.oracle.nctx->ol_i_id[12],
			dbc->library.oracle.nctx->ol_supply_w_id[12],
			dbc->library.oracle.nctx->ol_quantity[12],
			dbc->library.oracle.nctx->ol_i_id[13],
			dbc->library.oracle.nctx->ol_supply_w_id[13],
			dbc->library.oracle.nctx->ol_quantity[13],
			dbc->library.oracle.nctx->ol_i_id[14],
			dbc->library.oracle.nctx->ol_supply_w_id[14],
			dbc->library.oracle.nctx->ol_quantity[14]);
#endif
retry:
	execstatus = OCIStmtExecute(
			dbc->library.oracle.oraclesvc, dbc->library.oracle.nctx->curn1,
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
