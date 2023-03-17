--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- Based on TPC-C Standard Specification Revision 5.0 
-- /

spool ${WSRLDB}/stock_level.log;
set echo on;

CREATE OR REPLACE PROCEDURE stock_level(in_w_id       district.d_w_id%TYPE,
					in_d_id       district.d_id%TYPE,
					in_threshold  stock.s_quantity%TYPE,
					low_stock     OUT INTEGER) AS

	tmp_d_next_o_id district.d_next_o_id%TYPE;

BEGIN

<<stock_level1>>
	BEGIN
	SELECT d_next_o_id
	INTO tmp_d_next_o_id
	FROM district
	WHERE d_w_id = in_w_id
		AND d_id = in_d_id
		AND rownum < 2;

	EXCEPTION
		WHEN TOO_MANY_ROWS THEN
			DBMS_OUTPUT.PUT_LINE('(1)oops ! more than one row in_w_id = ' || in_w_id || ' in_d_id = ' || in_d_id);
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('(1)no rows in_w_id = ' || in_w_id || ' in_d_id = ' || in_d_id);
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO stock_level1;
			ELSIF SQLCODE = -1555 THEN
				GOTO stock_level1;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_stock_level;
			END IF;
	END;

<<stock_level2>>
	BEGIN
	SELECT count(*)
	INTO low_stock
	FROM order_line, stock, district
	WHERE d_id = in_d_id
		AND d_w_id = in_w_id
		AND d_id = ol_d_id
		AND d_w_id = ol_w_id
		AND ol_i_id = s_i_id
		AND ol_w_id = s_w_id
		AND s_quantity < in_threshold
		AND ol_o_id BETWEEN (tmp_d_next_o_id - 20)
			AND (tmp_d_next_o_id - 1)
			AND rownum < 2;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('(2)no rows in_d_id = ' || in_d_id || ' in_threshold = ' || in_threshold || ' tmp_d_next_o_id ' || tmp_d_next_o_id);
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO stock_level2;
			ELSIF SQLCODE = -1555 THEN
				GOTO stock_level2;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_stock_level;
			END IF;
	END;
<<end_stock_level>>
	NULL;
END;
/
set echo off;
spool off;

exit sql.sqlcode;
