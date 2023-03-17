--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- Based on TPC-C Standard Specification Revision 5.0 
-- /

spool ${WSRLDB}/neworder.log;
set echo on;

CREATE OR REPLACE PROCEDURE neworder(  tmp_w_id	warehouse.w_id%TYPE,
				tmp_d_id 	district.d_id%TYPE,
				tmp_c_id 	customer.c_id%TYPE,
				tmp_o_all_local orders.o_all_local%TYPE,
				tmp_o_ol_cnt	orders.o_ol_cnt%TYPE,
				ol_i_id1 	order_line.ol_i_id%TYPE,
				ol_supply_w_id1 order_line.ol_supply_w_id%TYPE,
				ol_quantity1 	order_line.ol_quantity%TYPE,
				ol_i_id2 	order_line.ol_i_id%TYPE,
				ol_supply_w_id2 order_line.ol_supply_w_id%TYPE,
				ol_quantity2 	order_line.ol_quantity%TYPE,
				ol_i_id3 	order_line.ol_i_id%TYPE,
				ol_supply_w_id3 order_line.ol_supply_w_id%TYPE,
				ol_quantity3 	order_line.ol_quantity%TYPE,
				ol_i_id4 	order_line.ol_i_id%TYPE,
				ol_supply_w_id4 order_line.ol_supply_w_id%TYPE,
				ol_quantity4 	order_line.ol_quantity%TYPE,
				ol_i_id5 	order_line.ol_i_id%TYPE,
				ol_supply_w_id5 order_line.ol_supply_w_id%TYPE,
				ol_quantity5 	order_line.ol_quantity%TYPE,
				ol_i_id6 	order_line.ol_i_id%TYPE,
				ol_supply_w_id6 order_line.ol_supply_w_id%TYPE,
				ol_quantity6 	order_line.ol_quantity%TYPE,
				ol_i_id7 	order_line.ol_i_id%TYPE,
				ol_supply_w_id7 order_line.ol_supply_w_id%TYPE,
				ol_quantity7 	order_line.ol_quantity%TYPE,
				ol_i_id8	order_line.ol_i_id%TYPE,
				ol_supply_w_id8	order_line.ol_supply_w_id%TYPE,
				ol_quantity8 	order_line.ol_quantity%TYPE,
				ol_i_id9 	order_line.ol_i_id%TYPE,
				ol_supply_w_id9 order_line.ol_supply_w_id%TYPE,
				ol_quantity9 	order_line.ol_quantity%TYPE,
				ol_i_id10 	order_line.ol_i_id%TYPE,
				ol_supply_w_id10 order_line.ol_supply_w_id%TYPE,
				ol_quantity10 	 order_line.ol_quantity%TYPE,
				ol_i_id11 	 order_line.ol_i_id%TYPE,
				ol_supply_w_id11 order_line.ol_supply_w_id%TYPE,
				ol_quantity11 	 order_line.ol_quantity%TYPE,
				ol_i_id12 	 order_line.ol_i_id%TYPE,
				ol_supply_w_id12 order_line.ol_supply_w_id%TYPE,
				ol_quantity12 	 order_line.ol_quantity%TYPE,
				ol_i_id13	 order_line.ol_i_id%TYPE,
				ol_supply_w_id13 order_line.ol_supply_w_id%TYPE,
				ol_quantity13 	 order_line.ol_quantity%TYPE,
				ol_i_id14 	 order_line.ol_i_id%TYPE,
				ol_supply_w_id14 order_line.ol_supply_w_id%TYPE,
				ol_quantity14 	 order_line.ol_quantity%TYPE,
				ol_i_id15 	 order_line.ol_i_id%TYPE,
				ol_supply_w_id15 order_line.ol_supply_w_id%TYPE,
				ol_quantity15 	 order_line.ol_quantity%TYPE
--				rc OUT INTEGER) AS
				) AS
 
	out_c_credit        customer.c_credit%TYPE;
	tmp_i_name          item.i_name%TYPE;
	tmp_i_data          item.i_data%TYPE; 
	out_c_last          customer.c_last%TYPE;

	tmp_ol_supply_w_id  order_line.ol_supply_w_id%TYPE;
	tmp_ol_quantity     order_line.ol_quantity%TYPE;
	out_d_next_o_id     district.d_next_o_id%TYPE;
	tmp_i_id            order_line.ol_i_id%TYPE;

	tmp_s_quantity      order_line.ol_quantity%TYPE;

	out_w_tax           warehouse.w_tax%TYPE; 
	out_d_tax           district.d_tax%TYPE;
	out_c_discount      customer.c_discount%TYPE;
	tmp_i_price         item.i_price%TYPE;
	tmp_ol_amount       order_line.ol_amount%TYPE;
	tmp_total_amount    order_line.ol_amount%TYPE;

	o_id                district.d_next_o_id%TYPE;

	PROCEDURE new_order_2 (in_w_id warehouse.w_id%TYPE,
					in_d_id district.d_id%TYPE,
					in_ol_i_id order_line.ol_i_id%TYPE,
					in_ol_quantity order_line.ol_quantity%TYPE,
					in_i_price item.i_price%TYPE,
					in_i_name item.i_name%TYPE,
					in_i_data item.i_data%TYPE,
					in_ol_o_id district.d_next_o_id%TYPE,
					in_ol_amount order_line.ol_amount%TYPE,
					in_ol_supply_w_id order_line.ol_supply_w_id%TYPE,
					in_ol_number order_line.ol_number%TYPE,
					out_s_quantity OUT INTEGER) IS

	tmp_s_dist	stock.s_dist_01%TYPE;
	tmp_s_data	stock.s_data%TYPE;

	BEGIN
	IF in_d_id = 1 THEN
<<new_order1>>
		BEGIN
		SELECT s_quantity, s_dist_01, s_data
		INTO out_s_quantity, tmp_s_dist, tmp_s_data
		FROM stock
		WHERE s_i_id = in_ol_i_id
			AND s_w_id = in_w_id
			AND rownum < 2;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(1)oops ! more than one row in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(1)no rows - in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order1;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order1;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order2;
				END IF;
		END;
	ELSIF in_d_id = 2 THEN
<<new_order2>>
		BEGIN
		SELECT s_quantity, s_dist_02, s_data
		INTO out_s_quantity, tmp_s_dist, tmp_s_data
		FROM stock
		WHERE s_i_id = in_ol_i_id
			AND s_w_id = in_w_id
			AND rownum < 2;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(2)oops ! more than one row in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(2)no rows - in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order2;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order2;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order2;
				END IF;
		END;
	ELSIF in_d_id = 3 THEN
<<new_order3>>
		BEGIN
		SELECT s_quantity, s_dist_03, s_data
		INTO out_s_quantity, tmp_s_dist, tmp_s_data
		FROM stock
		WHERE s_i_id = in_ol_i_id
			AND s_w_id = in_w_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(3)oops ! more than one row in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(3)no rows - in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order3;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order3;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order2;
				END IF;
		END;
	ELSIF in_d_id = 4 THEN
<<new_order4>>
		BEGIN
		SELECT s_quantity, s_dist_04, s_data
		INTO out_s_quantity, tmp_s_dist, tmp_s_data
		FROM stock
		WHERE s_i_id = in_ol_i_id
			AND s_w_id = in_w_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(4)oops ! more than one row in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(4)no rows - in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order4;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order4;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order2;
				END IF;
		END;
	ELSIF in_d_id = 5 THEN
<<new_order5>>
		BEGIN
		SELECT s_quantity, s_dist_05, s_data
		INTO out_s_quantity, tmp_s_dist, tmp_s_data
		FROM stock
		WHERE s_i_id = in_ol_i_id
			AND s_w_id = in_w_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(5)oops ! more than one row in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(5)no rows - in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order5;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order5;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order2;
				END IF;
		END;
	ELSIF in_d_id = 6 THEN
<<new_order6>>
		BEGIN
		SELECT s_quantity, s_dist_06, s_data
		INTO out_s_quantity, tmp_s_dist, tmp_s_data
		FROM stock
		WHERE s_i_id = in_ol_i_id
			AND s_w_id = in_w_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(6)oops ! more than one row in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(6)no rows - in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order6;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order6;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order2;
				END IF;
		END;
	ELSIF in_d_id = 7 THEN
<<new_order7>>
		BEGIN
		SELECT s_quantity, s_dist_07, s_data
		INTO out_s_quantity, tmp_s_dist, tmp_s_data
		FROM stock
		WHERE s_i_id = in_ol_i_id
			AND s_w_id = in_w_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(7)oops ! more than one row in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(7)no rows - in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order7;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order7;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order2;
				END IF;
		END;
	ELSIF in_d_id = 8 THEN
<<new_order8>>
		BEGIN
		SELECT s_quantity, s_dist_08, s_data
		INTO out_s_quantity, tmp_s_dist, tmp_s_data
		FROM stock
		WHERE s_i_id = in_ol_i_id
			AND s_w_id = in_w_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(8)oops ! more than one row in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(8)no rows - in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order8;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order8;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order2;
				END IF;
		END;
	ELSIF in_d_id = 9 THEN
<<new_order9>>
		BEGIN
		SELECT s_quantity, s_dist_09, s_data
		INTO out_s_quantity, tmp_s_dist, tmp_s_data
		FROM stock
		WHERE s_i_id = in_ol_i_id
			AND s_w_id = in_w_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(9)oops ! more than one row in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(9)no rows - in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order9;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order9;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order2;
				END IF;
		END;
	ELSIF in_d_id = 10 THEN
<<new_order10>>
		BEGIN
		SELECT s_quantity, s_dist_10, s_data
		INTO out_s_quantity, tmp_s_dist, tmp_s_data
		FROM stock
		WHERE s_i_id = in_ol_i_id
			AND s_w_id = in_w_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(10)oops ! more than one row in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(10)no rows - in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order10;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order10;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order2;
				END IF;
		END;
	END IF;

	IF out_s_quantity > in_ol_quantity + 10 THEN
<<new_order11>>
		DECLARE
                cursor c1 is select s_quantity from stock where s_i_id = in_ol_i_id and s_w_id = in_w_id for update;
		BEGIN
		UPDATE stock
		SET s_quantity = s_quantity - in_ol_quantity
		WHERE CURRENT OF c1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(11)no rows - in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order11;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order11;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order2;
				END IF;
		END;
	ELSE
<<new_order12>>
		BEGIN
		UPDATE stock
		SET s_quantity = s_quantity - in_ol_quantity + 91
		WHERE s_i_id = in_ol_i_id
		AND s_w_id = in_w_id;	
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(12)no rows - in_ol_i_id = ' || in_ol_i_id || ' in_w_id = ' || in_w_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order12;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order12;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order2;
				END IF;
		END;
	END IF;

<<new_order13>>
	BEGIN
	INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id,
				ol_supply_w_id, ol_delivery_d, ol_quantity,
				ol_amount, ol_dist_info)
	VALUES (in_ol_o_id, in_d_id, in_w_id, in_ol_number, in_ol_i_id,
		in_ol_supply_w_id, NULL, in_ol_quantity,
		in_ol_amount, tmp_s_dist);
		EXCEPTION
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order13;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order13;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order2;
				END IF;
		END;
<<end_new_order2>>
		NULL;
	END new_order_2;

BEGIN
--  declare exit handler for sqlstate '02000' set rc = 1;

--	rc := 0;

	o_id := 0;

<<new_order14>>
	BEGIN
	SELECT w_tax
	INTO out_w_tax
	FROM warehouse
	WHERE w_id = tmp_w_id
		AND rownum < 2;
	EXCEPTION
		WHEN TOO_MANY_ROWS THEN
			DBMS_OUTPUT.PUT_LINE('(14)oops ! more than one row tmp_w_id = ' || tmp_w_id);
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('(14)no rows - tmp_w_id = ' || tmp_w_id);
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO new_order14;
			ELSIF SQLCODE = -1555 THEN
				GOTO new_order14;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_new_order;
			END IF;
	END;

<<new_order15>>
	BEGIN
	SELECT d_tax, d_next_o_id
	INTO out_d_tax, out_d_next_o_id
	FROM district   
	WHERE d_w_id = tmp_w_id
		AND d_id = tmp_d_id
		AND rownum < 2
		FOR UPDATE;
	EXCEPTION
		WHEN TOO_MANY_ROWS THEN
			DBMS_OUTPUT.PUT_LINE('(15)oops ! more than one row tmp_w_id = ' || tmp_w_id || ' tmp_d_id = ' || tmp_d_id);
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('(15)no rows - tmp_w_id = ' || tmp_w_id || ' tmp_d_id = ' || tmp_d_id);
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO new_order15;
			ELSIF SQLCODE = -1555 THEN
				GOTO new_order15;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_new_order;
			END IF;
	END;

	o_id := out_d_next_o_id;

<<new_order16>>
	BEGIN
	UPDATE district
	SET d_next_o_id = d_next_o_id + 1
	WHERE d_w_id = tmp_w_id
		AND d_id = tmp_d_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('(16)no rows - tmp_w_id = ' || tmp_w_id || ' tmp_d_id = ' || tmp_d_id);
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO new_order16;
			ELSIF SQLCODE = -1555 THEN
				GOTO new_order16;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_new_order;
			END IF;
	END;

<<new_order17>>
	BEGIN
	SELECT c_discount , c_last, c_credit
	INTO out_c_discount, out_c_last, out_c_credit
	FROM customer
	WHERE c_w_id = tmp_w_id
		AND c_d_id = tmp_d_id
		AND c_id = tmp_c_id;
	EXCEPTION
		WHEN TOO_MANY_ROWS THEN
			DBMS_OUTPUT.PUT_LINE('(17)oops ! more than one row tmp_w_id = ' || tmp_w_id || ' tmp_d_id = ' || tmp_d_id || ' tmp_c_id = ' || tmp_c_id);
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('(17)no rows - tmp_w_id = ' || tmp_w_id || ' tmp_d_id = ' || tmp_d_id || ' tmp_c_id = ' || tmp_c_id);
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO new_order17;
			ELSIF SQLCODE = -1555 THEN
				GOTO new_order17;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_new_order;
			END IF;
	END;

<<new_order18>>
	BEGIN
	INSERT INTO new_order (no_o_id, no_d_id, no_w_id)
	VALUES (out_d_next_o_id, tmp_d_id, tmp_w_id);
	EXCEPTION
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO new_order18;
			ELSIF SQLCODE = -1555 THEN
				GOTO new_order18;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_new_order;
			END IF;
	END;

<<new_order19>>
	BEGIN
	INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d,
				o_carrier_id, o_ol_cnt, o_all_local)
	VALUES (out_d_next_o_id, tmp_d_id, tmp_w_id, tmp_c_id,
		current_timestamp, NULL, tmp_o_ol_cnt, tmp_o_all_local);
	EXCEPTION
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO new_order19;
			ELSIF SQLCODE = -1555 THEN
				GOTO new_order19;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_new_order;
			END IF;
	END;

	tmp_total_amount := 0;

	IF tmp_o_ol_cnt > 0 
	THEN

		tmp_i_id           := ol_i_id1;
		tmp_ol_supply_w_id := ol_supply_w_id1;
		tmp_ol_quantity    := ol_quantity1;

<<new_order20>>
		BEGIN
		SELECT i_price, i_name, i_data
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(20)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(20)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order20;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order20;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 
		THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;

			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 1, tmp_s_quantity);

			tmp_total_amount := tmp_ol_amount;
		END IF;
	END IF;

	IF tmp_o_ol_cnt > 1 
	THEN
		tmp_i_id           := ol_i_id2;
		tmp_ol_supply_w_id := ol_supply_w_id2;
		tmp_ol_quantity    := ol_quantity2;

<<new_order21>>
		BEGIN
		SELECT i_price, i_name, i_data
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(21)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(21)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order21;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order21;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 
		THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;

			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 2, tmp_s_quantity);

			tmp_total_amount := tmp_total_amount + tmp_ol_amount;
		END IF;
	END IF;

	IF tmp_o_ol_cnt > 2 THEN

		tmp_i_id           := ol_i_id3;
		tmp_ol_supply_w_id := ol_supply_w_id3;
		tmp_ol_quantity    := ol_quantity3;

<<new_order22>>
		BEGIN
		SELECT i_price, i_name, i_data
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(22)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(22)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order22;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order22;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;

			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 3, tmp_s_quantity);

			tmp_total_amount := tmp_total_amount + tmp_ol_amount;
		END IF;
	END IF;

	IF tmp_o_ol_cnt > 3 THEN

		tmp_i_id           := ol_i_id4;
		tmp_ol_supply_w_id := ol_supply_w_id4;
		tmp_ol_quantity    := ol_quantity4;

<<new_order23>>
		BEGIN
		SELECT i_price, i_name, i_data
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(23)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(23)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order23;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order23;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;

			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 4, tmp_s_quantity);

			tmp_total_amount := tmp_total_amount + tmp_ol_amount;
		END IF;
	END IF;

	IF tmp_o_ol_cnt > 4 THEN

		tmp_i_id           := ol_i_id5;
		tmp_ol_supply_w_id := ol_supply_w_id5;
		tmp_ol_quantity    := ol_quantity5;

<<new_order24>>
		BEGIN
		SELECT i_price, i_name, i_data
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(24)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(24)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order24;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order24;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;

			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 5, tmp_s_quantity);

			tmp_total_amount := tmp_total_amount + tmp_ol_amount;
		END IF;
	END IF;

	IF tmp_o_ol_cnt > 5 THEN
		tmp_i_id           := ol_i_id6;
		tmp_ol_supply_w_id := ol_supply_w_id6;
		tmp_ol_quantity    := ol_quantity6;

<<new_order25>>
		BEGIN
		SELECT i_price, i_name, i_data
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(25)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(25)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order25;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order25;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;

			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 6, tmp_s_quantity);

			tmp_total_amount := tmp_total_amount + tmp_ol_amount;
		END IF;
	END IF;

	IF tmp_o_ol_cnt > 6 THEN
		tmp_i_id           := ol_i_id7;
		tmp_ol_supply_w_id := ol_supply_w_id7;
		tmp_ol_quantity    := ol_quantity7;

<<new_order26>>
		BEGIN
		SELECT i_price, i_name, i_data
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(26)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(26)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order26;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order26;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;

			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 7, tmp_s_quantity);

			tmp_total_amount := tmp_total_amount + tmp_ol_amount;
		END IF;
	END IF;

	IF tmp_o_ol_cnt > 7 THEN
		tmp_i_id           := ol_i_id8;
		tmp_ol_supply_w_id := ol_supply_w_id8;
		tmp_ol_quantity    := ol_quantity8;

<<new_order27>>
		BEGIN
		SELECT i_price, i_name, i_data
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(27)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(27)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order27;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order27;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;
			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 8, tmp_s_quantity);

			tmp_total_amount := tmp_total_amount + tmp_ol_amount;
		END IF;
	END IF;

	IF tmp_o_ol_cnt > 8 THEN
		tmp_i_id           := ol_i_id9;
		tmp_ol_supply_w_id := ol_supply_w_id9;
		tmp_ol_quantity    := ol_quantity9;

<<new_order28>>
		BEGIN
		SELECT i_price, i_name, i_data
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(28)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(28)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order28;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order28;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;
			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 9, tmp_s_quantity);

			tmp_total_amount := tmp_total_amount + tmp_ol_amount;
		END IF;
	END IF;

	IF tmp_o_ol_cnt > 9 THEN
		tmp_i_id           := ol_i_id10;
		tmp_ol_supply_w_id := ol_supply_w_id10;
		tmp_ol_quantity    := ol_quantity10;

<<new_order29>>
		BEGIN
		SELECT i_price, i_name, i_data 
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(29)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(29)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order29;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order29;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;
			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 10, tmp_s_quantity);

			tmp_total_amount := tmp_total_amount + tmp_ol_amount;
		END IF;
	END IF;

	IF tmp_o_ol_cnt > 10 THEN
		tmp_i_id           := ol_i_id11;
		tmp_ol_supply_w_id := ol_supply_w_id11;
		tmp_ol_quantity    := ol_quantity11;

<<new_order30>>
		BEGIN
		SELECT i_price, i_name, i_data
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(30)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(30)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order30;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order30;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;
			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 11, tmp_s_quantity);

			tmp_total_amount := tmp_total_amount + tmp_ol_amount;
		END IF;
	END IF;

	IF tmp_o_ol_cnt > 11 THEN
		tmp_i_id           := ol_i_id12;
		tmp_ol_supply_w_id := ol_supply_w_id12;
		tmp_ol_quantity    := ol_quantity12;

<<new_order31>>
		BEGIN
		SELECT i_price, i_name, i_data
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(31)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(31)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order31;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order31;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;
			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 12, tmp_s_quantity);

			tmp_total_amount := tmp_total_amount + tmp_ol_amount;
		END IF;
	END IF;

	IF tmp_o_ol_cnt > 12 THEN
		tmp_i_id           := ol_i_id13;
		tmp_ol_supply_w_id := ol_supply_w_id13;
		tmp_ol_quantity    := ol_quantity13;

<<new_order32>>
		BEGIN
		SELECT i_price, i_name, i_data
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(32)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(32)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order32;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order32;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;
			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 13, tmp_s_quantity);

			tmp_total_amount := tmp_total_amount + tmp_ol_amount;
		END IF;
	END IF;

	IF tmp_o_ol_cnt > 13 THEN
		tmp_i_id           := ol_i_id14;
		tmp_ol_supply_w_id := ol_supply_w_id14;
		tmp_ol_quantity    := ol_quantity14;

<<new_order33>>
		BEGIN
		SELECT i_price, i_name, i_data
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(33)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(33)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order33;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order33;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;
			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 14, tmp_s_quantity);

			tmp_total_amount := tmp_total_amount + tmp_ol_amount;
		END IF;
	END IF;

	IF tmp_o_ol_cnt > 14 THEN

		tmp_i_id           := ol_i_id15;
		tmp_ol_supply_w_id := ol_supply_w_id15;
		tmp_ol_quantity    := ol_quantity15;

<<new_order34>>
		BEGIN
		SELECT i_price, i_name, i_data
		INTO tmp_i_price, tmp_i_name, tmp_i_data
		FROM item
		WHERE i_id = tmp_i_id
			AND rownum < 2;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(34)oops ! more than one row tmp_i_id = ' || tmp_i_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(34)no rows - tmp_i_id = ' || tmp_i_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO new_order34;
				ELSIF SQLCODE = -1555 THEN
					GOTO new_order34;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_new_order;
				END IF;
		END;

		IF tmp_i_price > 0 THEN
			tmp_ol_amount := tmp_i_price * tmp_ol_quantity;
			new_order_2(tmp_w_id, tmp_d_id, tmp_i_id,
					tmp_ol_quantity, tmp_i_price,
					tmp_i_name, tmp_i_data,
					out_d_next_o_id, tmp_ol_amount,
					tmp_ol_supply_w_id, 15, tmp_s_quantity);

			tmp_total_amount := tmp_total_amount + tmp_ol_amount;
		END IF;
	END IF;
<<end_new_order>>
	NULL;
END;
/
set echo off;
spool off;

exit sql.sqlcode;
