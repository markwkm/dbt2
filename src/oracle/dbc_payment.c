/*
        This file is released under the terms of the Artistic License.  Please see
        the file LICENSE, included in this package, for details.
        Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
*/


#include <oracle_payment.h>

#define STMT_PAYMENT \
	"CALL payment (:w_id, :d_id, :c_id, :c_w_id, :c_d_id, :c_last, :h_amount)"

struct paymentctx {
	int w_id;
	int d_id;
	int c_id;
	int c_w_id;
	int c_d_id;
	
	char c_last[C_LAST_LEN+1];

	float h_amount;

	OCIStmt *curp1;

	OCIBind *w_id_bp;
	OCIBind *d_id_bp;
	OCIBind *c_id_bp;
	OCIBind *c_w__id_bp;
	OCIBind *c_d__id_bp;
	OCIBind *c_last_bp;
	OCIBind *h_amount_bp;
};

typedef struct paymentctx paymentctx;

int init_payment_txn (struct db_context_t *dbc)
{
	dbc->pctx = (paymentctx*) malloc(sizeof(paymentctx));

	if (dbc->pctx == NULL)
		return ERROR;

	/* PAYMENT_1 */
	OCIERROR(dbc->errhp,OCIHandleAlloc(dbc->oracleenv,(dvoid **)(&dbc->pctx->curp1), OCI_HTYPE_STMT, 0, (dvoid**)0));
	OCIERROR(dbc->errhp,OCIStmtPrepare(dbc->pctx->curp1, dbc->errhp, (text *)STMT_PAYMENT,
			strlen((char *)STMT_PAYMENT), (ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT));

	/* bind variables */
	OCIBND(dbc->pctx->curp1, dbc->pctx->w_id_bp,dbc->errhp,":w_id",ADR(dbc->pctx->w_id),
		SIZ(int),SQLT_INT);
	OCIBND(dbc->pctx->curp1, dbc->pctx->w_id_bp,dbc->errhp,":d_id",ADR(dbc->pctx->d_id),
		SIZ(int),SQLT_INT);
	OCIBND(dbc->pctx->curp1, dbc->pctx->w_id_bp,dbc->errhp,":c_id",ADR(dbc->pctx->c_id),
		SIZ(int),SQLT_INT);
	OCIBND(dbc->pctx->curp1, dbc->pctx->w_id_bp,dbc->errhp,":c_w_id",ADR(dbc->pctx->c_w_id),
		SIZ(int),SQLT_INT);
	OCIBND(dbc->pctx->curp1, dbc->pctx->w_id_bp,dbc->errhp,":c_d_id",ADR(dbc->pctx->c_d_id),
		SIZ(int),SQLT_INT);
	OCIBND(dbc->pctx->curp1, dbc->pctx->w_id_bp,dbc->errhp,":c_last",ADR(dbc->pctx->c_last),
		SIZ(dbc->pctx->c_last),SQLT_STR);
	OCIBND(dbc->pctx->curp1, dbc->pctx->w_id_bp,dbc->errhp,":h_amount",ADR(dbc->pctx->h_amount),
		SIZ(float),SQLT_FLT);

	return OK;
}

int execute_payment(struct db_context_t *dbc, struct payment_t *data)
{
	int rc=OK;

	/* Input variables. */
	dbc->pctx->w_id = data->w_id;
	dbc->pctx->d_id = data->d_id;
	dbc->pctx->c_id = data->c_id;
	dbc->pctx->c_w_id = data->c_w_id;
	dbc->pctx->c_d_id = data->c_d_id;
	strncpy (dbc->pctx->c_last, data->c_last, C_LAST_LEN+1);
	dbc->pctx->h_amount = data->h_amount;

	int retries=0;
	int execstatus=0;
	int errcode=0;

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE("STMT_PAYMENT input CALL payment(%d, %d, %d, %d, %d, '%s', %f);\n",dbc->pctx->w_id,dbc->pctx->d_id,dbc->pctx->c_id,dbc->pctx->c_w_id,dbc->pctx->c_d_id,dbc->pctx->c_last, dbc->pctx->h_amount);
#endif

retry:
	execstatus= OCIStmtExecute(dbc->oraclesvc,dbc->pctx->curp1,dbc->errhp,1,0,0,0,
       	       				OCI_COMMIT_ON_SUCCESS | OCI_DEFAULT);

	if ((execstatus != OCI_NO_DATA) && (execstatus != OCI_SUCCESS))
	{
		errcode=OCIERROR(dbc->errhp, execstatus);
		if((errcode == NOT_SERIALIZABLE) || (errcode == RECOVERR)
				|| (errcode == SNAPSHOT_TOO_OLD) || (errcode == NOT_SAFE_REPLAY)
				|| (errcode == COLUMN_VALUE_NULL))
		{
			OCITransCommit(dbc->oraclesvc,dbc->errhp,OCI_DEFAULT);
			retries++;
			goto retry;
		} else {
			return -1;
		}
	}
	if (execstatus == OCI_NO_DATA) {
		return OK;
	}

        return rc;
}

#ifdef UNIT_TEST_PAYMENT
int main ()
{
	struct db_context_t dbc;
	struct payment_t data;
	int rc;

	memset(&dbc, '0', sizeof(struct db_context_t));

	_db_init("dbt", "localhost" , "dbt", "dbt", "12000");

	rc = _connect_to_db(&dbc);

	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("Connect failed");
		return -1;
	}

	data.w_id=1;

	rc=execute_payment(&dbc, &data);
	
	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("execute_payment failed");
	}

	rc = _disconnect_from_db(&dbc);
	
	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("_disconnect_from_db failed");
	}

	return 0;
}
#endif
