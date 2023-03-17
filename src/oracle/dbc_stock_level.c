/*
        This file is released under the terms of the Artistic License.  Please see
        the file LICENSE, included in this package, for details.
        Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
*/


#include "oracle_stock_level.h"

#define STMT_STOCK_LEVEL \
	"CALL stock_level (:w_id, :d_id, :threshold, :low_stock)"

struct stockctx {
	int w_id;
	int d_id;
	int threshold;
	int low_stock;

	OCIStmt *curs1;

	OCIBind *w_id_bp;
	OCIBind *d_id_bp;
	OCIBind *threshold_bp;
	OCIBind *low_stock_bp;
};

typedef struct stockctx stockctx;

int init_stock_level_txn (struct db_context_t *dbc)
{
	dbc->sctx = (stockctx*) malloc(sizeof(stockctx));

	if (dbc->sctx == NULL)
		return ERROR;

	/* STOCK_LEVEL_1 */
	OCIERROR(dbc->errhp,OCIHandleAlloc(dbc->oracleenv,(dvoid **)(&dbc->sctx->curs1), OCI_HTYPE_STMT, 0, (dvoid**)0));
	OCIERROR(dbc->errhp,OCIStmtPrepare(dbc->sctx->curs1, dbc->errhp, (text *)STMT_STOCK_LEVEL,
			strlen((char *)STMT_STOCK_LEVEL), (ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT));

	/* bind variables */
	OCIBND(dbc->sctx->curs1, dbc->sctx->w_id_bp,dbc->errhp,":w_id",ADR(dbc->sctx->w_id),
		SIZ(int),SQLT_INT);
	OCIBND(dbc->sctx->curs1, dbc->sctx->d_id_bp,dbc->errhp,":d_id",ADR(dbc->sctx->d_id),
		SIZ(int),SQLT_INT);
	OCIBND(dbc->sctx->curs1, dbc->sctx->threshold_bp,dbc->errhp,":threshold",ADR(dbc->sctx->threshold),
		SIZ(int),SQLT_INT);
	OCIBND(dbc->sctx->curs1, dbc->sctx->low_stock_bp,dbc->errhp,":low_stock",ADR(dbc->sctx->low_stock),
		SIZ(int),SQLT_INT);

	return OK;
}

int execute_stock_level(struct db_context_t *dbc, struct stock_level_t *data)
{
	int rc=OK;

	/* Input variables. */
	dbc->sctx->w_id = data->w_id;
	dbc->sctx->d_id = data->d_id;
	dbc->sctx->threshold = data->threshold;

	int retries=0;
	int execstatus=0;
	int errcode=0;

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE("STMT_STOCK_LEVEL call stock_level(%d, %d, %d, %d);\n",dbc->sctx->w_id,dbc->sctx->d_id,dbc->sctx->threshold,dbc->sctx->low_stock);
#endif

retry:
	execstatus= OCIStmtExecute(dbc->oraclesvc,dbc->sctx->curs1,dbc->errhp,1,0,0,0,
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
#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE("STMT_STOCK_LEVEL result: %d\n",dbc->sctx->low_stock);
#endif

        return rc;
}

#ifdef UNIT_TEST_STOCK_LEVEL
int main ()
{
	struct db_context_t dbc;
	struct stock_level_t data;
	int rc;

	memset(&dbc, '0', sizeof(struct db_context_t));

	_db_init("dbt", "localhost" , "dbt", "dbt", "12000");

	rc = _connect_to_db(&dbc);

	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("Connect failed");
		return -1;
	}

	data.w_id=1;
	data.d_id=1;
	data.threshold=1;

	rc=execute_stock_level(&dbc, &data);

	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("execute_stock_level failed");
	}

	rc = _disconnect_from_db(&dbc);
	
	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("_disconnect_from_db failed");
	}

	return 0;
}
#endif
