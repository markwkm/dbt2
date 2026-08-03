--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
--
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- Copyright The DBT-2 Authors
--
-- Based on TPC-C Standard Specification Revision 5.11 Clause 2.6.2.
--
-- Output parameters for CHAR columns are declared VARCHAR2: a CHAR
-- OUT parameter is blank padded past the caller's buffer, which the
-- OCI caller receives as a truncated value with the indicator set.
--

CREATE OR REPLACE PROCEDURE order_status (in_c_id   customer.c_id%TYPE,
					in_c_w_id customer.c_w_id%TYPE,
					in_c_d_id customer.c_d_id%TYPE,
					in_c_last customer.c_last%TYPE,
					out_c_id      OUT customer.c_id%TYPE,
					out_c_first   OUT customer.c_first%TYPE,
					out_c_middle  OUT VARCHAR2,
					out_c_last    OUT customer.c_last%TYPE,
					out_c_balance OUT customer.c_balance%TYPE,
					out_o_id         OUT orders.o_id%TYPE,
					out_o_carrier_id OUT orders.o_carrier_id%TYPE,
					out_o_entry_d    OUT VARCHAR2,
					out_ol_i_id1        OUT order_line.ol_i_id%TYPE,
					out_ol_i_id2        OUT order_line.ol_i_id%TYPE,
					out_ol_i_id3        OUT order_line.ol_i_id%TYPE,
					out_ol_i_id4        OUT order_line.ol_i_id%TYPE,
					out_ol_i_id5        OUT order_line.ol_i_id%TYPE,
					out_ol_i_id6        OUT order_line.ol_i_id%TYPE,
					out_ol_i_id7        OUT order_line.ol_i_id%TYPE,
					out_ol_i_id8        OUT order_line.ol_i_id%TYPE,
					out_ol_i_id9        OUT order_line.ol_i_id%TYPE,
					out_ol_i_id10       OUT order_line.ol_i_id%TYPE,
					out_ol_i_id11       OUT order_line.ol_i_id%TYPE,
					out_ol_i_id12       OUT order_line.ol_i_id%TYPE,
					out_ol_i_id13       OUT order_line.ol_i_id%TYPE,
					out_ol_i_id14       OUT order_line.ol_i_id%TYPE,
					out_ol_i_id15       OUT order_line.ol_i_id%TYPE,
					out_ol_supply_w_id1  OUT order_line.ol_supply_w_id%TYPE,
					out_ol_supply_w_id2  OUT order_line.ol_supply_w_id%TYPE,
					out_ol_supply_w_id3  OUT order_line.ol_supply_w_id%TYPE,
					out_ol_supply_w_id4  OUT order_line.ol_supply_w_id%TYPE,
					out_ol_supply_w_id5  OUT order_line.ol_supply_w_id%TYPE,
					out_ol_supply_w_id6  OUT order_line.ol_supply_w_id%TYPE,
					out_ol_supply_w_id7  OUT order_line.ol_supply_w_id%TYPE,
					out_ol_supply_w_id8  OUT order_line.ol_supply_w_id%TYPE,
					out_ol_supply_w_id9  OUT order_line.ol_supply_w_id%TYPE,
					out_ol_supply_w_id10 OUT order_line.ol_supply_w_id%TYPE,
					out_ol_supply_w_id11 OUT order_line.ol_supply_w_id%TYPE,
					out_ol_supply_w_id12 OUT order_line.ol_supply_w_id%TYPE,
					out_ol_supply_w_id13 OUT order_line.ol_supply_w_id%TYPE,
					out_ol_supply_w_id14 OUT order_line.ol_supply_w_id%TYPE,
					out_ol_supply_w_id15 OUT order_line.ol_supply_w_id%TYPE,
					out_ol_quantity1  OUT order_line.ol_quantity%TYPE,
					out_ol_quantity2  OUT order_line.ol_quantity%TYPE,
					out_ol_quantity3  OUT order_line.ol_quantity%TYPE,
					out_ol_quantity4  OUT order_line.ol_quantity%TYPE,
					out_ol_quantity5  OUT order_line.ol_quantity%TYPE,
					out_ol_quantity6  OUT order_line.ol_quantity%TYPE,
					out_ol_quantity7  OUT order_line.ol_quantity%TYPE,
					out_ol_quantity8  OUT order_line.ol_quantity%TYPE,
					out_ol_quantity9  OUT order_line.ol_quantity%TYPE,
					out_ol_quantity10 OUT order_line.ol_quantity%TYPE,
					out_ol_quantity11 OUT order_line.ol_quantity%TYPE,
					out_ol_quantity12 OUT order_line.ol_quantity%TYPE,
					out_ol_quantity13 OUT order_line.ol_quantity%TYPE,
					out_ol_quantity14 OUT order_line.ol_quantity%TYPE,
					out_ol_quantity15 OUT order_line.ol_quantity%TYPE,
					out_ol_amount1  OUT order_line.ol_amount%TYPE,
					out_ol_amount2  OUT order_line.ol_amount%TYPE,
					out_ol_amount3  OUT order_line.ol_amount%TYPE,
					out_ol_amount4  OUT order_line.ol_amount%TYPE,
					out_ol_amount5  OUT order_line.ol_amount%TYPE,
					out_ol_amount6  OUT order_line.ol_amount%TYPE,
					out_ol_amount7  OUT order_line.ol_amount%TYPE,
					out_ol_amount8  OUT order_line.ol_amount%TYPE,
					out_ol_amount9  OUT order_line.ol_amount%TYPE,
					out_ol_amount10 OUT order_line.ol_amount%TYPE,
					out_ol_amount11 OUT order_line.ol_amount%TYPE,
					out_ol_amount12 OUT order_line.ol_amount%TYPE,
					out_ol_amount13 OUT order_line.ol_amount%TYPE,
					out_ol_amount14 OUT order_line.ol_amount%TYPE,
					out_ol_amount15 OUT order_line.ol_amount%TYPE,
					out_ol_delivery_d1  OUT VARCHAR2,
					out_ol_delivery_d2  OUT VARCHAR2,
					out_ol_delivery_d3  OUT VARCHAR2,
					out_ol_delivery_d4  OUT VARCHAR2,
					out_ol_delivery_d5  OUT VARCHAR2,
					out_ol_delivery_d6  OUT VARCHAR2,
					out_ol_delivery_d7  OUT VARCHAR2,
					out_ol_delivery_d8  OUT VARCHAR2,
					out_ol_delivery_d9  OUT VARCHAR2,
					out_ol_delivery_d10 OUT VARCHAR2,
					out_ol_delivery_d11 OUT VARCHAR2,
					out_ol_delivery_d12 OUT VARCHAR2,
					out_ol_delivery_d13 OUT VARCHAR2,
					out_ol_delivery_d14 OUT VARCHAR2,
					out_ol_delivery_d15 OUT VARCHAR2) AS

	TYPE t_number_list IS VARRAY(15) OF NUMBER;
	TYPE t_string_list IS VARRAY(15) OF VARCHAR2(28);

	a_ol_i_id t_number_list := t_number_list();
	a_ol_supply_w_id t_number_list := t_number_list();
	a_ol_quantity t_number_list := t_number_list();
	a_ol_amount t_number_list := t_number_list();
	a_ol_delivery_d t_string_list := t_string_list();

	out_o_ol_cnt orders.o_ol_cnt%TYPE;

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
	SELECT o_id, NVL(o_carrier_id, 0),
		TO_CHAR(o_entry_d, 'YYYY-MM-DD HH24:MI:SS'), o_ol_cnt
	INTO out_o_id, out_o_carrier_id, out_o_entry_d, out_o_ol_cnt
	FROM (SELECT o_id, o_carrier_id, o_entry_d, o_ol_cnt
		FROM orders
		WHERE o_w_id = in_c_w_id
			AND o_d_id = in_c_d_id
			AND o_c_id = out_c_id
		ORDER BY o_id DESC)
	WHERE rownum = 1;

	FOR line IN (SELECT ol_i_id, ol_supply_w_id, ol_quantity,
				ol_amount,
				TO_CHAR(ol_delivery_d,
					'YYYY-MM-DD HH24:MI:SS') ol_delivery_d
			FROM order_line
			WHERE ol_w_id = in_c_w_id
				AND ol_d_id = in_c_d_id
				AND ol_o_id = out_o_id)
	LOOP
		a_ol_i_id.EXTEND;
		a_ol_i_id(a_ol_i_id.COUNT) := line.ol_i_id;
		a_ol_supply_w_id.EXTEND;
		a_ol_supply_w_id(a_ol_supply_w_id.COUNT) := line.ol_supply_w_id;
		a_ol_quantity.EXTEND;
		a_ol_quantity(a_ol_quantity.COUNT) := line.ol_quantity;
		a_ol_amount.EXTEND;
		a_ol_amount(a_ol_amount.COUNT) := line.ol_amount;
		a_ol_delivery_d.EXTEND;
		a_ol_delivery_d(a_ol_delivery_d.COUNT) := line.ol_delivery_d;
	END LOOP;

	IF a_ol_i_id.COUNT >= 1 THEN
		out_ol_i_id1 := a_ol_i_id(1);
		out_ol_supply_w_id1 := a_ol_supply_w_id(1);
		out_ol_quantity1 := a_ol_quantity(1);
		out_ol_amount1 := a_ol_amount(1);
		out_ol_delivery_d1 := a_ol_delivery_d(1);
	END IF;
	IF a_ol_i_id.COUNT >= 2 THEN
		out_ol_i_id2 := a_ol_i_id(2);
		out_ol_supply_w_id2 := a_ol_supply_w_id(2);
		out_ol_quantity2 := a_ol_quantity(2);
		out_ol_amount2 := a_ol_amount(2);
		out_ol_delivery_d2 := a_ol_delivery_d(2);
	END IF;
	IF a_ol_i_id.COUNT >= 3 THEN
		out_ol_i_id3 := a_ol_i_id(3);
		out_ol_supply_w_id3 := a_ol_supply_w_id(3);
		out_ol_quantity3 := a_ol_quantity(3);
		out_ol_amount3 := a_ol_amount(3);
		out_ol_delivery_d3 := a_ol_delivery_d(3);
	END IF;
	IF a_ol_i_id.COUNT >= 4 THEN
		out_ol_i_id4 := a_ol_i_id(4);
		out_ol_supply_w_id4 := a_ol_supply_w_id(4);
		out_ol_quantity4 := a_ol_quantity(4);
		out_ol_amount4 := a_ol_amount(4);
		out_ol_delivery_d4 := a_ol_delivery_d(4);
	END IF;
	IF a_ol_i_id.COUNT >= 5 THEN
		out_ol_i_id5 := a_ol_i_id(5);
		out_ol_supply_w_id5 := a_ol_supply_w_id(5);
		out_ol_quantity5 := a_ol_quantity(5);
		out_ol_amount5 := a_ol_amount(5);
		out_ol_delivery_d5 := a_ol_delivery_d(5);
	END IF;
	IF a_ol_i_id.COUNT >= 6 THEN
		out_ol_i_id6 := a_ol_i_id(6);
		out_ol_supply_w_id6 := a_ol_supply_w_id(6);
		out_ol_quantity6 := a_ol_quantity(6);
		out_ol_amount6 := a_ol_amount(6);
		out_ol_delivery_d6 := a_ol_delivery_d(6);
	END IF;
	IF a_ol_i_id.COUNT >= 7 THEN
		out_ol_i_id7 := a_ol_i_id(7);
		out_ol_supply_w_id7 := a_ol_supply_w_id(7);
		out_ol_quantity7 := a_ol_quantity(7);
		out_ol_amount7 := a_ol_amount(7);
		out_ol_delivery_d7 := a_ol_delivery_d(7);
	END IF;
	IF a_ol_i_id.COUNT >= 8 THEN
		out_ol_i_id8 := a_ol_i_id(8);
		out_ol_supply_w_id8 := a_ol_supply_w_id(8);
		out_ol_quantity8 := a_ol_quantity(8);
		out_ol_amount8 := a_ol_amount(8);
		out_ol_delivery_d8 := a_ol_delivery_d(8);
	END IF;
	IF a_ol_i_id.COUNT >= 9 THEN
		out_ol_i_id9 := a_ol_i_id(9);
		out_ol_supply_w_id9 := a_ol_supply_w_id(9);
		out_ol_quantity9 := a_ol_quantity(9);
		out_ol_amount9 := a_ol_amount(9);
		out_ol_delivery_d9 := a_ol_delivery_d(9);
	END IF;
	IF a_ol_i_id.COUNT >= 10 THEN
		out_ol_i_id10 := a_ol_i_id(10);
		out_ol_supply_w_id10 := a_ol_supply_w_id(10);
		out_ol_quantity10 := a_ol_quantity(10);
		out_ol_amount10 := a_ol_amount(10);
		out_ol_delivery_d10 := a_ol_delivery_d(10);
	END IF;
	IF a_ol_i_id.COUNT >= 11 THEN
		out_ol_i_id11 := a_ol_i_id(11);
		out_ol_supply_w_id11 := a_ol_supply_w_id(11);
		out_ol_quantity11 := a_ol_quantity(11);
		out_ol_amount11 := a_ol_amount(11);
		out_ol_delivery_d11 := a_ol_delivery_d(11);
	END IF;
	IF a_ol_i_id.COUNT >= 12 THEN
		out_ol_i_id12 := a_ol_i_id(12);
		out_ol_supply_w_id12 := a_ol_supply_w_id(12);
		out_ol_quantity12 := a_ol_quantity(12);
		out_ol_amount12 := a_ol_amount(12);
		out_ol_delivery_d12 := a_ol_delivery_d(12);
	END IF;
	IF a_ol_i_id.COUNT >= 13 THEN
		out_ol_i_id13 := a_ol_i_id(13);
		out_ol_supply_w_id13 := a_ol_supply_w_id(13);
		out_ol_quantity13 := a_ol_quantity(13);
		out_ol_amount13 := a_ol_amount(13);
		out_ol_delivery_d13 := a_ol_delivery_d(13);
	END IF;
	IF a_ol_i_id.COUNT >= 14 THEN
		out_ol_i_id14 := a_ol_i_id(14);
		out_ol_supply_w_id14 := a_ol_supply_w_id(14);
		out_ol_quantity14 := a_ol_quantity(14);
		out_ol_amount14 := a_ol_amount(14);
		out_ol_delivery_d14 := a_ol_delivery_d(14);
	END IF;
	IF a_ol_i_id.COUNT >= 15 THEN
		out_ol_i_id15 := a_ol_i_id(15);
		out_ol_supply_w_id15 := a_ol_supply_w_id(15);
		out_ol_quantity15 := a_ol_quantity(15);
		out_ol_amount15 := a_ol_amount(15);
		out_ol_delivery_d15 := a_ol_delivery_d(15);
	END IF;

END;
/
