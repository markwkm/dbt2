/*
        This file is released under the terms of the Artistic License.  Please see
        the file LICENSE, included in this package, for details.
        Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
*/


#include <oracle_delivery.h>

#define STMT_DELIVERY \
	"CALL delivery (:w_id, :o_carrier_id)"

struct deliveryctx {
	int w_id;
	int o_carrier_id;

	OCIStmt *curd1;

	OCIBind *w_id_bp;
	OCIBind *o_carrier_id_bp;
};

typedef struct deliveryctx deliveryctx;

int init_delivery_txn (struct db_context_t *dbc)
{

	dbc->dctx = (deliveryctx*) malloc(sizeof(deliveryctx));

	if (dbc->dctx == NULL)
		return ERROR;

	/* DELIVERY_1 */
	OCIERROR(dbc->errhp,OCIHandleAlloc(dbc->oracleenv,(dvoid **)(&dbc->dctx->curd1), OCI_HTYPE_STMT, 0, (dvoid**)0));
	OCIERROR(dbc->errhp,OCIStmtPrepare(dbc->dctx->curd1, dbc->errhp, (text *)STMT_DELIVERY,
			strlen((char *)STMT_DELIVERY), (ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT));

	/* bind variables */
	OCIBND(dbc->dctx->curd1, dbc->dctx->w_id_bp,dbc->errhp,":w_id",ADR(dbc->dctx->w_id),
		SIZ(int),SQLT_INT);
	OCIBND(dbc->dctx->curd1, dbc->dctx->o_carrier_id_bp,dbc->errhp,":o_carrier_id",ADR(dbc->dctx->o_carrier_id),
		SIZ(int),SQLT_INT);

	return OK;
}

int execute_delivery(struct db_context_t *dbc, struct delivery_t *data)
{
	int rc=OK;

	/* Input variables. */
	dbc->dctx->w_id = data->w_id;
	dbc->dctx->o_carrier_id = data->o_carrier_id;

	int retries=0;
	int execstatus=0;
	int errcode=0;
         
#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE("STMT_DELIVERY CALL DELIVERY(%d, %d);\n",dbc->dctx->w_id, data->o_carrier_id);
#endif

retry:
	execstatus= OCIStmtExecute(dbc->oraclesvc,dbc->dctx->curd1,dbc->errhp,1,0,0,0,
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

#ifdef UNIT_TEST_DELIVERY
int main ()
{
	struct db_context_t dbc;
	struct delivery_t data;
	int rc;

	memset(&dbc, '0', sizeof(struct db_context_t));

	_db_init("dbt", "localhost" , "dbt", "dbt", "12000");

	rc = _connect_to_db(&dbc);

	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("Connect failed");
		return -1;
	}

	data.w_id=1;
	data.o_carrier_id=1;

	rc=execute_delivery(&dbc, &data);
	
	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("execute_delivery failed");
	}

	rc = _disconnect_from_db(&dbc);
	
	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("_disconnect_from_db failed");
	}

	return 0;
}
#endif /* UNIT_TEST_DELIVERY */
