--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
--
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- Copyright The DBT-2 Authors
--
-- Based on TPC-C Standard Specification Revision 5.11 Clause 2.4.2.
--
-- An unused item number, the one percent rollback case, raises
-- ORA-20001: an unhandled NO_DATA_FOUND cannot be used because the
-- SQL CALL statement reports it to the client as a successful
-- execution without undoing the procedure's work.  The error makes
-- Oracle roll the whole call back and the client counts the
-- transaction as rolled back.
--

CREATE OR REPLACE PROCEDURE neworder(tmp_w_id     warehouse.w_id%TYPE,
				tmp_d_id         district.d_id%TYPE,
				tmp_c_id         customer.c_id%TYPE,
				tmp_o_all_local  orders.o_all_local%TYPE,
				tmp_o_ol_cnt     orders.o_ol_cnt%TYPE,
				ol_i_id1         order_line.ol_i_id%TYPE,
				ol_supply_w_id1  order_line.ol_supply_w_id%TYPE,
				ol_quantity1     order_line.ol_quantity%TYPE,
				ol_i_id2         order_line.ol_i_id%TYPE,
				ol_supply_w_id2  order_line.ol_supply_w_id%TYPE,
				ol_quantity2     order_line.ol_quantity%TYPE,
				ol_i_id3         order_line.ol_i_id%TYPE,
				ol_supply_w_id3  order_line.ol_supply_w_id%TYPE,
				ol_quantity3     order_line.ol_quantity%TYPE,
				ol_i_id4         order_line.ol_i_id%TYPE,
				ol_supply_w_id4  order_line.ol_supply_w_id%TYPE,
				ol_quantity4     order_line.ol_quantity%TYPE,
				ol_i_id5         order_line.ol_i_id%TYPE,
				ol_supply_w_id5  order_line.ol_supply_w_id%TYPE,
				ol_quantity5     order_line.ol_quantity%TYPE,
				ol_i_id6         order_line.ol_i_id%TYPE,
				ol_supply_w_id6  order_line.ol_supply_w_id%TYPE,
				ol_quantity6     order_line.ol_quantity%TYPE,
				ol_i_id7         order_line.ol_i_id%TYPE,
				ol_supply_w_id7  order_line.ol_supply_w_id%TYPE,
				ol_quantity7     order_line.ol_quantity%TYPE,
				ol_i_id8         order_line.ol_i_id%TYPE,
				ol_supply_w_id8  order_line.ol_supply_w_id%TYPE,
				ol_quantity8     order_line.ol_quantity%TYPE,
				ol_i_id9         order_line.ol_i_id%TYPE,
				ol_supply_w_id9  order_line.ol_supply_w_id%TYPE,
				ol_quantity9     order_line.ol_quantity%TYPE,
				ol_i_id10        order_line.ol_i_id%TYPE,
				ol_supply_w_id10 order_line.ol_supply_w_id%TYPE,
				ol_quantity10    order_line.ol_quantity%TYPE,
				ol_i_id11        order_line.ol_i_id%TYPE,
				ol_supply_w_id11 order_line.ol_supply_w_id%TYPE,
				ol_quantity11    order_line.ol_quantity%TYPE,
				ol_i_id12        order_line.ol_i_id%TYPE,
				ol_supply_w_id12 order_line.ol_supply_w_id%TYPE,
				ol_quantity12    order_line.ol_quantity%TYPE,
				ol_i_id13        order_line.ol_i_id%TYPE,
				ol_supply_w_id13 order_line.ol_supply_w_id%TYPE,
				ol_quantity13    order_line.ol_quantity%TYPE,
				ol_i_id14        order_line.ol_i_id%TYPE,
				ol_supply_w_id14 order_line.ol_supply_w_id%TYPE,
				ol_quantity14    order_line.ol_quantity%TYPE,
				ol_i_id15        order_line.ol_i_id%TYPE,
				ol_supply_w_id15 order_line.ol_supply_w_id%TYPE,
				ol_quantity15    order_line.ol_quantity%TYPE) AS

	TYPE t_number_list IS VARRAY(15) OF NUMBER;

	a_ol_i_id t_number_list := t_number_list(
			ol_i_id1, ol_i_id2, ol_i_id3, ol_i_id4, ol_i_id5,
			ol_i_id6, ol_i_id7, ol_i_id8, ol_i_id9, ol_i_id10,
			ol_i_id11, ol_i_id12, ol_i_id13, ol_i_id14, ol_i_id15);
	a_ol_supply_w_id t_number_list := t_number_list(
			ol_supply_w_id1, ol_supply_w_id2, ol_supply_w_id3,
			ol_supply_w_id4, ol_supply_w_id5, ol_supply_w_id6,
			ol_supply_w_id7, ol_supply_w_id8, ol_supply_w_id9,
			ol_supply_w_id10, ol_supply_w_id11, ol_supply_w_id12,
			ol_supply_w_id13, ol_supply_w_id14, ol_supply_w_id15);
	a_ol_quantity t_number_list := t_number_list(
			ol_quantity1, ol_quantity2, ol_quantity3, ol_quantity4,
			ol_quantity5, ol_quantity6, ol_quantity7, ol_quantity8,
			ol_quantity9, ol_quantity10, ol_quantity11, ol_quantity12,
			ol_quantity13, ol_quantity14, ol_quantity15);

	out_w_tax        warehouse.w_tax%TYPE;
	out_d_tax        district.d_tax%TYPE;
	out_d_next_o_id  district.d_next_o_id%TYPE;
	out_c_discount   customer.c_discount%TYPE;
	out_c_last       customer.c_last%TYPE;
	out_c_credit     customer.c_credit%TYPE;
	tmp_i_price      item.i_price%TYPE;
	tmp_i_name       item.i_name%TYPE;
	tmp_i_data       item.i_data%TYPE;
	tmp_ol_amount    order_line.ol_amount%TYPE;
	tmp_total_amount order_line.ol_amount%TYPE;
	tmp_s_quantity   stock.s_quantity%TYPE;
	o_id             district.d_next_o_id%TYPE;

	PROCEDURE new_order_2 (in_w_id  warehouse.w_id%TYPE,
				in_d_id           district.d_id%TYPE,
				in_ol_i_id        order_line.ol_i_id%TYPE,
				in_ol_quantity    order_line.ol_quantity%TYPE,
				in_i_price        item.i_price%TYPE,
				in_i_name         item.i_name%TYPE,
				in_i_data         item.i_data%TYPE,
				in_ol_o_id        district.d_next_o_id%TYPE,
				in_ol_amount      order_line.ol_amount%TYPE,
				in_ol_supply_w_id order_line.ol_supply_w_id%TYPE,
				in_ol_number      order_line.ol_number%TYPE,
				out_s_quantity    OUT stock.s_quantity%TYPE) IS

		tmp_s_dist        stock.s_dist_01%TYPE;
		tmp_s_data        stock.s_data%TYPE;
		tmp_brand_generic CHAR(1);
		tmp_remote        INTEGER;

	BEGIN

		-- The stock is read and updated at the supplying warehouse.
		SELECT s_quantity,
			DECODE(in_d_id,
				1, s_dist_01, 2, s_dist_02, 3, s_dist_03,
				4, s_dist_04, 5, s_dist_05, 6, s_dist_06,
				7, s_dist_07, 8, s_dist_08, 9, s_dist_09,
				10, s_dist_10),
			s_data
		INTO out_s_quantity, tmp_s_dist, tmp_s_data
		FROM stock
		WHERE s_i_id = in_ol_i_id
			AND s_w_id = in_ol_supply_w_id
		FOR UPDATE;

		IF INSTR(in_i_data, 'ORIGINAL') > 0
			AND INSTR(tmp_s_data, 'ORIGINAL') > 0 THEN
			tmp_brand_generic := 'B';
		ELSE
			tmp_brand_generic := 'G';
		END IF;

		IF in_ol_supply_w_id <> in_w_id THEN
			tmp_remote := 1;
		ELSE
			tmp_remote := 0;
		END IF;

		IF out_s_quantity >= in_ol_quantity + 10 THEN
			UPDATE stock
			SET s_quantity = s_quantity - in_ol_quantity,
				s_ytd = s_ytd + in_ol_quantity,
				s_order_cnt = s_order_cnt + 1,
				s_remote_cnt = s_remote_cnt + tmp_remote
			WHERE s_i_id = in_ol_i_id
				AND s_w_id = in_ol_supply_w_id;
		ELSE
			UPDATE stock
			SET s_quantity = s_quantity - in_ol_quantity + 91,
				s_ytd = s_ytd + in_ol_quantity,
				s_order_cnt = s_order_cnt + 1,
				s_remote_cnt = s_remote_cnt + tmp_remote
			WHERE s_i_id = in_ol_i_id
				AND s_w_id = in_ol_supply_w_id;
		END IF;

		INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number,
			ol_i_id, ol_supply_w_id, ol_delivery_d, ol_quantity,
			ol_amount, ol_dist_info)
		VALUES (in_ol_o_id, in_d_id, in_w_id, in_ol_number,
			in_ol_i_id, in_ol_supply_w_id, NULL, in_ol_quantity,
			in_ol_amount, tmp_s_dist);

	END new_order_2;

BEGIN

	SELECT w_tax
	INTO out_w_tax
	FROM warehouse
	WHERE w_id = tmp_w_id;

	SELECT d_tax, d_next_o_id
	INTO out_d_tax, out_d_next_o_id
	FROM district
	WHERE d_w_id = tmp_w_id
		AND d_id = tmp_d_id
	FOR UPDATE;

	-- The order id is the pre-increment d_next_o_id.
	o_id := out_d_next_o_id;

	UPDATE district
	SET d_next_o_id = d_next_o_id + 1
	WHERE d_w_id = tmp_w_id
		AND d_id = tmp_d_id;

	SELECT c_discount, c_last, c_credit
	INTO out_c_discount, out_c_last, out_c_credit
	FROM customer
	WHERE c_w_id = tmp_w_id
		AND c_d_id = tmp_d_id
		AND c_id = tmp_c_id;

	INSERT INTO new_order (no_o_id, no_d_id, no_w_id)
	VALUES (o_id, tmp_d_id, tmp_w_id);

	INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d,
		o_carrier_id, o_ol_cnt, o_all_local)
	VALUES (o_id, tmp_d_id, tmp_w_id, tmp_c_id,
		current_timestamp, NULL, tmp_o_ol_cnt, tmp_o_all_local);

	tmp_total_amount := 0;

	FOR i IN 1 .. tmp_o_ol_cnt
	LOOP
		BEGIN
			SELECT i_price, i_name, i_data
			INTO tmp_i_price, tmp_i_name, tmp_i_data
			FROM item
			WHERE i_id = a_ol_i_id(i);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(
					-20001, 'Item number is not valid');
		END;

		tmp_ol_amount := tmp_i_price * a_ol_quantity(i);

		new_order_2(tmp_w_id, tmp_d_id, a_ol_i_id(i),
				a_ol_quantity(i), tmp_i_price, tmp_i_name,
				tmp_i_data, o_id, tmp_ol_amount,
				a_ol_supply_w_id(i), i, tmp_s_quantity);

		tmp_total_amount := tmp_total_amount + tmp_ol_amount;
	END LOOP;

	tmp_total_amount := tmp_total_amount * (1 - out_c_discount)
			* (1 + out_w_tax + out_d_tax);

END neworder;
/
