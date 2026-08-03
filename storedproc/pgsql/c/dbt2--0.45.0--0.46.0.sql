/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright The DBT-2 Authors
 */

\echo Use "ALTER EXTENSION dbt2 UPDATE" to load this file. \quit

/*
 * The functions now also return the transaction output data that a
 * TPC-C terminal must display.  Changing the returned columns requires
 * dropping and recreating the functions.
 */

DROP FUNCTION new_order (INTEGER, INTEGER, INTEGER, INTEGER, INTEGER,
    new_order_info, new_order_info, new_order_info, new_order_info,
    new_order_info, new_order_info, new_order_info, new_order_info,
    new_order_info, new_order_info, new_order_info, new_order_info,
    new_order_info, new_order_info, new_order_info);

CREATE FUNCTION new_order (
    w_id INTEGER,
    d_id INTEGER,
    c_id INTEGER,
    o_all_local INTEGER,
    o_ol_cnt INTEGER,
    order_line_1 new_order_info,
    order_line_2 new_order_info,
    order_line_3 new_order_info,
    order_line_4 new_order_info,
    order_line_5 new_order_info,
    order_line_6 new_order_info,
    order_line_7 new_order_info,
    order_line_8 new_order_info,
    order_line_9 new_order_info,
    order_line_10 new_order_info,
    order_line_11 new_order_info,
    order_line_12 new_order_info,
    order_line_13 new_order_info,
    order_line_14 new_order_info,
    order_line_15 new_order_info
) RETURNS TABLE (
    ol_supply_w_id INTEGER,
    ol_i_id INTEGER,
    i_name TEXT,
    ol_quantity INTEGER,
    s_quantity INTEGER,
    i_price REAL,
    ol_amount REAL,
    brand_generic CHAR,
    w_tax REAL,
    d_tax REAL,
    o_id INTEGER,
    c_last TEXT,
    c_credit TEXT,
    c_discount REAL
) AS 'MODULE_PATHNAME', 'new_order'
LANGUAGE C VOLATILE;

DROP FUNCTION order_status (INTEGER, INTEGER, INTEGER, TEXT);

CREATE FUNCTION order_status (
    c_id INTEGER,
    c_w_id INTEGER,
    c_d_id INTEGER,
    c_last TEXT
) RETURNS TABLE (
    ol_i_id INTEGER,
    ol_supply_w_id INTEGER,
    ol_quantity REAL,
    ol_amount REAL,
    ol_delivery_d TEXT,
    out_c_id INTEGER,
    out_c_first TEXT,
    out_c_middle TEXT,
    out_c_last TEXT,
    out_c_balance DOUBLE PRECISION,
    out_o_id INTEGER,
    out_o_carrier_id INTEGER,
    out_o_entry_d TEXT
) AS 'MODULE_PATHNAME', 'order_status'
LANGUAGE C VOLATILE;

DROP FUNCTION payment (INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, TEXT,
    REAL);

CREATE FUNCTION payment (
    w_id INTEGER,
    d_id INTEGER,
    c_id INTEGER,
    c_w_id INTEGER,
    c_d_id INTEGER,
    in_c_last TEXT,
    h_amount REAL
) RETURNS TABLE (
    w_street_1 TEXT,
    w_street_2 TEXT,
    w_city TEXT,
    w_state TEXT,
    w_zip TEXT,
    d_street_1 TEXT,
    d_street_2 TEXT,
    d_city TEXT,
    d_state TEXT,
    d_zip TEXT,
    c_first TEXT,
    c_middle TEXT,
    c_last TEXT,
    c_street_1 TEXT,
    c_street_2 TEXT,
    c_city TEXT,
    c_state TEXT,
    c_zip TEXT,
    c_phone TEXT,
    c_since TEXT,
    c_credit TEXT,
    c_credit_lim DOUBLE PRECISION,
    c_discount REAL,
    c_balance DOUBLE PRECISION,
    c_data TEXT,
    h_date TEXT,
    out_c_id INTEGER,
    w_name TEXT,
    d_name TEXT
) AS 'MODULE_PATHNAME', 'payment'
LANGUAGE C VOLATILE;
