--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- Based on TPC-C Standard Specification Revision 5.0 
-- /
spool ${WSRLDB}/delivery.log;
set echo on;
CREATE OR REPLACE PROCEDURE delivery (in_w_id new_order.no_w_id%TYPE,
					in_o_carrier_id orders.o_carrier_id%TYPE) AS

	out_c_id      orders.o_c_id%TYPE;
	out_ol_amount order_line.ol_amount%TYPE;
	tmp_d_id      order_line.ol_d_id%TYPE;
	tmp_o_id      new_order.no_o_id%TYPE;

BEGIN

	tmp_d_id := 1;

	WHILE tmp_d_id <= 10
	LOOP
		tmp_o_id := 0;

<<delivery1>>
		BEGIN
		SELECT no_o_id
		INTO tmp_o_id
		FROM new_order
		WHERE no_w_id = in_w_id
			AND no_d_id = tmp_d_id
			AND rownum < 2;
		
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				DBMS_OUTPUT.PUT_LINE('(1)oops ! more than one row in_w_id = ' || in_w_id || ' tmp_d_id = ' || tmp_d_id);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(1)no rows - in_w_id = ' || in_w_id || ' tmp_d_id = ' || tmp_d_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO delivery1;
				ELSIF SQLCODE = -1555 THEN
					GOTO delivery1;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_delivery;
				END IF;
		END;

		DBMS_OUTPUT.PUT_LINE('after delivery1 tmp_o_id = ' || tmp_o_id);

		IF tmp_o_id > 0 
		THEN
<<delivery2>>
			BEGIN
			DELETE FROM new_order 
			WHERE no_o_id = tmp_o_id 
			AND no_w_id = in_w_id 
				AND no_d_id = tmp_d_id;

			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					DBMS_OUTPUT.PUT_LINE('(2)no rows - in_w_id = ' || in_w_id || ' tmp_d_id= ' || tmp_d_id);
				WHEN OTHERS THEN
					IF SQLCODE = -8177 THEN
						GOTO delivery2;
					ELSIF SQLCODE = -1555 THEN
						GOTO delivery2;
					ELSE
						DBMS_OUTPUT.PUT_LINE(SQLERRM);
						GOTO end_delivery;
					END IF;
			END;
<<delivery3>>
			BEGIN 
			SELECT o_c_id
			INTO out_c_id
			FROM orders
			WHERE o_id = tmp_o_id
				AND o_w_id = in_w_id
				AND o_d_id = tmp_d_id
				AND rownum < 2;

			EXCEPTION
				WHEN TOO_MANY_ROWS THEN
					DBMS_OUTPUT.PUT_LINE('(3)oops ! more than one row - tmp_o_id = ' || tmp_o_id || ' in_w_id = ' || in_w_id || ' tmp_d_id= ' || tmp_d_id);
				WHEN NO_DATA_FOUND THEN
					DBMS_OUTPUT.PUT_LINE('(3)no rows - tmp_o_id = ' || tmp_o_id || ' in_w_id = ' || in_w_id || ' tmp_d_id= ' || tmp_d_id);
				WHEN OTHERS THEN
					IF SQLCODE = -8177 THEN
						GOTO delivery3;
					ELSIF SQLCODE = -1555 THEN
						GOTO delivery3;
					ELSE
						DBMS_OUTPUT.PUT_LINE(SQLERRM);
						GOTO end_delivery;
					END IF;
			END;
<<delivery4>>
			BEGIN 
			UPDATE orders
			SET o_carrier_id = in_o_carrier_id
			WHERE o_id = tmp_o_id
				AND o_w_id = in_w_id
				AND o_d_id = tmp_d_id;
 

			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					DBMS_OUTPUT.PUT_LINE('(4)no rows - tmp_o_id = ' || tmp_o_id || ' in_w_id = ' || in_w_id || ' tmp_d_id= ' || tmp_d_id);
				WHEN OTHERS THEN
					IF SQLCODE = -8177 THEN
						GOTO delivery4;
					ELSIF SQLCODE = -1555 THEN
						GOTO delivery4;
					ELSE
						DBMS_OUTPUT.PUT_LINE(SQLERRM);
						GOTO end_delivery;
					END IF;
			END;
<<delivery5>>
			BEGIN
			UPDATE order_line
			SET ol_delivery_d = current_timestamp
			WHERE ol_o_id = tmp_o_id
				AND ol_w_id = in_w_id
				AND ol_d_id = tmp_d_id;

			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					DBMS_OUTPUT.PUT_LINE('(5)no rows - tmp_o_id = ' || tmp_o_id || ' in_w_id = ' || in_w_id || ' tmp_d_id= ' || tmp_d_id);
				WHEN OTHERS THEN
					IF SQLCODE = -8177 THEN
						GOTO delivery5;
					ELSIF SQLCODE = -1555 THEN
						GOTO delivery5;
					ELSE
						DBMS_OUTPUT.PUT_LINE(SQLERRM);
						GOTO end_delivery;
					END IF;
			END;
<<delivery6>>
			BEGIN 
			SELECT SUM(ol_amount * ol_quantity)
			INTO out_ol_amount
			FROM order_line
			WHERE ol_o_id = tmp_o_id
				AND ol_w_id = in_w_id
				AND ol_d_id = tmp_d_id
				AND rownum < 7;

			EXCEPTION
				WHEN TOO_MANY_ROWS THEN
					DBMS_OUTPUT.PUT_LINE('(6)oops ! more than one row - tmp_o_id = ' || tmp_o_id || ' in_w_id = ' || in_w_id || ' tmp_d_id= ' || tmp_d_id);
				WHEN NO_DATA_FOUND THEN
					DBMS_OUTPUT.PUT_LINE('(6)no rows - tmp_o_id = ' || tmp_o_id || ' in_w_id = ' || in_w_id || ' tmp_d_id= ' || tmp_d_id);
				WHEN OTHERS THEN
					IF SQLCODE = -8177 THEN
						GOTO delivery6;
					ELSIF SQLCODE = -1555 THEN
						GOTO delivery6;
					ELSE
						DBMS_OUTPUT.PUT_LINE(SQLERRM);
						GOTO end_delivery;
					END IF;
			END;
<<delivery7>>
			BEGIN
			UPDATE customer
			SET c_delivery_cnt = c_delivery_cnt + 1,
			c_balance = c_balance + out_ol_amount
			WHERE c_id = out_c_id
				AND c_w_id = in_w_id
				AND c_d_id = tmp_d_id;

			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					DBMS_OUTPUT.PUT_LINE('(7)no rows - out_c_id = ' || out_c_id || ' in_w_id = ' || in_w_id || ' tmp_d_id= ' || tmp_d_id);
				WHEN OTHERS THEN
					IF SQLCODE = -8177 THEN
						GOTO delivery7;
					ELSIF SQLCODE = -1555 THEN
						GOTO delivery7;
					ELSE
						DBMS_OUTPUT.PUT_LINE(SQLERRM);
						GOTO end_delivery;
					END IF;
			END;

		END IF;

		tmp_d_id := tmp_d_id + 1;

	END LOOP;
<<end_delivery>>
	NULL;
END;
/
set echo off;
spool off;
exit sql.sqlcode;
