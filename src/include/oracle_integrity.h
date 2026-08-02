/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
 * Copyright The DBT-2 Authors
 *
 * Based on TPC-C Standard Specification Revision 5.0.
 */

#ifndef _ORACLE_INTEGRITY_H_
#define _ORACLE_INTEGRITY_H_

#include "db.h"

int execute_integrity_oracle(
		struct db_context_t *dbc, struct integrity_t *data);
int init_integrity_txn_oracle(struct db_context_t *dbc);

#endif /* _ORACLE_INTEGRITY_H_ */
