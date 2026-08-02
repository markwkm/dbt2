/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
 * Copyright The DBT-2 Authors
 *
 * 02 September 2006
 */

#ifndef _ORACLE_COMMON_H_
#define _ORACLE_COMMON_H_

#include <oci.h>

#define ORACLE_DBNAME_LEN 255
#define ORACLE_USER_LEN 31
#define ORACLE_PASS_LEN 31

#define ADR(object) ((ub1 *) &(object))
#define SIZ(object) ((sword) sizeof(object))

#define OCIERROR(errp, function)                                               \
	ocierror(__FILE__, __LINE__, (errp), (function));

#define OCIBND(stmp, bndp, errp, sqlvar, progv, progvl, ftype)                 \
	ocierror(                                                                  \
			__FILE__, __LINE__, (errp),                                        \
			OCIHandleAlloc(                                                    \
					(stmp), (dvoid **) &(bndp), OCI_HTYPE_BIND, 0,             \
					(dvoid **) 0));                                            \
	ocierror(                                                                  \
			__FILE__, __LINE__, (errp),                                        \
			OCIBindByName(                                                     \
					(stmp), &(bndp), (errp), (text *) (sqlvar),                \
					strlen((sqlvar)), (progv), (progvl), (ftype), 0, 0, 0, 0,  \
					0, OCI_DEFAULT));

#define OCIBNDRA(                                                              \
		stmp, bndp, errp, sqlvar, progv, progvl, ftype, indp, alen, arcode)    \
	ocierror(                                                                  \
			__FILE__, __LINE__, (errp),                                        \
			OCIHandleAlloc(                                                    \
					(stmp), (dvoid **) &(bndp), OCI_HTYPE_BIND, 0,             \
					(dvoid **) 0));                                            \
	ocierror(                                                                  \
			__FILE__, __LINE__, (errp),                                        \
			OCIBindByName(                                                     \
					(stmp), &(bndp), (errp), (text *) (sqlvar),                \
					strlen((sqlvar)), (progv), (progvl), (ftype), (indp),      \
					(alen), (arcode), 0, 0, OCI_DEFAULT));

#define OCIDEFINE(stmp, dfnp, errp, pos, progv, progvl, ftype)                 \
	OCIDefineByPos(                                                            \
			(stmp), &(dfnp), (errp), (pos), (progv), (progvl), (ftype), 0, 0,  \
			0, OCI_DEFAULT);

#define RECOVERR -10
#define IRRECERR -20
#define NOT_SERIALIZABLE 8177  /* ORA-08177: transaction not serializable */
#define SNAPSHOT_TOO_OLD 1555  /* ORA-01555: snapshot too old */
#define NOT_SAFE_REPLAY 25408  /* ORA-25408: can not safely replay call */
#define COLUMN_VALUE_NULL 1405 /* ORA-01405: fetched column value is NULL */

/* Per-transaction contexts, defined in the respective src/oracle files. */
struct deliveryctx;
struct integrityctx;
struct nordctx;
struct ordstatusctx;
struct paymentctx;
struct stockctx;

struct db_context_oracle {
	OCIEnv *oracleenv;
	OCIServer *oraclesrv;
	OCIError *errhp;
	OCISvcCtx *oraclesvc;
	OCISession *oracleusr;

	struct deliveryctx *dctx;
	struct integrityctx *ictx;
	struct nordctx *nctx;
	struct ordstatusctx *octx;
	struct paymentctx *pctx;
	struct stockctx *sctx;

	/* Connect identifier: EZConnect string or tnsnames.ora alias. */
	char dbname[ORACLE_DBNAME_LEN + 1];
	char user[ORACLE_USER_LEN + 1];
	char pass[ORACLE_PASS_LEN + 1];
};

int ocierror(char *fname, int lineno, OCIError *errhp, sword status);

#endif /* _ORACLE_COMMON_H_ */
