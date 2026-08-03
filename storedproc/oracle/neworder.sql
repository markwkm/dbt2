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
-- Output parameters for CHAR values are declared VARCHAR2: a CHAR
-- OUT parameter is blank padded past the caller's buffer, which the
-- OCI caller receives as a truncated value with the indicator set.
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
				ol_quantity15    order_line.ol_quantity%TYPE,
				out_w_tax        OUT warehouse.w_tax%TYPE,
				out_d_tax        OUT district.d_tax%TYPE,
				out_o_id         OUT orders.o_id%TYPE,
				out_c_last       OUT customer.c_last%TYPE,
				out_c_credit     OUT VARCHAR2,
				out_c_discount   OUT customer.c_discount%TYPE,
				out_total_amount OUT order_line.ol_amount%TYPE,
				out_i_price1     OUT item.i_price%TYPE,
				out_i_price2     OUT item.i_price%TYPE,
				out_i_price3     OUT item.i_price%TYPE,
				out_i_price4     OUT item.i_price%TYPE,
				out_i_price5     OUT item.i_price%TYPE,
				out_i_price6     OUT item.i_price%TYPE,
				out_i_price7     OUT item.i_price%TYPE,
				out_i_price8     OUT item.i_price%TYPE,
				out_i_price9     OUT item.i_price%TYPE,
				out_i_price10    OUT item.i_price%TYPE,
				out_i_price11    OUT item.i_price%TYPE,
				out_i_price12    OUT item.i_price%TYPE,
				out_i_price13    OUT item.i_price%TYPE,
				out_i_price14    OUT item.i_price%TYPE,
				out_i_price15    OUT item.i_price%TYPE,
				out_i_name1      OUT item.i_name%TYPE,
				out_i_name2      OUT item.i_name%TYPE,
				out_i_name3      OUT item.i_name%TYPE,
				out_i_name4      OUT item.i_name%TYPE,
				out_i_name5      OUT item.i_name%TYPE,
				out_i_name6      OUT item.i_name%TYPE,
				out_i_name7      OUT item.i_name%TYPE,
				out_i_name8      OUT item.i_name%TYPE,
				out_i_name9      OUT item.i_name%TYPE,
				out_i_name10     OUT item.i_name%TYPE,
				out_i_name11     OUT item.i_name%TYPE,
				out_i_name12     OUT item.i_name%TYPE,
				out_i_name13     OUT item.i_name%TYPE,
				out_i_name14     OUT item.i_name%TYPE,
				out_i_name15     OUT item.i_name%TYPE,
				out_s_quantity1  OUT stock.s_quantity%TYPE,
				out_s_quantity2  OUT stock.s_quantity%TYPE,
				out_s_quantity3  OUT stock.s_quantity%TYPE,
				out_s_quantity4  OUT stock.s_quantity%TYPE,
				out_s_quantity5  OUT stock.s_quantity%TYPE,
				out_s_quantity6  OUT stock.s_quantity%TYPE,
				out_s_quantity7  OUT stock.s_quantity%TYPE,
				out_s_quantity8  OUT stock.s_quantity%TYPE,
				out_s_quantity9  OUT stock.s_quantity%TYPE,
				out_s_quantity10 OUT stock.s_quantity%TYPE,
				out_s_quantity11 OUT stock.s_quantity%TYPE,
				out_s_quantity12 OUT stock.s_quantity%TYPE,
				out_s_quantity13 OUT stock.s_quantity%TYPE,
				out_s_quantity14 OUT stock.s_quantity%TYPE,
				out_s_quantity15 OUT stock.s_quantity%TYPE,
				out_ol_amount1   OUT order_line.ol_amount%TYPE,
				out_ol_amount2   OUT order_line.ol_amount%TYPE,
				out_ol_amount3   OUT order_line.ol_amount%TYPE,
				out_ol_amount4   OUT order_line.ol_amount%TYPE,
				out_ol_amount5   OUT order_line.ol_amount%TYPE,
				out_ol_amount6   OUT order_line.ol_amount%TYPE,
				out_ol_amount7   OUT order_line.ol_amount%TYPE,
				out_ol_amount8   OUT order_line.ol_amount%TYPE,
				out_ol_amount9   OUT order_line.ol_amount%TYPE,
				out_ol_amount10  OUT order_line.ol_amount%TYPE,
				out_ol_amount11  OUT order_line.ol_amount%TYPE,
				out_ol_amount12  OUT order_line.ol_amount%TYPE,
				out_ol_amount13  OUT order_line.ol_amount%TYPE,
				out_ol_amount14  OUT order_line.ol_amount%TYPE,
				out_ol_amount15  OUT order_line.ol_amount%TYPE,
				out_brand_generic1  OUT VARCHAR2,
				out_brand_generic2  OUT VARCHAR2,
				out_brand_generic3  OUT VARCHAR2,
				out_brand_generic4  OUT VARCHAR2,
				out_brand_generic5  OUT VARCHAR2,
				out_brand_generic6  OUT VARCHAR2,
				out_brand_generic7  OUT VARCHAR2,
				out_brand_generic8  OUT VARCHAR2,
				out_brand_generic9  OUT VARCHAR2,
				out_brand_generic10 OUT VARCHAR2,
				out_brand_generic11 OUT VARCHAR2,
				out_brand_generic12 OUT VARCHAR2,
				out_brand_generic13 OUT VARCHAR2,
				out_brand_generic14 OUT VARCHAR2,
				out_brand_generic15 OUT VARCHAR2) AS

	TYPE t_number_list IS VARRAY(15) OF NUMBER;
	TYPE t_name_list IS VARRAY(15) OF item.i_name%TYPE;
	TYPE t_char_list IS VARRAY(15) OF CHAR(1);

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

	a_i_price t_number_list := t_number_list();
	a_i_name t_name_list := t_name_list();
	a_s_quantity t_number_list := t_number_list();
	a_ol_amount t_number_list := t_number_list();
	a_brand_generic t_char_list := t_char_list();

	out_d_next_o_id   district.d_next_o_id%TYPE;
	tmp_i_price       item.i_price%TYPE;
	tmp_i_name        item.i_name%TYPE;
	tmp_i_data        item.i_data%TYPE;
	tmp_ol_amount     order_line.ol_amount%TYPE;
	tmp_total_amount  order_line.ol_amount%TYPE;
	tmp_s_quantity    stock.s_quantity%TYPE;
	tmp_brand_generic CHAR(1);
	o_id              district.d_next_o_id%TYPE;

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
				out_s_quantity    OUT stock.s_quantity%TYPE,
				out_brand_generic OUT VARCHAR2) IS

		tmp_s_dist stock.s_dist_01%TYPE;
		tmp_s_data stock.s_data%TYPE;
		tmp_remote INTEGER;

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
			out_brand_generic := 'B';
		ELSE
			out_brand_generic := 'G';
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
				a_ol_supply_w_id(i), i, tmp_s_quantity,
				tmp_brand_generic);

		tmp_total_amount := tmp_total_amount + tmp_ol_amount;

		a_i_price.EXTEND;
		a_i_price(i) := tmp_i_price;
		a_i_name.EXTEND;
		a_i_name(i) := tmp_i_name;
		a_s_quantity.EXTEND;
		a_s_quantity(i) := tmp_s_quantity;
		a_ol_amount.EXTEND;
		a_ol_amount(i) := tmp_ol_amount;
		a_brand_generic.EXTEND;
		a_brand_generic(i) := tmp_brand_generic;
	END LOOP;

	out_o_id := o_id;

	-- The total amount before the discount and tax adjustment that
	-- the client applies.
	out_total_amount := tmp_total_amount;

	IF tmp_o_ol_cnt >= 1 THEN
		out_i_price1 := a_i_price(1);
		out_i_name1 := a_i_name(1);
		out_s_quantity1 := a_s_quantity(1);
		out_ol_amount1 := a_ol_amount(1);
		out_brand_generic1 := a_brand_generic(1);
	END IF;
	IF tmp_o_ol_cnt >= 2 THEN
		out_i_price2 := a_i_price(2);
		out_i_name2 := a_i_name(2);
		out_s_quantity2 := a_s_quantity(2);
		out_ol_amount2 := a_ol_amount(2);
		out_brand_generic2 := a_brand_generic(2);
	END IF;
	IF tmp_o_ol_cnt >= 3 THEN
		out_i_price3 := a_i_price(3);
		out_i_name3 := a_i_name(3);
		out_s_quantity3 := a_s_quantity(3);
		out_ol_amount3 := a_ol_amount(3);
		out_brand_generic3 := a_brand_generic(3);
	END IF;
	IF tmp_o_ol_cnt >= 4 THEN
		out_i_price4 := a_i_price(4);
		out_i_name4 := a_i_name(4);
		out_s_quantity4 := a_s_quantity(4);
		out_ol_amount4 := a_ol_amount(4);
		out_brand_generic4 := a_brand_generic(4);
	END IF;
	IF tmp_o_ol_cnt >= 5 THEN
		out_i_price5 := a_i_price(5);
		out_i_name5 := a_i_name(5);
		out_s_quantity5 := a_s_quantity(5);
		out_ol_amount5 := a_ol_amount(5);
		out_brand_generic5 := a_brand_generic(5);
	END IF;
	IF tmp_o_ol_cnt >= 6 THEN
		out_i_price6 := a_i_price(6);
		out_i_name6 := a_i_name(6);
		out_s_quantity6 := a_s_quantity(6);
		out_ol_amount6 := a_ol_amount(6);
		out_brand_generic6 := a_brand_generic(6);
	END IF;
	IF tmp_o_ol_cnt >= 7 THEN
		out_i_price7 := a_i_price(7);
		out_i_name7 := a_i_name(7);
		out_s_quantity7 := a_s_quantity(7);
		out_ol_amount7 := a_ol_amount(7);
		out_brand_generic7 := a_brand_generic(7);
	END IF;
	IF tmp_o_ol_cnt >= 8 THEN
		out_i_price8 := a_i_price(8);
		out_i_name8 := a_i_name(8);
		out_s_quantity8 := a_s_quantity(8);
		out_ol_amount8 := a_ol_amount(8);
		out_brand_generic8 := a_brand_generic(8);
	END IF;
	IF tmp_o_ol_cnt >= 9 THEN
		out_i_price9 := a_i_price(9);
		out_i_name9 := a_i_name(9);
		out_s_quantity9 := a_s_quantity(9);
		out_ol_amount9 := a_ol_amount(9);
		out_brand_generic9 := a_brand_generic(9);
	END IF;
	IF tmp_o_ol_cnt >= 10 THEN
		out_i_price10 := a_i_price(10);
		out_i_name10 := a_i_name(10);
		out_s_quantity10 := a_s_quantity(10);
		out_ol_amount10 := a_ol_amount(10);
		out_brand_generic10 := a_brand_generic(10);
	END IF;
	IF tmp_o_ol_cnt >= 11 THEN
		out_i_price11 := a_i_price(11);
		out_i_name11 := a_i_name(11);
		out_s_quantity11 := a_s_quantity(11);
		out_ol_amount11 := a_ol_amount(11);
		out_brand_generic11 := a_brand_generic(11);
	END IF;
	IF tmp_o_ol_cnt >= 12 THEN
		out_i_price12 := a_i_price(12);
		out_i_name12 := a_i_name(12);
		out_s_quantity12 := a_s_quantity(12);
		out_ol_amount12 := a_ol_amount(12);
		out_brand_generic12 := a_brand_generic(12);
	END IF;
	IF tmp_o_ol_cnt >= 13 THEN
		out_i_price13 := a_i_price(13);
		out_i_name13 := a_i_name(13);
		out_s_quantity13 := a_s_quantity(13);
		out_ol_amount13 := a_ol_amount(13);
		out_brand_generic13 := a_brand_generic(13);
	END IF;
	IF tmp_o_ol_cnt >= 14 THEN
		out_i_price14 := a_i_price(14);
		out_i_name14 := a_i_name(14);
		out_s_quantity14 := a_s_quantity(14);
		out_ol_amount14 := a_ol_amount(14);
		out_brand_generic14 := a_brand_generic(14);
	END IF;
	IF tmp_o_ol_cnt >= 15 THEN
		out_i_price15 := a_i_price(15);
		out_i_name15 := a_i_name(15);
		out_s_quantity15 := a_s_quantity(15);
		out_ol_amount15 := a_ol_amount(15);
		out_brand_generic15 := a_brand_generic(15);
	END IF;

	tmp_total_amount := tmp_total_amount * (1 - out_c_discount)
			* (1 + out_w_tax + out_d_tax);

END neworder;
/
