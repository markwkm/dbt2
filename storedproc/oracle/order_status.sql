--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
--
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- Copyright The DBT-2 Authors
--
-- Based on TPC-C Standard Specification Revision 5.11 Clause 2.6.2.
--

CREATE OR REPLACE PROCEDURE order_status (in_c_id   customer.c_id%TYPE,
					in_c_w_id customer.c_w_id%TYPE,
					in_c_d_id customer.c_d_id%TYPE,
					in_c_last customer.c_last%TYPE) AS

	out_c_id      customer.c_id%TYPE;
	out_c_first   customer.c_first%TYPE;
	out_c_middle  customer.c_middle%TYPE;
	out_c_last    customer.c_last%TYPE;
	out_c_balance customer.c_balance%TYPE;

	out_o_id         orders.o_id%TYPE;
	out_o_carrier_id orders.o_carrier_id%TYPE;
	out_o_entry_d    orders.o_entry_d%TYPE;
	out_o_ol_cnt     orders.o_ol_cnt%TYPE;

	out_ol_i_id        order_line.ol_i_id%TYPE;
	out_ol_supply_w_id order_line.ol_supply_w_id%TYPE;
	out_ol_quantity    order_line.ol_quantity%TYPE;
	out_ol_amount      order_line.ol_amount%TYPE;
	out_ol_delivery_d  order_line.ol_delivery_d%TYPE;

	tmp_count INTEGER;

BEGIN

	-- Pick a customer by searching for c_last; take the customer in
	-- the middle, position n / 2 rounded up, of the list sorted by
	-- c_first.
	IF in_c_id = 0 THEN
		SELECT count(*)
		INTO tmp_count
		FROM customer
		WHERE c_w_id = in_c_w_id
			AND c_d_id = in_c_d_id
			AND c_last = in_c_last;

		SELECT c_id
		INTO out_c_id
		FROM (SELECT c_id,
				ROW_NUMBER() OVER (ORDER BY c_first ASC) rn
			FROM customer
			WHERE c_w_id = in_c_w_id
				AND c_d_id = in_c_d_id
				AND c_last = in_c_last)
		WHERE rn = FLOOR((tmp_count + 1) / 2);
	ELSE
		out_c_id := in_c_id;
	END IF;

	SELECT c_first, c_middle, c_last, c_balance
	INTO out_c_first, out_c_middle, out_c_last, out_c_balance
	FROM customer
	WHERE c_w_id = in_c_w_id
		AND c_d_id = in_c_d_id
		AND c_id = out_c_id;

	-- The customer's most recent order.
	SELECT o_id, o_carrier_id, o_entry_d, o_ol_cnt
	INTO out_o_id, out_o_carrier_id, out_o_entry_d, out_o_ol_cnt
	FROM (SELECT o_id, o_carrier_id, o_entry_d, o_ol_cnt
		FROM orders
		WHERE o_w_id = in_c_w_id
			AND o_d_id = in_c_d_id
			AND o_c_id = out_c_id
		ORDER BY o_id DESC)
	WHERE rownum = 1;

	FOR line IN (SELECT ol_i_id, ol_supply_w_id, ol_quantity,
				ol_amount, ol_delivery_d
			FROM order_line
			WHERE ol_w_id = in_c_w_id
				AND ol_d_id = in_c_d_id
				AND ol_o_id = out_o_id)
	LOOP
		out_ol_i_id := line.ol_i_id;
		out_ol_supply_w_id := line.ol_supply_w_id;
		out_ol_quantity := line.ol_quantity;
		out_ol_amount := line.ol_amount;
		out_ol_delivery_d := line.ol_delivery_d;
	END LOOP;

END;
/
