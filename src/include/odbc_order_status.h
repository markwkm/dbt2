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

#ifndef _ODBC_ORDER_STATUS_H_
#define _ODBC_ORDER_STATUS_H_

#include "db.h"

#ifndef ORACLEODBC
#define STMT_ORDER_STATUS                                                      \
  "CALL order_status (?, ?, ?, "                                               \
  "?, ?, ?, "                                                                  \
  "?, ?, ?, "                                                                  \
  "?, ?, "                                                                     \
  "?, ?, ?, ?, ?, "                                                            \
  "?, ?, ?, ?, ?, "                                                            \
  "?, ?, ?, ?, ?, "                                                            \
  "?, ?, ?, ?, ?, "                                                            \
  "?, ?, ?, ?, ?, "                                                            \
  "?, ?, ?, ?, ?, "                                                            \
  "?, ?, ?, ?, ?, "                                                            \
  "?, ?, ?, ?, ?, "                                                            \
  "?, ?, ?, ?, ?, "                                                            \
  "?, ?, ?, ?, ?, "                                                            \
  "?, ?, ?, ?, ?, "                                                            \
  "?, ?, ?, ?, ?, "                                                            \
  "?, ?, ?, ?, ?, "                                                            \
  "?, ?, ?, ?, ?, "                                                            \
  "?, ?, ?, ?, ?)"
#else
#define STMT_ORDER_STATUS \
	"CALL order_status (?, ?, ?, ?)"
#endif /* ORACLEODBC */

int execute_order_status(struct db_context_t *odbcc,
                         struct order_status_t *data);
int init_order_status_txn (struct db_context_t *odbcc);

#endif /* _ODBC_ORDER_STATUS_H_ */
