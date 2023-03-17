/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 *
 * Based on TPC-C Standard Specification Revision 5.0.
 *
 * Modified			dd/mm/yyyy
 * anurag.vora@oracle.com	02/Sep/2006	Remove extra parameters
 *						by putting ORACLEODBC flag
 */

#ifndef _ODBC_PAYMENT_H_
#define _ODBC_PAYMENT_H_

#include "db.h"

#ifndef ORACLEODBC
#define STMT_PAYMENT                                                           \
  "CALL payment (?, ?, ?, ?, ?, ?, ?,"                                         \
  "?, ?, ?, ?, ?, ?, "                                                         \
  "?, ?, ?, ?, ?, ?, "                                                         \
  "?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
#else
#define STMT_PAYMENT \
	"CALL payment (?, ?, ?, ?, ?, ?, ?)"
#endif /* ORACLEODBC */

int execute_payment(struct db_context_t *odbcc, struct payment_t *data);
int init_payment_txn (struct db_context_t *odbcc);

#endif /* _ODBC_PAYMENT_H_ */
