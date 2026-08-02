/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
 * Copyright The DBT-2 Authors
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "common.h"
#include "db.h"
#include "logging.h"
#include "oracle_delivery.h"
#include "oracle_integrity.h"
#include "oracle_new_order.h"
#include "oracle_order_status.h"
#include "oracle_payment.h"
#include "oracle_stock_level.h"

int commit_transaction_oracle(struct db_context_t *dbc) {
	/* Each transaction commits with OCI_COMMIT_ON_SUCCESS. */
	return OK;
}

/* Open a connection to the database. */
int connect_to_db_oracle(struct db_context_t *dbc) {
	struct db_context_oracle *ora = &dbc->library.oracle;
	int rc;

	OCIInitialize(OCI_THREADED | OCI_OBJECT, (dvoid *) 0, 0, 0, 0);
	OCIEnvInit(&ora->oracleenv, OCI_DEFAULT, 0, (dvoid **) 0);

	OCIHandleAlloc(
			(dvoid *) ora->oracleenv, (dvoid **) &ora->oraclesrv,
			OCI_HTYPE_SERVER, 0, (dvoid **) 0);
	OCIHandleAlloc(
			(dvoid *) ora->oracleenv, (dvoid **) &ora->errhp, OCI_HTYPE_ERROR,
			0, (dvoid **) 0);
	OCIHandleAlloc(
			(dvoid *) ora->oracleenv, (dvoid **) &ora->oraclesvc,
			OCI_HTYPE_SVCCTX, 0, (dvoid **) 0);

	rc = OCIServerAttach(
			ora->oraclesrv, ora->errhp, (text *) ora->dbname,
			strlen(ora->dbname), OCI_DEFAULT);
	if (rc != OCI_SUCCESS) {
		OCIERROR(ora->errhp, rc);
		LOG_ERROR_MESSAGE("connection to '%s' failed", ora->dbname);
		return ERROR;
	}

	OCIAttrSet(
			(dvoid *) ora->oraclesvc, OCI_HTYPE_SVCCTX,
			(dvoid *) ora->oraclesrv, (ub4) 0, OCI_ATTR_SERVER, ora->errhp);

	OCIHandleAlloc(
			(dvoid *) ora->oracleenv, (dvoid **) &ora->oracleusr,
			OCI_HTYPE_SESSION, 0, (dvoid **) 0);
	OCIAttrSet(
			(dvoid *) ora->oracleusr, OCI_HTYPE_SESSION, (dvoid *) ora->user,
			(ub4) strlen(ora->user), OCI_ATTR_USERNAME, ora->errhp);
	OCIAttrSet(
			(dvoid *) ora->oracleusr, OCI_HTYPE_SESSION, (dvoid *) ora->pass,
			(ub4) strlen(ora->pass), OCI_ATTR_PASSWORD, ora->errhp);

	rc = OCISessionBegin(
			ora->oraclesvc, ora->errhp, ora->oracleusr, OCI_CRED_RDBMS,
			OCI_DEFAULT);
	if (rc != OCI_SUCCESS) {
		OCIERROR(ora->errhp, rc);
		LOG_ERROR_MESSAGE(
				"session begin failed for user '%s' on '%s'", ora->user,
				ora->dbname);
		return ERROR;
	}

	OCIAttrSet(
			ora->oraclesvc, OCI_HTYPE_SVCCTX, ora->oracleusr, 0,
			OCI_ATTR_SESSION, ora->errhp);

	if (init_delivery_txn_oracle(dbc) != OK) {
		LOG_ERROR_MESSAGE("Delivery context initialization failed");
		return ERROR;
	}
	if (init_integrity_txn_oracle(dbc) != OK) {
		LOG_ERROR_MESSAGE("Integrity context initialization failed");
		return ERROR;
	}
	if (init_nord_txn_oracle(dbc) != OK) {
		LOG_ERROR_MESSAGE("Neworder context initialization failed");
		return ERROR;
	}
	if (init_order_status_txn_oracle(dbc) != OK) {
		LOG_ERROR_MESSAGE("Orderstatus context initialization failed");
		return ERROR;
	}
	if (init_payment_txn_oracle(dbc) != OK) {
		LOG_ERROR_MESSAGE("Payment context initialization failed");
		return ERROR;
	}
	if (init_stock_level_txn_oracle(dbc) != OK) {
		LOG_ERROR_MESSAGE("Stocklevel context initialization failed");
		return ERROR;
	}

	return OK;
}

/* Disconnect from the database and free the connection handle. */
int disconnect_from_db_oracle(struct db_context_t *dbc) {
	struct db_context_oracle *ora = &dbc->library.oracle;

	free(ora->dctx);
	ora->dctx = NULL;
	free(ora->ictx);
	ora->ictx = NULL;
	free(ora->nctx);
	ora->nctx = NULL;
	free(ora->octx);
	ora->octx = NULL;
	free(ora->pctx);
	ora->pctx = NULL;
	free(ora->sctx);
	ora->sctx = NULL;

	OCIERROR(
			ora->errhp,
			OCISessionEnd(
					ora->oraclesvc, ora->errhp, ora->oracleusr, OCI_DEFAULT));
	OCIERROR(
			ora->errhp,
			OCIServerDetach(ora->oraclesrv, ora->errhp, OCI_DEFAULT));
	OCIHandleFree((dvoid *) ora->oracleusr, OCI_HTYPE_SESSION);
	OCIHandleFree((dvoid *) ora->oraclesvc, OCI_HTYPE_SVCCTX);
	OCIHandleFree((dvoid *) ora->errhp, OCI_HTYPE_ERROR);
	OCIHandleFree((dvoid *) ora->oraclesrv, OCI_HTYPE_SERVER);
	OCIHandleFree((dvoid *) ora->oracleenv, OCI_HTYPE_ENV);

	return OK;
}

int rollback_transaction_oracle(struct db_context_t *dbc) {
	struct db_context_oracle *ora = &dbc->library.oracle;

	OCITransRollback(ora->oraclesvc, ora->errhp, OCI_DEFAULT);
	return STATUS_ROLLBACK;
}

int db_init_oracle(
		struct db_context_t *dbc, char *dbname, char *user, char *pass) {
	dbc->connect = connect_to_db_oracle;
	dbc->commit_transaction = commit_transaction_oracle;
	dbc->disconnect = disconnect_from_db_oracle;
	dbc->rollback_transaction = rollback_transaction_oracle;
	dbc->execute_delivery = execute_delivery_oracle;
	dbc->execute_integrity = execute_integrity_oracle;
	dbc->execute_new_order = execute_new_order_oracle;
	dbc->execute_order_status = execute_order_status_oracle;
	dbc->execute_payment = execute_payment_oracle;
	dbc->execute_stock_level = execute_stock_level_oracle;

	/* Copy values only if it's not NULL or empty. */
	if (dbname != NULL && dbname[0] != '\0') {
		strncpy(dbc->library.oracle.dbname, dbname, ORACLE_DBNAME_LEN);
	} else {
		strncpy(dbc->library.oracle.dbname, "//localhost:1521/FREEPDB1",
				ORACLE_DBNAME_LEN);
	}
	if (user != NULL && user[0] != '\0') {
		strncpy(dbc->library.oracle.user, user, ORACLE_USER_LEN);
	} else {
		strncpy(dbc->library.oracle.user, DB_USER, ORACLE_USER_LEN);
	}
	if (pass != NULL && pass[0] != '\0') {
		strncpy(dbc->library.oracle.pass, pass, ORACLE_PASS_LEN);
	} else {
		strncpy(dbc->library.oracle.pass, DB_PASS, ORACLE_PASS_LEN);
	}

	return OK;
}

int ocierror(char *fname, int lineno, OCIError *errhp, sword status) {
	text errbuf[512];
	sb4 errcode;
	sb4 lstat;
	ub4 recno = 2;

	switch (status) {
	case OCI_SUCCESS:
		break;
	case OCI_SUCCESS_WITH_INFO:
		fprintf(stderr, "Module %s Line %d\n", fname, lineno);
		fprintf(stderr, "Error - OCI_SUCCESS_WITH_INFO\n");
		lstat = OCIErrorGet(
				errhp, recno++, (text *) NULL, &errcode, errbuf,
				(ub4) sizeof(errbuf), OCI_HTYPE_ERROR);
		fprintf(stderr, "Error - %s\n", errbuf);
		break;
	case OCI_NEED_DATA:
		fprintf(stderr, "Module %s Line %d\n", fname, lineno);
		fprintf(stderr, "Error - OCI_NEED_DATA\n");
		return (IRRECERR);
	case OCI_NO_DATA:
		fprintf(stderr, "Module %s Line %d\n", fname, lineno);
		fprintf(stderr, "Error - OCI_NO_DATA\n");
		return (IRRECERR);
	case OCI_ERROR:
		lstat = OCIErrorGet(
				errhp, (ub4) 1, (text *) NULL, &errcode, errbuf,
				(ub4) sizeof(errbuf), OCI_HTYPE_ERROR);
		if (errcode == NOT_SERIALIZABLE)
			return (errcode);
		if (errcode == SNAPSHOT_TOO_OLD)
			return (errcode);
		if (errcode == NOT_SAFE_REPLAY)
			return (errcode);
		if (errcode == COLUMN_VALUE_NULL)
			return (errcode);
		if (errcode == NO_DATA_FOUND)
			return (errcode);
		/*
		 * The expected New-Order rollback case: the neworder
		 * procedure raises ORA-20001 for an unused item number.
		 */
		if (errcode == ITEM_NOT_VALID)
			return (errcode);
		while (lstat != OCI_NO_DATA) {
			fprintf(stderr, "Module %s Line %d\n", fname, lineno);
			fprintf(stderr, "Error - %s\n", errbuf);
			lstat = OCIErrorGet(
					errhp, recno++, (text *) NULL, &errcode, errbuf,
					(ub4) sizeof(errbuf), OCI_HTYPE_ERROR);
		}
		return (errcode);
	case OCI_INVALID_HANDLE:
		fprintf(stderr, "Module %s Line %d\n", fname, lineno);
		fprintf(stderr, "Error - OCI_INVALID_HANDLE\n");
		exit(-1);
	case OCI_STILL_EXECUTING:
		fprintf(stderr, "Module %s Line %d\n", fname, lineno);
		fprintf(stderr, "Error - OCI_STILL_EXECUTE\n");
		return (IRRECERR);
	case OCI_CONTINUE:
		fprintf(stderr, "Module %s Line %d\n", fname, lineno);
		fprintf(stderr, "Error - OCI_CONTINUE\n");
		return (IRRECERR);
	default:
		fprintf(stderr, "Module %s Line %d\n", fname, lineno);
		fprintf(stderr, "Status - %d\n", (int) status);
		return (IRRECERR);
	}
	return (RECOVERR);
}
