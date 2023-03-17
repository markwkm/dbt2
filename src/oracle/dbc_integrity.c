/*
        This file is released under the terms of the Artistic License.  Please see
        the file LICENSE, included in this package, for details.
        Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
*/

#include <oracle_integrity.h>

#define STMT_INTEGRITY "SELECT count(*) FROM ware"

struct integrityctx {
	int w_nware;

	OCIStmt *curi1;

	OCIDefine *w_nware_dp;
};

typedef struct integrityctx integrityctx;

int init_integrity_txn (struct db_context_t *dbc)
{
	dbc->ictx = (integrityctx*) malloc(sizeof(integrityctx));

	if (dbc->ictx == NULL)
		return ERROR;

	/* STMT_INTEGRITY */
	OCIERROR(dbc->errhp,OCIHandleAlloc(dbc->oracleenv,(dvoid **)(&dbc->ictx->curi1), OCI_HTYPE_STMT, 0, (dvoid**)0));
	OCIERROR(dbc->errhp,OCIStmtPrepare(dbc->ictx->curi1, dbc->errhp, (text *)STMT_INTEGRITY,
			strlen((char *)STMT_INTEGRITY), (ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT));

	/* bind variables */
		/* none */

	/* define variables */
	OCIDEFINE(dbc->ictx->curi1, dbc->ictx->w_nware_dp,dbc->errhp,1,ADR(dbc->ictx->w_nware),
		SIZ(int), SQLT_INT);

	return OK;
}

int execute_integrity(struct db_context_t *dbc, struct integrity_t *data)
{
	int rc=OK;

	/* Input variables. */
	int w_id = data->w_id;

	int retries=0;
	int execstatus=0;
	int errcode=0;

#ifdef DEBUG_QUERY
        LOG_ERROR_MESSAGE("STMT_INTEGRITY query: %s\n",STMT_INTEGRITY);
#endif

retry:
	execstatus= OCIStmtExecute(dbc->oraclesvc,dbc->ictx->curi1,dbc->errhp,1,0,0,0,
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
		/* No rows in ware !*/
		LOG_ERROR_MESSAGE("ERROR: W_ID is NULL for query w_id: %d\n", w_id);
		return -1;
	}

	//  dbc->ictx->w_nware in the result
	if (dbc->ictx->w_nware != w_id)
	{
		LOG_ERROR_MESSAGE("ERROR: Expect W_ID = %d Got W_ID = %d", w_id, dbc->ictx->w_nware);
		return -1;
	}

#ifdef DEBUG_QUERY
	LOG_ERROR_MESSAGE("STMT_INTEGRITY result: %d\n",dbc->ictx->w_nware);
#endif
	return rc;
}

#ifdef UNIT_TEST_INTEGRITY
int main ()
{
	struct db_context_t dbc;
	struct integrity_t data;
	int rc;

	memset(&dbc, '0', sizeof(struct db_context_t));

	_db_init("dbt", "localhost" , "dbt", "dbt", "12000");

	rc = _connect_to_db(&dbc);

	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("Connect failed");
		return -1;
	}

	data.w_id=15;

	rc=execute_integrity(&dbc, &data);

	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("execute_integrity failed");
	}

	rc = _disconnect_from_db(&dbc);
	
	if ( rc != OK ) {
		LOG_ERROR_MESSAGE("_disconnect_from_db failed");
	}

	return 0;
}
#endif /* UNIT_TEST_INTEGRITY */
