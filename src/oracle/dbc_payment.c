/*
		This file is released under the terms of the Artistic License.  Please
   see the file LICENSE, included in this package, for details. Copyright (C)
   2006 Anurag Vora & Oracle Corporation. All rights reserved.
*/

#include <stdio.h>
#include <string.h>

#include <oracle_payment.h>

#include "logging.h"

#define STMT_PAYMENT                                                           \
	"CALL payment (:w_id, :d_id, :c_id, :c_w_id, :c_d_id, :c_last, "           \
	":h_amount, "                                                              \
	":out_w_name, :out_w_street_1, :out_w_street_2, :out_w_city, "             \
	":out_w_state, :out_w_zip, "                                               \
	":out_d_name, :out_d_street_1, :out_d_street_2, :out_d_city, "             \
	":out_d_state, :out_d_zip, "                                               \
	":out_c_id, :out_c_first, :out_c_middle, :out_c_last, "                    \
	":out_c_street_1, :out_c_street_2, :out_c_city, :out_c_state, "            \
	":out_c_zip, :out_c_phone, :out_c_since, :out_c_credit, "                  \
	":out_c_credit_lim, :out_c_discount, :out_c_balance, :out_c_data)"

struct paymentctx {
	int w_id;
	int d_id;
	int c_id;
	int c_w_id;
	int c_d_id;

	char c_last[4 * (C_LAST_LEN + 1)];

	float h_amount;

	char out_w_name[4 * (W_NAME_LEN + 1)];
	char out_w_street_1[4 * (W_STREET_1_LEN + 1)];
	char out_w_street_2[4 * (W_STREET_2_LEN + 1)];
	char out_w_city[4 * (W_CITY_LEN + 1)];
	char out_w_state[4 * (W_STATE_LEN + 1)];
	char out_w_zip[4 * (W_ZIP_LEN + 1)];
	char out_d_name[4 * (D_NAME_LEN + 1)];
	char out_d_street_1[4 * (D_STREET_1_LEN + 1)];
	char out_d_street_2[4 * (D_STREET_2_LEN + 1)];
	char out_d_city[4 * (D_CITY_LEN + 1)];
	char out_d_state[4 * (D_STATE_LEN + 1)];
	char out_d_zip[4 * (D_ZIP_LEN + 1)];
	int out_c_id;
	char out_c_first[4 * (C_FIRST_LEN + 1)];
	char out_c_middle[C_MIDDLE_LEN + 1];
	char out_c_last[4 * (C_LAST_LEN + 1)];
	char out_c_street_1[4 * (C_STREET_1_LEN + 1)];
	char out_c_street_2[4 * (C_STREET_2_LEN + 1)];
	char out_c_city[4 * (C_CITY_LEN + 1)];
	char out_c_state[4 * (C_STATE_LEN + 1)];
	char out_c_zip[4 * (C_ZIP_LEN + 1)];
	char out_c_phone[4 * (C_PHONE_LEN + 1)];
	char out_c_since[C_SINCE_LEN + 1];
	char out_c_credit[C_CREDIT_LEN + 1];
	double out_c_credit_lim;
	double out_c_discount;
	double out_c_balance;
	char out_c_data[4 * (C_DATA_LEN + 1)];

	sb2 out_w_name_ind;
	sb2 out_w_street_1_ind;
	sb2 out_w_street_2_ind;
	sb2 out_w_city_ind;
	sb2 out_w_state_ind;
	sb2 out_w_zip_ind;
	sb2 out_d_name_ind;
	sb2 out_d_street_1_ind;
	sb2 out_d_street_2_ind;
	sb2 out_d_city_ind;
	sb2 out_d_state_ind;
	sb2 out_d_zip_ind;
	sb2 out_c_id_ind;
	sb2 out_c_first_ind;
	sb2 out_c_middle_ind;
	sb2 out_c_last_ind;
	sb2 out_c_street_1_ind;
	sb2 out_c_street_2_ind;
	sb2 out_c_city_ind;
	sb2 out_c_state_ind;
	sb2 out_c_zip_ind;
	sb2 out_c_phone_ind;
	sb2 out_c_since_ind;
	sb2 out_c_credit_ind;
	sb2 out_c_credit_lim_ind;
	sb2 out_c_discount_ind;
	sb2 out_c_balance_ind;
	sb2 out_c_data_ind;

	OCIStmt *curp1;

	OCIBind *w_id_bp;
	OCIBind *d_id_bp;
	OCIBind *c_id_bp;
	OCIBind *c_w__id_bp;
	OCIBind *c_d__id_bp;
	OCIBind *c_last_bp;
	OCIBind *h_amount_bp;

	OCIBind *out_w_name_bp;
	OCIBind *out_w_street_1_bp;
	OCIBind *out_w_street_2_bp;
	OCIBind *out_w_city_bp;
	OCIBind *out_w_state_bp;
	OCIBind *out_w_zip_bp;
	OCIBind *out_d_name_bp;
	OCIBind *out_d_street_1_bp;
	OCIBind *out_d_street_2_bp;
	OCIBind *out_d_city_bp;
	OCIBind *out_d_state_bp;
	OCIBind *out_d_zip_bp;
	OCIBind *out_c_id_bp;
	OCIBind *out_c_first_bp;
	OCIBind *out_c_middle_bp;
	OCIBind *out_c_last_bp;
	OCIBind *out_c_street_1_bp;
	OCIBind *out_c_street_2_bp;
	OCIBind *out_c_city_bp;
	OCIBind *out_c_state_bp;
	OCIBind *out_c_zip_bp;
	OCIBind *out_c_phone_bp;
	OCIBind *out_c_since_bp;
	OCIBind *out_c_credit_bp;
	OCIBind *out_c_credit_lim_bp;
	OCIBind *out_c_discount_bp;
	OCIBind *out_c_balance_bp;
	OCIBind *out_c_data_bp;
};

typedef struct paymentctx paymentctx;

int init_payment_txn_oracle(struct db_context_t *dbc) {
	paymentctx *pctx;

	dbc->library.oracle.pctx = (paymentctx *) malloc(sizeof(paymentctx));

	if (dbc->library.oracle.pctx == NULL)
		return ERROR;

	/* PAYMENT_1 */
	OCIERROR(
			dbc->library.oracle.errhp,
			OCIHandleAlloc(
					dbc->library.oracle.oracleenv,
					(dvoid **) (&dbc->library.oracle.pctx->curp1),
					OCI_HTYPE_STMT, 0, (dvoid **) 0));
	OCIERROR(
			dbc->library.oracle.errhp,
			OCIStmtPrepare(
					dbc->library.oracle.pctx->curp1, dbc->library.oracle.errhp,
					(text *) STMT_PAYMENT, strlen((char *) STMT_PAYMENT),
					(ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT));

	/* bind variables */
	OCIBND(dbc->library.oracle.pctx->curp1, dbc->library.oracle.pctx->w_id_bp,
		   dbc->library.oracle.errhp, ":w_id",
		   ADR(dbc->library.oracle.pctx->w_id), SIZ(int), SQLT_INT);
	OCIBND(dbc->library.oracle.pctx->curp1, dbc->library.oracle.pctx->w_id_bp,
		   dbc->library.oracle.errhp, ":d_id",
		   ADR(dbc->library.oracle.pctx->d_id), SIZ(int), SQLT_INT);
	OCIBND(dbc->library.oracle.pctx->curp1, dbc->library.oracle.pctx->w_id_bp,
		   dbc->library.oracle.errhp, ":c_id",
		   ADR(dbc->library.oracle.pctx->c_id), SIZ(int), SQLT_INT);
	OCIBND(dbc->library.oracle.pctx->curp1, dbc->library.oracle.pctx->w_id_bp,
		   dbc->library.oracle.errhp, ":c_w_id",
		   ADR(dbc->library.oracle.pctx->c_w_id), SIZ(int), SQLT_INT);
	OCIBND(dbc->library.oracle.pctx->curp1, dbc->library.oracle.pctx->w_id_bp,
		   dbc->library.oracle.errhp, ":c_d_id",
		   ADR(dbc->library.oracle.pctx->c_d_id), SIZ(int), SQLT_INT);
	OCIBND(dbc->library.oracle.pctx->curp1, dbc->library.oracle.pctx->w_id_bp,
		   dbc->library.oracle.errhp, ":c_last",
		   ADR(dbc->library.oracle.pctx->c_last),
		   SIZ(dbc->library.oracle.pctx->c_last), SQLT_STR);
	OCIBND(dbc->library.oracle.pctx->curp1, dbc->library.oracle.pctx->w_id_bp,
		   dbc->library.oracle.errhp, ":h_amount",
		   ADR(dbc->library.oracle.pctx->h_amount), SIZ(float), SQLT_FLT);

	/* Output variables. */
	pctx = dbc->library.oracle.pctx;
	OCIBNDRA(
			pctx->curp1, pctx->out_w_name_bp, dbc->library.oracle.errhp,
			":out_w_name", ADR(pctx->out_w_name), SIZ(pctx->out_w_name),
			SQLT_STR, &pctx->out_w_name_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_w_street_1_bp, dbc->library.oracle.errhp,
			":out_w_street_1", ADR(pctx->out_w_street_1),
			SIZ(pctx->out_w_street_1), SQLT_STR, &pctx->out_w_street_1_ind, 0,
			0);
	OCIBNDRA(
			pctx->curp1, pctx->out_w_street_2_bp, dbc->library.oracle.errhp,
			":out_w_street_2", ADR(pctx->out_w_street_2),
			SIZ(pctx->out_w_street_2), SQLT_STR, &pctx->out_w_street_2_ind, 0,
			0);
	OCIBNDRA(
			pctx->curp1, pctx->out_w_city_bp, dbc->library.oracle.errhp,
			":out_w_city", ADR(pctx->out_w_city), SIZ(pctx->out_w_city),
			SQLT_STR, &pctx->out_w_city_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_w_state_bp, dbc->library.oracle.errhp,
			":out_w_state", ADR(pctx->out_w_state), SIZ(pctx->out_w_state),
			SQLT_STR, &pctx->out_w_state_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_w_zip_bp, dbc->library.oracle.errhp,
			":out_w_zip", ADR(pctx->out_w_zip), SIZ(pctx->out_w_zip), SQLT_STR,
			&pctx->out_w_zip_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_d_name_bp, dbc->library.oracle.errhp,
			":out_d_name", ADR(pctx->out_d_name), SIZ(pctx->out_d_name),
			SQLT_STR, &pctx->out_d_name_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_d_street_1_bp, dbc->library.oracle.errhp,
			":out_d_street_1", ADR(pctx->out_d_street_1),
			SIZ(pctx->out_d_street_1), SQLT_STR, &pctx->out_d_street_1_ind, 0,
			0);
	OCIBNDRA(
			pctx->curp1, pctx->out_d_street_2_bp, dbc->library.oracle.errhp,
			":out_d_street_2", ADR(pctx->out_d_street_2),
			SIZ(pctx->out_d_street_2), SQLT_STR, &pctx->out_d_street_2_ind, 0,
			0);
	OCIBNDRA(
			pctx->curp1, pctx->out_d_city_bp, dbc->library.oracle.errhp,
			":out_d_city", ADR(pctx->out_d_city), SIZ(pctx->out_d_city),
			SQLT_STR, &pctx->out_d_city_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_d_state_bp, dbc->library.oracle.errhp,
			":out_d_state", ADR(pctx->out_d_state), SIZ(pctx->out_d_state),
			SQLT_STR, &pctx->out_d_state_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_d_zip_bp, dbc->library.oracle.errhp,
			":out_d_zip", ADR(pctx->out_d_zip), SIZ(pctx->out_d_zip), SQLT_STR,
			&pctx->out_d_zip_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_id_bp, dbc->library.oracle.errhp,
			":out_c_id", ADR(pctx->out_c_id), SIZ(int), SQLT_INT,
			&pctx->out_c_id_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_first_bp, dbc->library.oracle.errhp,
			":out_c_first", ADR(pctx->out_c_first), SIZ(pctx->out_c_first),
			SQLT_STR, &pctx->out_c_first_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_middle_bp, dbc->library.oracle.errhp,
			":out_c_middle", ADR(pctx->out_c_middle), SIZ(pctx->out_c_middle),
			SQLT_STR, &pctx->out_c_middle_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_last_bp, dbc->library.oracle.errhp,
			":out_c_last", ADR(pctx->out_c_last), SIZ(pctx->out_c_last),
			SQLT_STR, &pctx->out_c_last_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_street_1_bp, dbc->library.oracle.errhp,
			":out_c_street_1", ADR(pctx->out_c_street_1),
			SIZ(pctx->out_c_street_1), SQLT_STR, &pctx->out_c_street_1_ind, 0,
			0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_street_2_bp, dbc->library.oracle.errhp,
			":out_c_street_2", ADR(pctx->out_c_street_2),
			SIZ(pctx->out_c_street_2), SQLT_STR, &pctx->out_c_street_2_ind, 0,
			0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_city_bp, dbc->library.oracle.errhp,
			":out_c_city", ADR(pctx->out_c_city), SIZ(pctx->out_c_city),
			SQLT_STR, &pctx->out_c_city_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_state_bp, dbc->library.oracle.errhp,
			":out_c_state", ADR(pctx->out_c_state), SIZ(pctx->out_c_state),
			SQLT_STR, &pctx->out_c_state_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_zip_bp, dbc->library.oracle.errhp,
			":out_c_zip", ADR(pctx->out_c_zip), SIZ(pctx->out_c_zip), SQLT_STR,
			&pctx->out_c_zip_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_phone_bp, dbc->library.oracle.errhp,
			":out_c_phone", ADR(pctx->out_c_phone), SIZ(pctx->out_c_phone),
			SQLT_STR, &pctx->out_c_phone_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_since_bp, dbc->library.oracle.errhp,
			":out_c_since", ADR(pctx->out_c_since), SIZ(pctx->out_c_since),
			SQLT_STR, &pctx->out_c_since_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_credit_bp, dbc->library.oracle.errhp,
			":out_c_credit", ADR(pctx->out_c_credit), SIZ(pctx->out_c_credit),
			SQLT_STR, &pctx->out_c_credit_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_credit_lim_bp, dbc->library.oracle.errhp,
			":out_c_credit_lim", ADR(pctx->out_c_credit_lim), SIZ(double),
			SQLT_FLT, &pctx->out_c_credit_lim_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_discount_bp, dbc->library.oracle.errhp,
			":out_c_discount", ADR(pctx->out_c_discount), SIZ(double), SQLT_FLT,
			&pctx->out_c_discount_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_balance_bp, dbc->library.oracle.errhp,
			":out_c_balance", ADR(pctx->out_c_balance), SIZ(double), SQLT_FLT,
			&pctx->out_c_balance_ind, 0, 0);
	OCIBNDRA(
			pctx->curp1, pctx->out_c_data_bp, dbc->library.oracle.errhp,
			":out_c_data", ADR(pctx->out_c_data), SIZ(pctx->out_c_data),
			SQLT_STR, &pctx->out_c_data_ind, 0, 0);

	return OK;
}

int execute_payment_oracle(struct db_context_t *dbc, struct payment_t *data) {
	struct paymentctx *pctx = dbc->library.oracle.pctx;
	int rc = OK;

	/* Input variables. */
	dbc->library.oracle.pctx->w_id = data->w_id;
	dbc->library.oracle.pctx->d_id = data->d_id;
	dbc->library.oracle.pctx->c_id = data->c_id;
	dbc->library.oracle.pctx->c_w_id = data->c_w_id;
	dbc->library.oracle.pctx->c_d_id = data->c_d_id;
	wcstombs(
			dbc->library.oracle.pctx->c_last, data->c_last,
			4 * (C_LAST_LEN + 1));
	dbc->library.oracle.pctx->h_amount = data->h_amount;

	int retries = 0;
	int execstatus = 0;
	int errcode = 0;

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE(
			"STMT_PAYMENT input CALL payment(%d, %d, %d, %d, %d, '%s', %f);\n",
			dbc->library.oracle.pctx->w_id, dbc->library.oracle.pctx->d_id,
			dbc->library.oracle.pctx->c_id, dbc->library.oracle.pctx->c_w_id,
			dbc->library.oracle.pctx->c_d_id, dbc->library.oracle.pctx->c_last,
			dbc->library.oracle.pctx->h_amount);
#endif

retry:
	execstatus = OCIStmtExecute(
			dbc->library.oracle.oraclesvc, dbc->library.oracle.pctx->curp1,
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
	if (pctx->out_w_name_ind == 0) {
		snprintf(data->w_name, sizeof(data->w_name), "%s", pctx->out_w_name);
	}
	if (pctx->out_w_street_1_ind == 0) {
		snprintf(
				data->w_street_1, sizeof(data->w_street_1), "%s",
				pctx->out_w_street_1);
	}
	if (pctx->out_w_street_2_ind == 0) {
		snprintf(
				data->w_street_2, sizeof(data->w_street_2), "%s",
				pctx->out_w_street_2);
	}
	if (pctx->out_w_city_ind == 0) {
		snprintf(data->w_city, sizeof(data->w_city), "%s", pctx->out_w_city);
	}
	if (pctx->out_w_state_ind == 0) {
		snprintf(data->w_state, sizeof(data->w_state), "%s", pctx->out_w_state);
	}
	if (pctx->out_w_zip_ind == 0) {
		snprintf(data->w_zip, sizeof(data->w_zip), "%s", pctx->out_w_zip);
	}
	if (pctx->out_d_name_ind == 0) {
		snprintf(data->d_name, sizeof(data->d_name), "%s", pctx->out_d_name);
	}
	if (pctx->out_d_street_1_ind == 0) {
		snprintf(
				data->d_street_1, sizeof(data->d_street_1), "%s",
				pctx->out_d_street_1);
	}
	if (pctx->out_d_street_2_ind == 0) {
		snprintf(
				data->d_street_2, sizeof(data->d_street_2), "%s",
				pctx->out_d_street_2);
	}
	if (pctx->out_d_city_ind == 0) {
		snprintf(data->d_city, sizeof(data->d_city), "%s", pctx->out_d_city);
	}
	if (pctx->out_d_state_ind == 0) {
		snprintf(data->d_state, sizeof(data->d_state), "%s", pctx->out_d_state);
	}
	if (pctx->out_d_zip_ind == 0) {
		snprintf(data->d_zip, sizeof(data->d_zip), "%s", pctx->out_d_zip);
	}
	if (pctx->out_c_id_ind == 0) {
		data->c_id = pctx->out_c_id;
	}
	if (pctx->out_c_first_ind == 0) {
		snprintf(data->c_first, sizeof(data->c_first), "%s", pctx->out_c_first);
	}
	if (pctx->out_c_middle_ind == 0) {
		snprintf(
				data->c_middle, sizeof(data->c_middle), "%s",
				pctx->out_c_middle);
	}
	if (pctx->out_c_last_ind == 0) {
		mbstowcs(data->c_last, pctx->out_c_last, C_LAST_LEN + 1);
	}
	if (pctx->out_c_street_1_ind == 0) {
		snprintf(
				data->c_street_1, sizeof(data->c_street_1), "%s",
				pctx->out_c_street_1);
	}
	if (pctx->out_c_street_2_ind == 0) {
		snprintf(
				data->c_street_2, sizeof(data->c_street_2), "%s",
				pctx->out_c_street_2);
	}
	if (pctx->out_c_city_ind == 0) {
		snprintf(data->c_city, sizeof(data->c_city), "%s", pctx->out_c_city);
	}
	if (pctx->out_c_state_ind == 0) {
		snprintf(data->c_state, sizeof(data->c_state), "%s", pctx->out_c_state);
	}
	if (pctx->out_c_zip_ind == 0) {
		snprintf(data->c_zip, sizeof(data->c_zip), "%s", pctx->out_c_zip);
	}
	if (pctx->out_c_phone_ind == 0) {
		snprintf(data->c_phone, sizeof(data->c_phone), "%s", pctx->out_c_phone);
	}
	if (pctx->out_c_since_ind == 0) {
		snprintf(data->c_since, sizeof(data->c_since), "%s", pctx->out_c_since);
	}
	if (pctx->out_c_credit_ind == 0) {
		snprintf(
				data->c_credit, sizeof(data->c_credit), "%s",
				pctx->out_c_credit);
	}
	if (pctx->out_c_credit_lim_ind == 0) {
		data->c_credit_lim = pctx->out_c_credit_lim;
	}
	if (pctx->out_c_discount_ind == 0) {
		data->c_discount = pctx->out_c_discount;
	}
	if (pctx->out_c_balance_ind == 0) {
		data->c_balance = pctx->out_c_balance;
	}
	if (pctx->out_c_data_ind == 0) {
		snprintf(data->c_data, sizeof(data->c_data), "%s", pctx->out_c_data);
	}

	return rc;
}
