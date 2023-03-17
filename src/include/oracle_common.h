/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *  
 * Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
 * 02 September 2006
 *
 * Modified			dd/mm/yyyy
 * anurag.vora@oracle.com	21/sep/2006	Handle failover condition
 */

#ifndef _ORACLE_COMMON_H_
#define _ORACLE_COMMON_H_

#include "common.h"
#include "logging.h"
#include "transaction_data.h"

#include <oci.h>
#include <string.h>

#define ADR(object) ((ub1 *)&(object))
#define SIZ(object) ((sword)sizeof(object))

#define OCIERROR(errp,function)\
	ocierror(__FILE__,__LINE__,(errp),(function));

#define OCIBND(stmp, bndp, errp, sqlvar, progv, progvl, ftype)\
	ocierror(__FILE__,__LINE__,(errp), \
		OCIHandleAlloc((stmp),(dvoid**)&(bndp),OCI_HTYPE_BIND,0,(dvoid**)0)); \
	ocierror(__FILE__,__LINE__, (errp), \
		OCIBindByName((stmp), &(bndp), (errp), \
			(text *)(sqlvar), strlen((sqlvar)),\
			(progv), (progvl), (ftype),0,0,0,0,0,OCI_DEFAULT));

#define OCIBNDRA(stmp,bndp,errp,sqlvar,progv,progvl,ftype,indp,alen,arcode) \
	ocierror(__FILE__,__LINE__,(errp), \
		OCIHandleAlloc((stmp),(dvoid**)&(bndp),OCI_HTYPE_BIND,0,(dvoid**)0)); \
	ocierror(__FILE__,__LINE__,(errp), \
		OCIBindByName((stmp),&(bndp),(errp),(text *)(sqlvar),strlen((sqlvar)),\
			(progv),(progvl),(ftype),(indp),(alen),(arcode),0,0,OCI_DEFAULT));

#define OCIDEFINE(stmp,dfnp,errp,pos,progv,progvl,ftype)\
	OCIDefineByPos((stmp),&(dfnp),(errp),(pos),(progv),(progvl),(ftype),\
			0,0,0,OCI_DEFAULT);

#define RECOVERR -10
#define IRRECERR -20
#define NOT_SERIALIZABLE  8177  /* ORA-08177: transaction not serializable */
#define SNAPSHOT_TOO_OLD  1555  /* ORA-01555: snapshot too old */
#define NOT_SAFE_REPLAY   25408 /* ORA-25408: can not safely replay call */
#define COLUMN_VALUE_NULL   1405  /* ORA-01405: fetched column value is NULL */

extern char oracle_dbname[32];
extern char oracle_host[128];
extern char oracle_port_t[32];
extern char oracle_user[32];
extern char oracle_pass[32];
extern char oracle_socket_t[256];

extern struct deliveryctx dctx;
extern struct integrityctx ictx;
extern struct nordctx nctx;
extern struct ordstatusctx octx;
extern struct paymentctx pctx;
extern struct stockctx sctx;

struct db_context_t {
	OCIEnv *oracleenv;
	OCIServer *oraclesrv;
	OCIError *errhp;
	OCISvcCtx *oraclesvc;
	OCISession *oracleusr;

	struct deliveryctx  *dctx;
	struct integrityctx *ictx;
	struct nordctx      *nctx;
	struct ordstatusctx *octx;
	struct paymentctx   *pctx;
	struct stockctx     *sctx;
};

extern int ocierror(char *fname, int lineno, OCIError *errhp, sword status);

int commit_transaction(struct db_context_t *dbc);
int _connect_to_db(struct db_context_t *dbc);
int _disconnect_from_db(struct db_context_t *dbc);
int _db_init(char *_oracle_dbname, char *_oracle_host, char * _oracle_user, char * _oracle_pass, 
             char *_oracle_port);
int rollback_transaction(struct db_context_t *dbc);

#endif /* _ORACLE_COMMON_H_ */
