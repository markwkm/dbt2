/*
        This file is released under the terms of the Artistic License.  Please see
        the file LICENSE, included in this package, for details.
        Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
*/


#include <oracle_order_status.h>

#define STMT_ORDER_STATUS \
	"CALL order_status (:c_id, :c_w_id, :c_d_id, :c_last)"

struct ordstatusctx {
	int c_id;
	int c_w_id;
	int c_d_id;
	char c_last[C_LAST_LEN+1];

	OCIStmt *curo1;

	OCIBind *c_id_bp;
	OCIBind *c_w_id_bp;
	OCIBind *c_d_id_bp;
	OCIBind *c_last_bp;
};

typedef struct ordstatusctx ordstatusctx;

int init_order_status_txn (struct db_context_t *dbc)
{
	dbc->octx = (ordstatusctx*) malloc(sizeof(ordstatusctx));

	if (dbc->octx == NULL)
		return ERROR;

	/* ORDER_STATUS_1 */
	OCIERROR(dbc->errhp,OCIHandleAlloc(dbc->oracleenv,(dvoid **)(&dbc->octx->curo1), OCI_HTYPE_STMT, 0, (dvoid**)0));
	OCIERROR(dbc->errhp,OCIStmtPrepare(dbc->octx->curo1, dbc->errhp, (text *)STMT_ORDER_STATUS,
			strlen((char *)STMT_ORDER_STATUS), (ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT));

	/* bind variables */
	OCIBND(dbc->octx->curo1, dbc->octx->c_id_bp,dbc->errhp,":c_id",ADR(dbc->octx->c_id),
		SIZ(int),SQLT_INT);
	OCIBND(dbc->octx->curo1, dbc->octx->c_w_id_bp,dbc->errhp,":c_w_id",ADR(dbc->octx->c_w_id),
		SIZ(int),SQLT_INT);
	OCIBND(dbc->octx->curo1, dbc->octx->c_d_id_bp,dbc->errhp,":c_d_id",ADR(dbc->octx->c_d_id),
		SIZ(int),SQLT_INT);
	OCIBND(dbc->octx->curo1, dbc->octx->c_last_bp,dbc->errhp,":c_last",ADR(dbc->octx->c_last),
		SIZ(dbc->octx->c_last),SQLT_STR);

	return OK;
}

int execute_order_status(struct db_context_t *dbc, struct order_status_t *data)
{
	int rc=OK;

	/* Input variables. */
	dbc->octx->c_id = data->c_id;
	dbc->octx->c_w_id = data->c_w_id;
	dbc->octx->c_d_id = data->c_d_id;
	strncpy (dbc->octx->c_last, data->c_last, C_LAST_LEN+1);

	int retries=0;
	int execstatus=0;
	int errcode=0;

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE("STMT_ORDER_STATUS call order_status(%d, %d, %d, '%s');\n",dbc->octx->c_id,dbc->octx->c_w_id,dbc->octx->c_d_id,dbc->octx->c_last);
#endif
retry:
	execstatus= OCIStmtExecute(dbc->oraclesvc,dbc->octx->curo1,dbc->errhp,1,0,0,0,
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

#ifdef UNIT_TEST_ORDER_STATUS
int main ()
{
	struct db_context_t dbc;
	struct order_status_t data;
	int rc;

	memset(&dbc, '0', sizeof(struct db_context_t));

	_db_init("dbt", "localhost" , "dbt", "dbt", "12000");

	rc = _connect_to_db(&dbc);

	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("Connect failed");
		return -1;
	}

	data.c_id=1;
	data.c_d_id=1;
	data.c_w_id=1;
	strcpy(&data.c_last, "BARBARBAR");

	rc=execute_order_status(&dbc, &data);

	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("execute_order_status failed");
	}

	rc = _disconnect_from_db(&dbc);
	
	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("_disconnect_from_db failed");
	}
	
	return 0;
}
#endif
