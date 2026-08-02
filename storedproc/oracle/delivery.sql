--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
--
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- Copyright The DBT-2 Authors
--
-- Based on TPC-C Standard Specification Revision 5.11 Clause 2.7.4.
--

CREATE OR REPLACE PROCEDURE delivery (in_w_id         new_order.no_w_id%TYPE,
					in_o_carrier_id orders.o_carrier_id%TYPE) AS

	out_c_id      orders.o_c_id%TYPE;
	out_ol_amount order_line.ol_amount%TYPE;
	tmp_d_id      order_line.ol_d_id%TYPE;
	tmp_o_id      new_order.no_o_id%TYPE;

BEGIN

	tmp_d_id := 1;

	WHILE tmp_d_id <= 10
	LOOP
		-- The oldest undelivered order is the one with the lowest
		-- no_o_id; skip the district if there is none.
		SELECT MIN(no_o_id)
		INTO tmp_o_id
		FROM new_order
		WHERE no_w_id = in_w_id
			AND no_d_id = tmp_d_id;

		IF tmp_o_id IS NOT NULL
		THEN
			DELETE FROM new_order
			WHERE no_o_id = tmp_o_id
				AND no_w_id = in_w_id
				AND no_d_id = tmp_d_id;

			SELECT o_c_id
			INTO out_c_id
			FROM orders
			WHERE o_id = tmp_o_id
				AND o_w_id = in_w_id
				AND o_d_id = tmp_d_id
			FOR UPDATE;

			UPDATE orders
			SET o_carrier_id = in_o_carrier_id
			WHERE o_id = tmp_o_id
				AND o_w_id = in_w_id
				AND o_d_id = tmp_d_id;

			UPDATE order_line
			SET ol_delivery_d = current_timestamp
			WHERE ol_o_id = tmp_o_id
				AND ol_w_id = in_w_id
				AND ol_d_id = tmp_d_id;

			SELECT SUM(ol_amount)
			INTO out_ol_amount
			FROM order_line
			WHERE ol_o_id = tmp_o_id
				AND ol_w_id = in_w_id
				AND ol_d_id = tmp_d_id;

			UPDATE customer
			SET c_delivery_cnt = c_delivery_cnt + 1,
				c_balance = c_balance + out_ol_amount
			WHERE c_id = out_c_id
				AND c_w_id = in_w_id
				AND c_d_id = tmp_d_id;

		END IF;

		tmp_d_id := tmp_d_id + 1;

	END LOOP;

END;
/
