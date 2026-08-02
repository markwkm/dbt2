--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
--
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- Copyright The DBT-2 Authors
--
-- Based on TPC-C Standard Specification Revision 5.11 Clause 2.8.2.
--

CREATE OR REPLACE PROCEDURE stock_level(in_w_id      district.d_w_id%TYPE,
					in_d_id      district.d_id%TYPE,
					in_threshold stock.s_quantity%TYPE,
					low_stock    OUT INTEGER) AS

	tmp_d_next_o_id district.d_next_o_id%TYPE;

BEGIN

	SELECT d_next_o_id
	INTO tmp_d_next_o_id
	FROM district
	WHERE d_w_id = in_w_id
		AND d_id = in_d_id;

	SELECT count(*)
	INTO low_stock
	FROM (SELECT DISTINCT ol_i_id
		FROM order_line
		WHERE ol_w_id = in_w_id
			AND ol_d_id = in_d_id
			AND ol_o_id BETWEEN (tmp_d_next_o_id - 20)
					AND (tmp_d_next_o_id - 1)) ol, stock
	WHERE s_w_id = in_w_id
		AND s_i_id = ol.ol_i_id
		AND s_quantity < in_threshold;

END;
/
