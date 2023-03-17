--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- Based on TPC-C Standard Specification Revision 5.0 
-- /

spool ${WSRLDB}/order_status.log;
set echo on;

CREATE OR REPLACE PROCEDURE order_status (in_c_id customer.c_id%TYPE,
					in_c_w_id customer.c_w_id%TYPE,
					in_c_d_id customer.c_d_id%TYPE,
					in_c_last customer.c_last%TYPE) AS

	out_c_first             customer.c_first%TYPE;
	out_c_middle            customer.c_middle%TYPE;
	out_c_balance           customer.c_balance%TYPE;
	out_o_id                order_line.ol_o_id%TYPE;
	out_o_carrier_id        orders.o_carrier_id%TYPE;
	out_o_entry_d           orders.o_entry_d%TYPE;
	out_o_ol_cnt            orders.o_ol_cnt%TYPE;
	out_ol_supply_w_id1     order_line.ol_supply_w_id%TYPE;
	out_ol_i_id1            order_line.ol_i_id%TYPE;
	out_ol_quantity1        order_line.ol_quantity%TYPE;
	out_ol_amount1          order_line.ol_amount%TYPE;
	out_ol_delivery_d1      order_line.ol_delivery_d%TYPE;
	out_ol_supply_w_id2     order_line.ol_supply_w_id%TYPE;
	out_ol_i_id2            order_line.ol_i_id%TYPE;
	out_ol_quantity2        order_line.ol_quantity%TYPE;
	out_ol_amount2          order_line.ol_amount%TYPE;
	out_ol_delivery_d2      order_line.ol_delivery_d%TYPE;
	out_ol_supply_w_id3     order_line.ol_supply_w_id%TYPE;
	out_ol_i_id3            order_line.ol_i_id%TYPE;
	out_ol_quantity3        order_line.ol_quantity%TYPE;
	out_ol_amount3          order_line.ol_amount%TYPE;
	out_ol_delivery_d3      order_line.ol_delivery_d%TYPE;
	out_ol_supply_w_id4     order_line.ol_supply_w_id%TYPE;
	out_ol_i_id4            order_line.ol_i_id%TYPE;
	out_ol_quantity4        order_line.ol_quantity%TYPE; 
	out_ol_amount4          order_line.ol_amount%TYPE;
	out_ol_delivery_d4      order_line.ol_delivery_d%TYPE;
	out_ol_supply_w_id5     order_line.ol_supply_w_id%TYPE; 
	out_ol_i_id5            order_line.ol_i_id%TYPE;
	out_ol_quantity5        order_line.ol_quantity%TYPE; 
	out_ol_amount5          order_line.ol_amount%TYPE;
	out_ol_delivery_d5      order_line.ol_delivery_d%TYPE;
	out_ol_supply_w_id6     order_line.ol_supply_w_id%TYPE; 
	out_ol_i_id6            order_line.ol_i_id%TYPE;
	out_ol_quantity6        order_line.ol_quantity%TYPE; 
	out_ol_amount6          order_line.ol_amount%TYPE;
	out_ol_delivery_d6      order_line.ol_delivery_d%TYPE;
	out_ol_supply_w_id7     order_line.ol_supply_w_id%TYPE; 
	out_ol_i_id7            order_line.ol_i_id%TYPE;
	out_ol_quantity7        order_line.ol_quantity%TYPE; 
	out_ol_amount7          order_line.ol_amount%TYPE;
	out_ol_delivery_d7      order_line.ol_delivery_d%TYPE;
	out_ol_supply_w_id8     order_line.ol_supply_w_id%TYPE; 
	out_ol_i_id8            order_line.ol_i_id%TYPE;
	out_ol_quantity8        order_line.ol_quantity%TYPE; 
	out_ol_amount8          order_line.ol_amount%TYPE;
	out_ol_delivery_d8      order_line.ol_delivery_d%TYPE;
	out_ol_supply_w_id9     order_line.ol_supply_w_id%TYPE; 
	out_ol_i_id9            order_line.ol_i_id%TYPE;
	out_ol_quantity9        order_line.ol_quantity%TYPE; 
	out_ol_amount9          order_line.ol_amount%TYPE;
	out_ol_delivery_d9      order_line.ol_delivery_d%TYPE;
	out_ol_supply_w_id10    order_line.ol_supply_w_id%TYPE; 
	out_ol_i_id10           order_line.ol_i_id%TYPE;
	out_ol_quantity10       order_line.ol_quantity%TYPE; 
	out_ol_amount10         order_line.ol_amount%TYPE;
	out_ol_delivery_d10     order_line.ol_delivery_d%TYPE;
	out_ol_supply_w_id11    order_line.ol_supply_w_id%TYPE; 
	out_ol_i_id11           order_line.ol_i_id%TYPE;
	out_ol_quantity11       order_line.ol_quantity%TYPE; 
	out_ol_amount11         order_line.ol_amount%TYPE;
	out_ol_delivery_d11     order_line.ol_delivery_d%TYPE;
	out_ol_supply_w_id12    order_line.ol_supply_w_id%TYPE; 
	out_ol_i_id12           order_line.ol_i_id%TYPE;
	out_ol_quantity12       order_line.ol_quantity%TYPE; 
	out_ol_amount12         order_line.ol_amount%TYPE;
	out_ol_delivery_d12     order_line.ol_delivery_d%TYPE;
	out_ol_supply_w_id13    order_line.ol_supply_w_id%TYPE; 
	out_ol_i_id13           order_line.ol_i_id%TYPE;
	out_ol_quantity13       order_line.ol_quantity%TYPE; 
	out_ol_amount13         order_line.ol_amount%TYPE;
	out_ol_delivery_d13     order_line.ol_delivery_d%TYPE;
	out_ol_supply_w_id14    order_line.ol_supply_w_id%TYPE; 
	out_ol_i_id14           order_line.ol_i_id%TYPE;
	out_ol_quantity14       order_line.ol_quantity%TYPE; 
	out_ol_amount14         order_line.ol_amount%TYPE;
	out_ol_delivery_d14     order_line.ol_delivery_d%TYPE;
	out_ol_supply_w_id15    order_line.ol_supply_w_id%TYPE; 
	out_ol_i_id15           order_line.ol_i_id%TYPE;
	out_ol_quantity15       order_line.ol_quantity%TYPE; 
	out_ol_amount15         order_line.ol_amount%TYPE;
	out_ol_delivery_d15     order_line.ol_delivery_d%TYPE;

	out_c_id                customer.c_id%TYPE;
	out_c_last              customer.c_last%TYPE;

        rc                      INTEGER := 0;

	cursor c is SELECT ol_i_id, ol_supply_w_id, ol_quantity, 
				ol_amount, ol_delivery_d
			FROM order_line
			WHERE ol_w_id = in_c_w_id
				AND ol_d_id = in_c_d_id
				AND ol_o_id = out_o_id
				AND rownum < 2;

--      declare continue handler for sqlstate '02000' set rc = 1;

BEGIN

--*
--* Pick a customeromer by searching for c_last, should pick the one in the
--* middle, not the first one.
--*/
	IF in_c_id = 0 THEN
<<order_status1>>
		BEGIN
		SELECT c_id
		INTO out_c_id 
		FROM customer
		WHERE c_w_id = in_c_w_id
			AND c_d_id = in_c_d_id
			AND c_last = in_c_last
			AND rownum < 2
		ORDER BY c_first ASC;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(1)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' in_c_last = ' || in_c_last);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(1)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' in_c_last = ' || in_c_last);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status1;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status1;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
	ELSE
		out_c_id := in_c_id;
	END IF;

<<order_status2>>
	BEGIN
	SELECT c_first, c_middle, c_last, c_balance
	INTO out_c_first, out_c_middle, out_c_last, out_c_balance
	FROM customer
	WHERE c_w_id = in_c_w_id   
		AND c_d_id = in_c_d_id
		AND c_id = out_c_id
		AND rownum < 2;

	EXCEPTION
		WHEN TOO_MANY_ROWS THEN
			DBMS_OUTPUT.PUT_LINE('(2)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_c_id = ' || out_c_id);
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('(2)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_c_id = ' || out_c_id);
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO order_status2;
			ELSIF SQLCODE = -1555 THEN
				GOTO order_status2;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_order_status;
			END IF;
	END;

<<order_status3>>
	BEGIN
	SELECT o_id, o_carrier_id, o_entry_d, o_ol_cnt
	INTO out_o_id, out_o_carrier_id, out_o_entry_d, out_o_ol_cnt
	FROM orders
	WHERE o_w_id = in_c_w_id
	  	AND o_d_id = in_c_d_id
	  	AND o_c_id = out_c_id
		AND rownum < 2
	ORDER BY o_id DESC;

	EXCEPTION
		WHEN TOO_MANY_ROWS THEN
			DBMS_OUTPUT.PUT_LINE('(3)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_c_id = ' || out_c_id);
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('(3)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_c_id = ' || out_c_id);
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO order_status3;
			ELSIF SQLCODE = -1555 THEN
				GOTO order_status3;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_order_status;
			END IF;
	END;

	open c;

	BEGIN
<<order_status4>>
		BEGIN
		fetch c into out_ol_i_id1, out_ol_supply_w_id1, out_ol_quantity1, 
				out_ol_amount1, out_ol_delivery_d1;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(4)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(4)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status4;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status4;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
<<order_status5>>
		BEGIN
		fetch c into out_ol_i_id2, out_ol_supply_w_id2, out_ol_quantity2, 
				out_ol_amount2, out_ol_delivery_d2;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(5)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(5)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status5;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status5;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
<<order_status6>>
		BEGIN
		fetch c into out_ol_i_id3, out_ol_supply_w_id3, out_ol_quantity3, 
				out_ol_amount3, out_ol_delivery_d3;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(6)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(6)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status6;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status6;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
<<order_status7>>
		BEGIN
		fetch c into out_ol_i_id4, out_ol_supply_w_id4, out_ol_quantity4, 
				out_ol_amount4, out_ol_delivery_d4;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(7)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(7)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status7;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status7;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
<<order_status8>>
		BEGIN
		fetch c into out_ol_i_id5, out_ol_supply_w_id5, out_ol_quantity5, 
				out_ol_amount5, out_ol_delivery_d5;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(8)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(8)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status8;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status8;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
<<order_status9>>
		BEGIN
		fetch c into out_ol_i_id6, out_ol_supply_w_id6, out_ol_quantity6, 
				out_ol_amount6, out_ol_delivery_d6;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(9)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(9)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status9;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status9;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
<<order_status10>>
		BEGIN
		fetch c into out_ol_i_id7, out_ol_supply_w_id7, out_ol_quantity7, 
				out_ol_amount7, out_ol_delivery_d7;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(10)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(10)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status10;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status10;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
<<order_status11>>
		BEGIN
		fetch c into out_ol_i_id8, out_ol_supply_w_id8, out_ol_quantity8, 
				out_ol_amount8, out_ol_delivery_d8;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(11)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(11)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status11;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status11;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
<<order_status12>>
		BEGIN
		fetch c into out_ol_i_id9, out_ol_supply_w_id9, out_ol_quantity9, 
				out_ol_amount9, out_ol_delivery_d9;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(12)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(12)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status12;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status12;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
<<order_status13>>
		BEGIN
		fetch c into out_ol_i_id10, out_ol_supply_w_id10, out_ol_quantity10, 
				out_ol_amount10, out_ol_delivery_d10;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(13)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(13)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status13;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status13;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
<<order_status14>>
		BEGIN
		fetch c into out_ol_i_id11, out_ol_supply_w_id11, out_ol_quantity11, 
				out_ol_amount11, out_ol_delivery_d11;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(14)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(14)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status14;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status14;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
<<order_status15>>
		BEGIN
		fetch c into out_ol_i_id12, out_ol_supply_w_id12, out_ol_quantity12, 
				out_ol_amount12, out_ol_delivery_d12;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(15)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(15)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status15;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status15;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
<<order_status16>>
		BEGIN
		fetch c into out_ol_i_id13, out_ol_supply_w_id13, out_ol_quantity13, 
			out_ol_amount13, out_ol_delivery_d13;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(16)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(16)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status16;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status16;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
<<order_status17>>
		BEGIN
		fetch c into out_ol_i_id14, out_ol_supply_w_id14, out_ol_quantity14, 
				out_ol_amount14, out_ol_delivery_d14;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(17)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(17)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status17;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status17;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
<<order_status18>>
		BEGIN
		fetch c into out_ol_i_id15, out_ol_supply_w_id15, out_ol_quantity15, 
				out_ol_amount15, out_ol_delivery_d15;

		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(18)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(18)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_o_id = ' || out_o_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO order_status18;
				ELSIF SQLCODE = -1555 THEN
					GOTO order_status18;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_order_status;
				END IF;
		END;
--     end fetch_block;
	END;

close c;
<<end_order_status>>
	NULL;
END;
/
set echo off;
spool off;

exit sql.sqlcode;
