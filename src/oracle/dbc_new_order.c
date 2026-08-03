/*
		This file is released under the terms of the Artistic License.  Please
   see the file LICENSE, included in this package, for details. Copyright (C)
   2006 Anurag Vora & Oracle Corporation. All rights reserved.
*/

#include <stdio.h>
#include <string.h>

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
	":ol_i_id15, :ol_supply_w_id15, :ol_quantity15, "                          \
	":out_w_tax, :out_d_tax, :out_o_id, :out_c_last, :out_c_credit, "          \
	":out_c_discount, :out_total_amount, "                                     \
	":out_i_price1, :out_i_price2, :out_i_price3, :out_i_price4, "             \
	":out_i_price5, :out_i_price6, :out_i_price7, :out_i_price8, "             \
	":out_i_price9, :out_i_price10, :out_i_price11, :out_i_price12, "          \
	":out_i_price13, :out_i_price14, :out_i_price15, "                         \
	":out_i_name1, :out_i_name2, :out_i_name3, :out_i_name4, "                 \
	":out_i_name5, :out_i_name6, :out_i_name7, :out_i_name8, "                 \
	":out_i_name9, :out_i_name10, :out_i_name11, :out_i_name12, "              \
	":out_i_name13, :out_i_name14, :out_i_name15, "                            \
	":out_s_quantity1, :out_s_quantity2, :out_s_quantity3, "                   \
	":out_s_quantity4, :out_s_quantity5, :out_s_quantity6, "                   \
	":out_s_quantity7, :out_s_quantity8, :out_s_quantity9, "                   \
	":out_s_quantity10, :out_s_quantity11, :out_s_quantity12, "                \
	":out_s_quantity13, :out_s_quantity14, :out_s_quantity15, "                \
	":out_ol_amount1, :out_ol_amount2, :out_ol_amount3, "                      \
	":out_ol_amount4, :out_ol_amount5, :out_ol_amount6, "                      \
	":out_ol_amount7, :out_ol_amount8, :out_ol_amount9, "                      \
	":out_ol_amount10, :out_ol_amount11, :out_ol_amount12, "                   \
	":out_ol_amount13, :out_ol_amount14, :out_ol_amount15, "                   \
	":out_brand_generic1, :out_brand_generic2, :out_brand_generic3, "          \
	":out_brand_generic4, :out_brand_generic5, :out_brand_generic6, "          \
	":out_brand_generic7, :out_brand_generic8, :out_brand_generic9, "          \
	":out_brand_generic10, :out_brand_generic11, :out_brand_generic12, "       \
	":out_brand_generic13, :out_brand_generic14, :out_brand_generic15)"

struct nordctx {
	int w_id;

	int d_id;
	int c_id;
	int o_all_local;
	int o_ol_cnt;

	int ol_i_id[O_OL_CNT_MAX];
	int ol_supply_w_id[O_OL_CNT_MAX];
	int ol_quantity[O_OL_CNT_MAX];

	double w_tax;
	double d_tax;
	int o_id;
	char c_last[4 * (C_LAST_LEN + 1)];
	char c_credit[C_CREDIT_LEN + 1];
	double c_discount;
	double total_amount;
	double i_price[O_OL_CNT_MAX];
	char i_name[O_OL_CNT_MAX][4 * (I_NAME_LEN + 1)];
	int s_quantity[O_OL_CNT_MAX];
	double ol_amount[O_OL_CNT_MAX];
	char brand_generic[O_OL_CNT_MAX][2];

	sb2 w_tax_ind;
	sb2 d_tax_ind;
	sb2 o_id_ind;
	sb2 c_last_ind;
	sb2 c_credit_ind;
	sb2 c_discount_ind;
	sb2 total_amount_ind;
	sb2 i_price_ind[O_OL_CNT_MAX];
	sb2 i_name_ind[O_OL_CNT_MAX];
	sb2 s_quantity_ind[O_OL_CNT_MAX];
	sb2 ol_amount_ind[O_OL_CNT_MAX];
	sb2 brand_generic_ind[O_OL_CNT_MAX];

	OCIStmt *curn1;

	OCIBind *w_id_bp;
	OCIBind *d_id_bp;
	OCIBind *c_id_bp;
	OCIBind *o_all_local_bp;
	OCIBind *o_ol_cnt_bp;
	OCIBind *ol_i_id_bp[O_OL_CNT_MAX];
	OCIBind *ol_supply_w_id_bp[O_OL_CNT_MAX];
	OCIBind *ol_quantity_bp[O_OL_CNT_MAX];

	OCIBind *w_tax_bp;
	OCIBind *d_tax_bp;
	OCIBind *o_id_bp;
	OCIBind *c_last_bp;
	OCIBind *c_credit_bp;
	OCIBind *c_discount_bp;
	OCIBind *total_amount_bp;
	OCIBind *i_price_bp[O_OL_CNT_MAX];
	OCIBind *i_name_bp[O_OL_CNT_MAX];
	OCIBind *s_quantity_bp[O_OL_CNT_MAX];
	OCIBind *ol_amount_bp[O_OL_CNT_MAX];
	OCIBind *brand_generic_bp[O_OL_CNT_MAX];
};

typedef struct nordctx nordctx;

int init_nord_txn_oracle(struct db_context_t *dbc) {
	int i = 0;
	char ol_i_id[11];
	char ol_supply_w_id[18];
	char ol_quantity[15];
	char i_price[16];
	char i_name[15];
	char s_quantity[19];
	char ol_amount[18];
	char brand_generic[22];
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

	/* Output variables. */
	OCIBNDRA(
			dbc->library.oracle.nctx->curn1, dbc->library.oracle.nctx->w_tax_bp,
			dbc->library.oracle.errhp, ":out_w_tax",
			ADR(dbc->library.oracle.nctx->w_tax), SIZ(double), SQLT_FLT,
			&dbc->library.oracle.nctx->w_tax_ind, 0, 0);
	OCIBNDRA(
			dbc->library.oracle.nctx->curn1, dbc->library.oracle.nctx->d_tax_bp,
			dbc->library.oracle.errhp, ":out_d_tax",
			ADR(dbc->library.oracle.nctx->d_tax), SIZ(double), SQLT_FLT,
			&dbc->library.oracle.nctx->d_tax_ind, 0, 0);
	OCIBNDRA(
			dbc->library.oracle.nctx->curn1, dbc->library.oracle.nctx->o_id_bp,
			dbc->library.oracle.errhp, ":out_o_id",
			ADR(dbc->library.oracle.nctx->o_id), SIZ(int), SQLT_INT,
			&dbc->library.oracle.nctx->o_id_ind, 0, 0);
	OCIBNDRA(
			dbc->library.oracle.nctx->curn1,
			dbc->library.oracle.nctx->c_last_bp, dbc->library.oracle.errhp,
			":out_c_last", ADR(dbc->library.oracle.nctx->c_last),
			SIZ(dbc->library.oracle.nctx->c_last), SQLT_STR,
			&dbc->library.oracle.nctx->c_last_ind, 0, 0);
	OCIBNDRA(
			dbc->library.oracle.nctx->curn1,
			dbc->library.oracle.nctx->c_credit_bp, dbc->library.oracle.errhp,
			":out_c_credit", ADR(dbc->library.oracle.nctx->c_credit),
			SIZ(dbc->library.oracle.nctx->c_credit), SQLT_STR,
			&dbc->library.oracle.nctx->c_credit_ind, 0, 0);
	OCIBNDRA(
			dbc->library.oracle.nctx->curn1,
			dbc->library.oracle.nctx->c_discount_bp, dbc->library.oracle.errhp,
			":out_c_discount", ADR(dbc->library.oracle.nctx->c_discount),
			SIZ(double), SQLT_FLT, &dbc->library.oracle.nctx->c_discount_ind, 0,
			0);
	OCIBNDRA(
			dbc->library.oracle.nctx->curn1,
			dbc->library.oracle.nctx->total_amount_bp,
			dbc->library.oracle.errhp, ":out_total_amount",
			ADR(dbc->library.oracle.nctx->total_amount), SIZ(double), SQLT_FLT,
			&dbc->library.oracle.nctx->total_amount_ind, 0, 0);

	for (i = 0; i < O_OL_CNT_MAX; i++) {
		sprintf(i_price, ":out_i_price%d", i + 1);
		sprintf(i_name, ":out_i_name%d", i + 1);
		sprintf(s_quantity, ":out_s_quantity%d", i + 1);
		sprintf(ol_amount, ":out_ol_amount%d", i + 1);
		sprintf(brand_generic, ":out_brand_generic%d", i + 1);

		OCIBNDRA(
				dbc->library.oracle.nctx->curn1,
				dbc->library.oracle.nctx->i_price_bp[i],
				dbc->library.oracle.errhp, i_price,
				ADR(dbc->library.oracle.nctx->i_price[i]), SIZ(double),
				SQLT_FLT, &dbc->library.oracle.nctx->i_price_ind[i], 0, 0);
		OCIBNDRA(
				dbc->library.oracle.nctx->curn1,
				dbc->library.oracle.nctx->i_name_bp[i],
				dbc->library.oracle.errhp, i_name,
				ADR(dbc->library.oracle.nctx->i_name[i]),
				SIZ(dbc->library.oracle.nctx->i_name[i]), SQLT_STR,
				&dbc->library.oracle.nctx->i_name_ind[i], 0, 0);
		OCIBNDRA(
				dbc->library.oracle.nctx->curn1,
				dbc->library.oracle.nctx->s_quantity_bp[i],
				dbc->library.oracle.errhp, s_quantity,
				ADR(dbc->library.oracle.nctx->s_quantity[i]), SIZ(int),
				SQLT_INT, &dbc->library.oracle.nctx->s_quantity_ind[i], 0, 0);
		OCIBNDRA(
				dbc->library.oracle.nctx->curn1,
				dbc->library.oracle.nctx->ol_amount_bp[i],
				dbc->library.oracle.errhp, ol_amount,
				ADR(dbc->library.oracle.nctx->ol_amount[i]), SIZ(double),
				SQLT_FLT, &dbc->library.oracle.nctx->ol_amount_ind[i], 0, 0);
		OCIBNDRA(
				dbc->library.oracle.nctx->curn1,
				dbc->library.oracle.nctx->brand_generic_bp[i],
				dbc->library.oracle.errhp, brand_generic,
				ADR(dbc->library.oracle.nctx->brand_generic[i]),
				SIZ(dbc->library.oracle.nctx->brand_generic[i]), SQLT_STR,
				&dbc->library.oracle.nctx->brand_generic_ind[i], 0, 0);
	}

	return OK;
}

int execute_new_order_oracle(
		struct db_context_t *dbc, struct new_order_t *data) {
	struct nordctx *nctx = dbc->library.oracle.nctx;
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
		} else if (errcode == ITEM_NOT_VALID) {
			/* The expected New-Order rollback case. */
			data->rollback = 1;
			return ERROR;
		} else {
			return ERROR;
		}
	}
	if (execstatus == OCI_NO_DATA) {
		return ERROR;
	}

	/* Output variables. */
	if (nctx->w_tax_ind == 0) {
		data->w_tax = nctx->w_tax;
	}
	if (nctx->d_tax_ind == 0) {
		data->d_tax = nctx->d_tax;
	}
	if (nctx->o_id_ind == 0) {
		data->o_id = nctx->o_id;
	}
	if (nctx->c_last_ind == 0) {
		snprintf(data->c_last, sizeof(data->c_last), "%s", nctx->c_last);
	}
	if (nctx->c_credit_ind == 0) {
		snprintf(data->c_credit, sizeof(data->c_credit), "%s", nctx->c_credit);
	}
	if (nctx->c_discount_ind == 0) {
		data->c_discount = nctx->c_discount;
	}
	if (nctx->total_amount_ind == 0) {
		data->total_amount = nctx->total_amount;
	}
	for (j = 0; j < O_OL_CNT_MAX; j++) {
		if (nctx->i_price_ind[j] == 0) {
			data->order_line[j].i_price = nctx->i_price[j];
		}
		if (nctx->i_name_ind[j] == 0) {
			snprintf(
					data->order_line[j].i_name,
					sizeof(data->order_line[j].i_name), "%s", nctx->i_name[j]);
		}
		if (nctx->s_quantity_ind[j] == 0) {
			data->order_line[j].s_quantity = nctx->s_quantity[j];
		}
		if (nctx->ol_amount_ind[j] == 0) {
			data->order_line[j].ol_amount = nctx->ol_amount[j];
		}
		if (nctx->brand_generic_ind[j] == 0) {
			data->order_line[j].brand_generic = nctx->brand_generic[j][0];
		}
	}

	return rc;
}
