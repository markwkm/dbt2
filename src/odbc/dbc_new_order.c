/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 *
 * Based on TPC-C Standard Specification Revision 5.0.
 */

#include <odbc_new_order.h>

#ifdef ORACLEODBC
struct nordctx {
	int w_id;
	float w_tax;

	int d_id;
	int c_id;
	int o_all_local;
	int o_ol_cnt;

	int ol_i_id[O_OL_CNT_MAX];
	int ol_supply_w_id[O_OL_CNT_MAX];
	int ol_quantity[O_OL_CNT_MAX];

	SQLHSTMT curn1;
};

typedef struct nordctx nordctx;

int init_nord_txn (struct db_context_t *odbcc)
 {
 	SQLRETURN rc;
 	int i = 1;
 	int j;
 
	odbcc->nctx = (nordctx*) malloc(sizeof(nordctx));

	if (odbcc->nctx == NULL)
		return ERROR;

	/* allocate statement handle */
	rc = SQLAllocHandle(SQL_HANDLE_STMT, odbcc->hdbc, &odbcc->nctx->curn1);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->nctx->curn1);
		return ERROR;
	}

	/* Perpare statement for New Order transaction. */
	rc = SQLPrepare(odbcc->nctx->curn1, (SQLCHAR *)STMT_NEW_ORDER, SQL_NTS);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->nctx->curn1);
		return ERROR;
	}

	/* Bind variables for New Order transaction. */
	rc = SQLBindParameter(odbcc->nctx->curn1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->nctx->w_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->nctx->curn1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->nctx->curn1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->nctx->d_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->nctx->curn1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->nctx->curn1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->nctx->c_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->nctx->curn1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->nctx->curn1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->nctx->o_all_local, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->nctx->curn1);
		return ERROR;
	}
	rc = SQLBindParameter(odbcc->nctx->curn1,
		i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
		&odbcc->nctx->o_ol_cnt, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->nctx->curn1);
		return ERROR;
	}
	for (j = 0; j < O_OL_CNT_MAX; j++) {
		rc = SQLBindParameter(odbcc->nctx->curn1,
			i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
			&odbcc->nctx->ol_i_id[j], 0, NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->nctx->curn1);
			return ERROR;
		}
		rc = SQLBindParameter(odbcc->nctx->curn1,
			i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
			&odbcc->nctx->ol_supply_w_id[j], 0, NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->nctx->curn1);
			return ERROR;
		}
		rc = SQLBindParameter(odbcc->nctx->curn1,
			i++, SQL_PARAM_INPUT, SQL_C_SLONG, SQL_INTEGER, 0, 0,
			&odbcc->nctx->ol_quantity[j], 0, NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->nctx->curn1);
			return ERROR;
		}
	}

	return OK;
}
#endif /* ORACLEODBC */

int execute_new_order(struct db_context_t *odbcc, struct new_order_t *data) {
	SQLRETURN rc;
	int i = 1;
	int j=0;

#ifdef ORACLEODBC
	/* Input variables. */
	odbcc->nctx->w_id = data->w_id;
	odbcc->nctx->d_id = data->d_id;
	odbcc->nctx->c_id = data->c_id;
	odbcc->nctx->o_all_local = data->o_all_local;
	odbcc->nctx->o_ol_cnt = data->o_ol_cnt;

	/* Loop through the last set of parameters. */
	for (j=0; j < O_OL_CNT_MAX; j++) {
		odbcc->nctx->ol_i_id[j] = data->order_line[j].ol_i_id;
		odbcc->nctx->ol_supply_w_id[j] = data->order_line[j].ol_supply_w_id;
		odbcc->nctx->ol_quantity[j] = data->order_line[j].ol_quantity;
	}
#else
	/* Perpare statement for New Order transaction. */
	rc = SQLPrepare(
			odbcc->library.odbc.hstmt, (unsigned char *) STMT_NEW_ORDER,
			SQL_NTS);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}

	/* Bind variables for New Order transaction. */
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->w_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->d_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->c_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->o_all_local, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->o_ol_cnt, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	for (j = 0; j < O_OL_CNT_MAX; j++) {
		rc = SQLBindParameter(
				odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
				SQL_INTEGER, 0, 0, &data->order_line[j].ol_i_id, 0, NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
			return ERROR;
		}
		rc = SQLBindParameter(
				odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
				SQL_INTEGER, 0, 0, &data->order_line[j].ol_supply_w_id, 0,
				NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
			return ERROR;
		}
		rc = SQLBindParameter(
				odbcc->library.odbc.hstmt, i++, SQL_PARAM_INPUT, SQL_C_SLONG,
				SQL_INTEGER, 0, 0, &data->order_line[j].ol_quantity, 0, NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
			return ERROR;
		}
		rc = SQLBindParameter(
				odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
				SQL_VARCHAR, 0, 0, data->order_line[j].i_name,
				sizeof(data->order_line[j].i_name), NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
			return ERROR;
		}
		rc = SQLBindParameter(
				odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_DOUBLE,
				SQL_DOUBLE, 0, 0, &data->order_line[j].i_price, 0, NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
			return ERROR;
		}
		rc = SQLBindParameter(
				odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_SLONG,
				SQL_INTEGER, 0, 0, &data->order_line[j].s_quantity, 0, NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
			return ERROR;
		}
		rc = SQLBindParameter(
				odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_DOUBLE,
				SQL_DOUBLE, 0, 0, &data->order_line[j].ol_amount, 0, NULL);
		if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
			LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
			return ERROR;
		}
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->o_id, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_DOUBLE,
			SQL_DOUBLE, 0, 0, &data->total_amount, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_DOUBLE,
			SQL_DOUBLE, 0, 0, &data->w_tax, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_DOUBLE,
			SQL_DOUBLE, 0, 0, &data->d_tax, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->c_last, sizeof(data->c_last), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_CHAR,
			SQL_VARCHAR, 0, 0, data->c_credit, sizeof(data->c_credit), NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_DOUBLE,
			SQL_DOUBLE, 0, 0, &data->c_discount, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
	rc = SQLBindParameter(
			odbcc->library.odbc.hstmt, i++, SQL_PARAM_OUTPUT, SQL_C_SLONG,
			SQL_INTEGER, 0, 0, &data->rollback, 0, NULL);
	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}
#endif /* ORACLEODBC */

	/* Execute stored procedure. */
	rc = SQLExecute(odbcc->library.odbc.hstmt);
	if (check_odbc_rc(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt, rc) ==
		ERROR) {
		LOG_ODBC_ERROR(SQL_HANDLE_STMT, odbcc->library.odbc.hstmt);
		return ERROR;
	}

	return OK;
}
