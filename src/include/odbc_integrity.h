/*
 * This file is released under the terms of the Artistic License.
 * Please see the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 *
 * Based on TPC-C Standard Specification Revision 5.0.
 */

#ifndef _ODBC_INTEGRITY_H_
#define _ODBC_INTEGRITY_H_

#include "db.h"

int execute_integrity(struct db_context_t *dbc, struct integrity_t *data);

#endif /* _ODBC_INTEGRITY_H_ */
