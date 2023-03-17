/*
 * odbc_order_status.h
 *
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
 *
 * 02 September 2006
 * Based on TPC-C Standard Specification Revision 5.0.
 */

#ifndef _ORACLE_ORDER_STATUS_H_
#define _ORACLE_ORDER_STATUS_H_

#include <transaction_data.h>
#include <oracle_common.h>

int execute_order_status(struct db_context_t *dbc, struct order_status_t *data);
int init_order_status_txn (struct db_context_t *dbc);

#endif /* _ORACLE_ORDER_STATUS_H_ */
