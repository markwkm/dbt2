/*
		This file is released under the terms of the Artistic License.  Please
   see the file LICENSE, included in this package, for details. Copyright (C)
   2006 Anurag Vora & Oracle Corporation. All rights reserved.
*/

#include <stdio.h>
#include <string.h>

#include <oracle_order_status.h>

#include "logging.h"

#define STMT_ORDER_STATUS                                                      \
	"CALL order_status (:c_id, :c_w_id, :c_d_id, :c_last, "                    \
	":out_c_id, :out_c_first, :out_c_middle, :out_c_last, "                    \
	":out_c_balance, :out_o_id, :out_o_carrier_id, :out_o_entry_d, "           \
	":out_ol_i_id1, :out_ol_i_id2, :out_ol_i_id3, :out_ol_i_id4, "             \
	":out_ol_i_id5, :out_ol_i_id6, :out_ol_i_id7, :out_ol_i_id8, "             \
	":out_ol_i_id9, :out_ol_i_id10, :out_ol_i_id11, :out_ol_i_id12, "          \
	":out_ol_i_id13, :out_ol_i_id14, :out_ol_i_id15, "                         \
	":out_ol_supply_w_id1, :out_ol_supply_w_id2, :out_ol_supply_w_id3, "       \
	":out_ol_supply_w_id4, :out_ol_supply_w_id5, :out_ol_supply_w_id6, "       \
	":out_ol_supply_w_id7, :out_ol_supply_w_id8, :out_ol_supply_w_id9, "       \
	":out_ol_supply_w_id10, :out_ol_supply_w_id11, "                           \
	":out_ol_supply_w_id12, :out_ol_supply_w_id13, "                           \
	":out_ol_supply_w_id14, :out_ol_supply_w_id15, "                           \
	":out_ol_quantity1, :out_ol_quantity2, :out_ol_quantity3, "                \
	":out_ol_quantity4, :out_ol_quantity5, :out_ol_quantity6, "                \
	":out_ol_quantity7, :out_ol_quantity8, :out_ol_quantity9, "                \
	":out_ol_quantity10, :out_ol_quantity11, :out_ol_quantity12, "             \
	":out_ol_quantity13, :out_ol_quantity14, :out_ol_quantity15, "             \
	":out_ol_amount1, :out_ol_amount2, :out_ol_amount3, "                      \
	":out_ol_amount4, :out_ol_amount5, :out_ol_amount6, "                      \
	":out_ol_amount7, :out_ol_amount8, :out_ol_amount9, "                      \
	":out_ol_amount10, :out_ol_amount11, :out_ol_amount12, "                   \
	":out_ol_amount13, :out_ol_amount14, :out_ol_amount15, "                   \
	":out_ol_delivery_d1, :out_ol_delivery_d2, :out_ol_delivery_d3, "          \
	":out_ol_delivery_d4, :out_ol_delivery_d5, :out_ol_delivery_d6, "          \
	":out_ol_delivery_d7, :out_ol_delivery_d8, :out_ol_delivery_d9, "          \
	":out_ol_delivery_d10, :out_ol_delivery_d11, :out_ol_delivery_d12, "       \
	":out_ol_delivery_d13, :out_ol_delivery_d14, :out_ol_delivery_d15)"

struct ordstatusctx {
	int c_id;
	int c_w_id;
	int c_d_id;
	char c_last[4 * (C_LAST_LEN + 1)];

	int out_c_id;
	char out_c_first[4 * (C_FIRST_LEN + 1)];
	char out_c_middle[C_MIDDLE_LEN + 1];
	char out_c_last[4 * (C_LAST_LEN + 1)];
	double out_c_balance;
	int out_o_id;
	int out_o_carrier_id;
	char out_o_entry_d[O_ENTRY_D_LEN + 1];
	int out_ol_i_id[O_OL_CNT_MAX];
	int out_ol_supply_w_id[O_OL_CNT_MAX];
	int out_ol_quantity[O_OL_CNT_MAX];
	double out_ol_amount[O_OL_CNT_MAX];
	char out_ol_delivery_d[O_OL_CNT_MAX][OL_DELIVERY_D_LEN + 1];

	sb2 out_c_id_ind;
	sb2 out_c_first_ind;
	sb2 out_c_middle_ind;
	sb2 out_c_last_ind;
	sb2 out_c_balance_ind;
	sb2 out_o_id_ind;
	sb2 out_o_carrier_id_ind;
	sb2 out_o_entry_d_ind;
	sb2 out_ol_i_id_ind[O_OL_CNT_MAX];
	sb2 out_ol_supply_w_id_ind[O_OL_CNT_MAX];
	sb2 out_ol_quantity_ind[O_OL_CNT_MAX];
	sb2 out_ol_amount_ind[O_OL_CNT_MAX];
	sb2 out_ol_delivery_d_ind[O_OL_CNT_MAX];

	OCIStmt *curo1;

	OCIBind *c_id_bp;
	OCIBind *c_w_id_bp;
	OCIBind *c_d_id_bp;
	OCIBind *c_last_bp;

	OCIBind *out_c_id_bp;
	OCIBind *out_c_first_bp;
	OCIBind *out_c_middle_bp;
	OCIBind *out_c_last_bp;
	OCIBind *out_c_balance_bp;
	OCIBind *out_o_id_bp;
	OCIBind *out_o_carrier_id_bp;
	OCIBind *out_o_entry_d_bp;
	OCIBind *out_ol_i_id_bp[O_OL_CNT_MAX];
	OCIBind *out_ol_supply_w_id_bp[O_OL_CNT_MAX];
	OCIBind *out_ol_quantity_bp[O_OL_CNT_MAX];
	OCIBind *out_ol_amount_bp[O_OL_CNT_MAX];
	OCIBind *out_ol_delivery_d_bp[O_OL_CNT_MAX];
};

typedef struct ordstatusctx ordstatusctx;

int init_order_status_txn_oracle(struct db_context_t *dbc) {
	ordstatusctx *octx;
	int i = 0;
	char out_ol_i_id[19];
	char out_ol_supply_w_id[26];
	char out_ol_quantity[22];
	char out_ol_amount[20];
	char out_ol_delivery_d[24];

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

	/* Output variables. */
	octx = dbc->library.oracle.octx;
	OCIBNDRA(
			octx->curo1, octx->out_c_id_bp, dbc->library.oracle.errhp,
			":out_c_id", ADR(octx->out_c_id), SIZ(int), SQLT_INT,
			&octx->out_c_id_ind, 0, 0);
	OCIBNDRA(
			octx->curo1, octx->out_c_first_bp, dbc->library.oracle.errhp,
			":out_c_first", ADR(octx->out_c_first), SIZ(octx->out_c_first),
			SQLT_STR, &octx->out_c_first_ind, 0, 0);
	OCIBNDRA(
			octx->curo1, octx->out_c_middle_bp, dbc->library.oracle.errhp,
			":out_c_middle", ADR(octx->out_c_middle), SIZ(octx->out_c_middle),
			SQLT_STR, &octx->out_c_middle_ind, 0, 0);
	OCIBNDRA(
			octx->curo1, octx->out_c_last_bp, dbc->library.oracle.errhp,
			":out_c_last", ADR(octx->out_c_last), SIZ(octx->out_c_last),
			SQLT_STR, &octx->out_c_last_ind, 0, 0);
	OCIBNDRA(
			octx->curo1, octx->out_c_balance_bp, dbc->library.oracle.errhp,
			":out_c_balance", ADR(octx->out_c_balance), SIZ(double), SQLT_FLT,
			&octx->out_c_balance_ind, 0, 0);
	OCIBNDRA(
			octx->curo1, octx->out_o_id_bp, dbc->library.oracle.errhp,
			":out_o_id", ADR(octx->out_o_id), SIZ(int), SQLT_INT,
			&octx->out_o_id_ind, 0, 0);
	OCIBNDRA(
			octx->curo1, octx->out_o_carrier_id_bp, dbc->library.oracle.errhp,
			":out_o_carrier_id", ADR(octx->out_o_carrier_id), SIZ(int),
			SQLT_INT, &octx->out_o_carrier_id_ind, 0, 0);
	OCIBNDRA(
			octx->curo1, octx->out_o_entry_d_bp, dbc->library.oracle.errhp,
			":out_o_entry_d", ADR(octx->out_o_entry_d),
			SIZ(octx->out_o_entry_d), SQLT_STR, &octx->out_o_entry_d_ind, 0, 0);

	for (i = 0; i < O_OL_CNT_MAX; i++) {
		sprintf(out_ol_i_id, ":out_ol_i_id%d", i + 1);
		sprintf(out_ol_supply_w_id, ":out_ol_supply_w_id%d", i + 1);
		sprintf(out_ol_quantity, ":out_ol_quantity%d", i + 1);
		sprintf(out_ol_amount, ":out_ol_amount%d", i + 1);
		sprintf(out_ol_delivery_d, ":out_ol_delivery_d%d", i + 1);

		OCIBNDRA(
				octx->curo1, octx->out_ol_i_id_bp[i], dbc->library.oracle.errhp,
				out_ol_i_id, ADR(octx->out_ol_i_id[i]), SIZ(int), SQLT_INT,
				&octx->out_ol_i_id_ind[i], 0, 0);
		OCIBNDRA(
				octx->curo1, octx->out_ol_supply_w_id_bp[i],
				dbc->library.oracle.errhp, out_ol_supply_w_id,
				ADR(octx->out_ol_supply_w_id[i]), SIZ(int), SQLT_INT,
				&octx->out_ol_supply_w_id_ind[i], 0, 0);
		OCIBNDRA(
				octx->curo1, octx->out_ol_quantity_bp[i],
				dbc->library.oracle.errhp, out_ol_quantity,
				ADR(octx->out_ol_quantity[i]), SIZ(int), SQLT_INT,
				&octx->out_ol_quantity_ind[i], 0, 0);
		OCIBNDRA(
				octx->curo1, octx->out_ol_amount_bp[i],
				dbc->library.oracle.errhp, out_ol_amount,
				ADR(octx->out_ol_amount[i]), SIZ(double), SQLT_FLT,
				&octx->out_ol_amount_ind[i], 0, 0);
		OCIBNDRA(
				octx->curo1, octx->out_ol_delivery_d_bp[i],
				dbc->library.oracle.errhp, out_ol_delivery_d,
				ADR(octx->out_ol_delivery_d[i]),
				SIZ(octx->out_ol_delivery_d[i]), SQLT_STR,
				&octx->out_ol_delivery_d_ind[i], 0, 0);
	}

	return OK;
}

int execute_order_status_oracle(
		struct db_context_t *dbc, struct order_status_t *data) {
	struct ordstatusctx *octx = dbc->library.oracle.octx;
	int i = 0;
	int rc = OK;

	/* Input variables. */
	dbc->library.oracle.octx->c_id = data->c_id;
	dbc->library.oracle.octx->c_w_id = data->c_w_id;
	dbc->library.oracle.octx->c_d_id = data->c_d_id;
	wcstombs(
			dbc->library.oracle.octx->c_last, data->c_last,
			4 * (C_LAST_LEN + 1));

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

	/* Output variables. */
	if (octx->out_c_id_ind == 0) {
		data->c_id = octx->out_c_id;
	}
	if (octx->out_c_first_ind == 0) {
		snprintf(data->c_first, sizeof(data->c_first), "%s", octx->out_c_first);
	}
	if (octx->out_c_middle_ind == 0) {
		snprintf(
				data->c_middle, sizeof(data->c_middle), "%s",
				octx->out_c_middle);
	}
	if (octx->out_c_last_ind == 0) {
		mbstowcs(data->c_last, octx->out_c_last, C_LAST_LEN + 1);
	}
	if (octx->out_c_balance_ind == 0) {
		data->c_balance = octx->out_c_balance;
	}
	if (octx->out_o_id_ind == 0) {
		data->o_id = octx->out_o_id;
	}
	if (octx->out_o_carrier_id_ind == 0) {
		data->o_carrier_id = octx->out_o_carrier_id;
	}
	if (octx->out_o_entry_d_ind == 0) {
		snprintf(
				data->o_entry_d, sizeof(data->o_entry_d), "%s",
				octx->out_o_entry_d);
	}
	data->o_ol_cnt = 0;
	for (i = 0; i < O_OL_CNT_MAX; i++) {
		if (octx->out_ol_i_id_ind[i] != 0) {
			break;
		}
		data->order_line[i].ol_i_id = octx->out_ol_i_id[i];
		if (octx->out_ol_supply_w_id_ind[i] == 0) {
			data->order_line[i].ol_supply_w_id = octx->out_ol_supply_w_id[i];
		}
		if (octx->out_ol_quantity_ind[i] == 0) {
			data->order_line[i].ol_quantity = octx->out_ol_quantity[i];
		}
		if (octx->out_ol_amount_ind[i] == 0) {
			data->order_line[i].ol_amount = octx->out_ol_amount[i];
		}
		if (octx->out_ol_delivery_d_ind[i] == 0) {
			snprintf(
					data->order_line[i].ol_delivery_d,
					sizeof(data->order_line[i].ol_delivery_d), "%s",
					octx->out_ol_delivery_d[i]);
		}
		data->o_ol_cnt = i + 1;
	}

	return rc;
}
