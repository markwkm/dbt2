/*
	This file is released under the terms of the Artistic License.  Please see
 	the file LICENSE, included in this package, for details.
 	Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
*/

#include <pthread.h>
#include "common.h"
#include "logging.h"
#include "oracle_common.h"
#include <stdio.h>

char oracle_dbname[32] = "dbt2";
char oracle_host[128] = "localhost";
char oracle_user[32] = "dbt";
char oracle_pass[32] = "dbt";
char oracle_port_t[32] = "0";
char oracle_socket_t[256] = "/tmp/mysql.sock";

extern int init_delivery_txn (struct db_context_t *dbc);
extern int init_integrity_txn (struct db_context_t *dbc);
extern int init_nord_txn (struct db_context_t *dbc);
extern int init_order_status_txn (struct db_context_t *dbc);
extern int init_payment_txn (struct db_context_t *dbc);
extern int init_stock_level_txn (struct db_context_t *dbc);

int commit_transaction(struct db_context_t *dbc)
{

	/* This is already handled by each transaction */
	return OK;
}

/* Open a connection to the database. */
int _connect_to_db(struct db_context_t *dbc)
{
	int rc;
#ifdef DBT2_OCI_THREADED
	OCIInitialize(OCI_THREADED|OCI_OBJECT,(dvoid *)0,0,0,0);
#else
	OCIInitialize(OCI_DEFAULT|OCI_OBJECT,(dvoid *)0,0,0,0);
#endif
	OCIEnvInit(&(dbc->oracleenv), OCI_DEFAULT, 0, (dvoid **)0);

	OCIHandleAlloc((dvoid *)(dbc->oracleenv), (dvoid **)&(dbc->oraclesrv), OCI_HTYPE_SERVER, 0 , (dvoid **)0);
	OCIHandleAlloc((dvoid *)(dbc->oracleenv), (dvoid **)&(dbc->errhp), OCI_HTYPE_ERROR, 0 , (dvoid **)0);
	OCIHandleAlloc((dvoid *)(dbc->oracleenv), (dvoid **)&(dbc->oraclesvc), OCI_HTYPE_SVCCTX, 0 , (dvoid **)0);

	if ((rc=OCIServerAttach((dbc->oraclesrv), (dbc->errhp), (text *)oracle_dbname,strlen(oracle_dbname),OCI_DEFAULT))) {
		OCIERROR((dbc->errhp),OCIServerAttach((dbc->oraclesrv), (dbc->errhp), (text *)oracle_dbname,strlen(oracle_dbname),OCI_DEFAULT));
		return ERROR;
	}

	OCIAttrSet((dvoid *)(dbc->oraclesvc), OCI_HTYPE_SVCCTX, (dvoid *)(dbc->oraclesrv),
			(ub4)0,OCI_ATTR_SERVER, (dbc->errhp));

	OCIHandleAlloc((dvoid *)(dbc->oracleenv), (dvoid **)&(dbc->oracleusr), OCI_HTYPE_SESSION, 0 , (dvoid **)0);
	OCIAttrSet((dvoid *)(dbc->oracleusr), OCI_HTYPE_SESSION, (dvoid *)oracle_user, (ub4)strlen(oracle_user),
			OCI_ATTR_USERNAME, (dbc->errhp));
	OCIAttrSet((dvoid *)(dbc->oracleusr), OCI_HTYPE_SESSION, (dvoid *)oracle_pass, (ub4)strlen(oracle_pass),
			OCI_ATTR_PASSWORD, (dbc->errhp));

	OCIERROR((dbc->errhp), OCISessionBegin((dbc->oraclesvc), (dbc->errhp), (dbc->oracleusr), OCI_CRED_RDBMS, OCI_DEFAULT));

	OCIAttrSet((dbc->oraclesvc), OCI_HTYPE_SVCCTX, (dbc->oracleusr), 0, OCI_ATTR_SESSION, (dbc->errhp));

	if ( (rc = init_delivery_txn (dbc)) != OK ) {
		LOG_ERROR_MESSAGE("Delivery context initialization failed");
		return ERROR;
	}
	if ( (rc = init_integrity_txn (dbc)) != OK ) {
		LOG_ERROR_MESSAGE("Integrity context initialization failed");
		return ERROR;
	}
	if ( (rc = init_nord_txn (dbc)) != OK ) {
		LOG_ERROR_MESSAGE("Neworder context initialization failed");
		return ERROR;
	}
	if ( (rc = init_order_status_txn (dbc)) != OK ) {
		LOG_ERROR_MESSAGE("Orderstatus context initialization failed");
		return ERROR;
	}
	if ( (rc = init_payment_txn (dbc)) != OK ) {
		LOG_ERROR_MESSAGE("Payment context initialization failed");
		return ERROR;
	}
	if ( (rc = init_stock_level_txn (dbc)) != OK ) {
		LOG_ERROR_MESSAGE("Stocklevel context initialization failed");
		return ERROR;
	}

	return OK;
}

/* Disconnect from the database and free the connection handle. */
int _disconnect_from_db(struct db_context_t *dbc)
{
	if (dbc->dctx) {
		free(dbc->dctx);
		//LOG_ERROR_MESSAGE("Freed dctx");
	}
	if (dbc->ictx) {
		free(dbc->ictx);
		//LOG_ERROR_MESSAGE("Freed ictx");
	}
	if (dbc->nctx) {
		free(dbc->nctx);
		//LOG_ERROR_MESSAGE("Freed nctx");
	}
	if (dbc->octx) {
		free(dbc->octx);
		//LOG_ERROR_MESSAGE("Freed octx");
	}
	if (dbc->pctx) {
		free(dbc->pctx);
		//LOG_ERROR_MESSAGE("Freed pctx");
	}
	if (dbc->sctx) {
		free(dbc->sctx);
		//LOG_ERROR_MESSAGE("Freed sctx");
	}

	OCIERROR(dbc->errhp,OCISessionEnd ( dbc->oraclesvc,dbc->errhp, dbc->oracleusr, OCI_DEFAULT));
	OCIERROR(dbc->errhp,OCIServerDetach ( dbc->oraclesrv, dbc->errhp, OCI_DEFAULT));
	OCIHandleFree((dvoid *)(dbc->oracleusr), OCI_HTYPE_SESSION);
	OCIHandleFree((dvoid *)(dbc->oraclesvc), OCI_HTYPE_SVCCTX);
	OCIHandleFree((dvoid *)(dbc->errhp), OCI_HTYPE_ERROR);
	OCIHandleFree((dvoid *)(dbc->oraclesrv), OCI_HTYPE_SERVER);
	OCIHandleFree((dvoid *)(dbc->oracleenv), OCI_HTYPE_ENV);

	return OK;
}

int _db_init(char * _oracle_dbname, char *_oracle_host, char * _oracle_user, 
             char * _oracle_pass, char * _oracle_port)
{
	/* Copy values only if it's not NULL. */
	if (_oracle_dbname != NULL) {
		strcpy(oracle_dbname, _oracle_dbname);
	}
	if (_oracle_host != NULL) {
		strcpy(oracle_host, _oracle_host);
       	}
	if (_oracle_user != NULL) {
		strcpy(oracle_user, _oracle_user);
       	}
	if (_oracle_pass != NULL) {
		strcpy(oracle_pass, _oracle_pass);
	}
	if (_oracle_port != NULL) {
		strcpy(oracle_port_t, _oracle_port);
	}
	/*if (_oracle_socket != NULL) {
		strcpy(oracle_socket_t, _oracle_socket);
	}*/
	return OK;
}

int rollback_transaction(struct db_context_t *dbc)
{
	OCITransRollback(dbc->oraclesvc,dbc->errhp,OCI_DEFAULT);
	return STATUS_ROLLBACK;
}

int ocierror(fname, lineno, errhp, status)
char *fname;
int lineno;
OCIError *errhp;
sword status;
{
  text errbuf[512];
  sb4 errcode;
  sb4 lstat;
  ub4 recno=2;

  switch (status) {
  case OCI_SUCCESS:
    break;
  case OCI_SUCCESS_WITH_INFO:
    fprintf(stderr,"Module %s Line %d\n", fname, lineno);
    fprintf(stderr,"Error - OCI_SUCCESS_WITH_INFO\n");
    lstat = OCIErrorGet (errhp, recno++, (text *) NULL, &errcode, errbuf,
                           (ub4) sizeof(errbuf), OCI_HTYPE_ERROR);
    fprintf(stderr,"Error - %s\n", errbuf);
    break;
  case OCI_NEED_DATA:
    fprintf(stderr,"Module %s Line %d\n", fname, lineno);
    fprintf(stderr,"Error - OCI_NEED_DATA\n");
    return (IRRECERR);
  case OCI_NO_DATA:
    fprintf(stderr,"Module %s Line %d\n", fname, lineno);
    fprintf(stderr,"Error - OCI_NO_DATA\n");
    return (IRRECERR);
  case OCI_ERROR:
    lstat = OCIErrorGet (errhp, (ub4) 1,
                   (text *) NULL, &errcode, errbuf,
                        (ub4) sizeof(errbuf), OCI_HTYPE_ERROR);
    if (errcode == NOT_SERIALIZABLE) return (errcode);
    if (errcode == SNAPSHOT_TOO_OLD) return (errcode);
    if (errcode == NOT_SAFE_REPLAY) return (errcode);
    if (errcode == COLUMN_VALUE_NULL) return (errcode);
    while (lstat != OCI_NO_DATA)
    {
      fprintf(stderr,"Module %s Line %d\n", fname, lineno);
      fprintf(stderr,"Error - %s\n", errbuf);
      lstat = OCIErrorGet (errhp, recno++, (text *) NULL, &errcode, errbuf,
                           (ub4) sizeof(errbuf), OCI_HTYPE_ERROR);
    }
    return (errcode);
  case OCI_INVALID_HANDLE:
    fprintf(stderr,"Module %s Line %d\n", fname, lineno);
   fprintf(stderr,"Error - OCI_INVALID_HANDLE\n");
    exit(-1);
  case OCI_STILL_EXECUTING:
    fprintf(stderr,"Module %s Line %d\n", fname, lineno);
    fprintf(stderr,"Error - OCI_STILL_EXECUTE\n");
    return (IRRECERR);
  case OCI_CONTINUE:
    fprintf(stderr,"Module %s Line %d\n", fname, lineno);
    fprintf(stderr,"Error - OCI_CONTINUE\n");
    return (IRRECERR);
  default:
    fprintf(stderr,"Module %s Line %d\n", fname, lineno);
    fprintf(stderr,"Status - %s\n", (char *)status);
    return (IRRECERR);
  }
  return (RECOVERR);
}

