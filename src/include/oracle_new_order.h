/*
 * odbc_new_order.h
 *
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
 *
 * 02 September 2006
 * Based on TPC-C Standard Specification Revision 5.0.
 */

#ifndef _ORACLE_NEW_ORDER_H_
#define _ORACLE_NEW_ORDER_H_

#include <transaction_data.h>
#include <oracle_common.h>

int execute_new_order(struct db_context_t *dbc, struct new_order_t *data);
int init_nord_txn (struct db_context_t *dbc);

#endif /* _ORACLE_NEW_ORDER_H_ */
