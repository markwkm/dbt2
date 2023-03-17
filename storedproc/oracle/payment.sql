--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- Based on TPC-C Standard Specification Revision 5.0 
-- /

spool ${WSRLDB}/payment.log;
set echo on;

CREATE OR REPLACE PROCEDURE payment(in_w_id          warehouse.w_id%TYPE,
					in_d_id      district.d_id%TYPE,
					in_c_id      customer.c_id%TYPE,
					in_c_w_id    customer.c_w_id%TYPE,
					in_c_d_id    customer.c_d_id%TYPE,
					in_c_last    customer.c_last%TYPE,
					in_h_amount  history.h_amount%TYPE) AS

	out_w_name     warehouse.w_name%TYPE;
	out_w_street_1 warehouse.w_street_1%TYPE;
	out_w_street_2 warehouse.w_street_2%TYPE;
	out_w_city     warehouse.w_city%TYPE;
	out_w_state    warehouse.w_state%TYPE;
	out_w_zip      warehouse.w_zip%TYPE;

	out_d_name     district.d_name%TYPE;
	out_d_street_1 district.d_street_1%TYPE;
	out_d_street_2 district.d_street_2%TYPE;
	out_d_city     district.d_city%TYPE;
	out_d_state    district.d_state%TYPE;
	out_d_zip      district.d_zip%TYPE;

	out_c_id          customer.c_id%TYPE;
	out_c_first       customer.c_first%TYPE;
	out_c_middle      customer.c_middle%TYPE;
	out_c_last        customer.c_last%TYPE;
	out_c_street_1    customer.c_street_1%TYPE;
	out_c_street_2    customer.c_street_2%TYPE;
	out_c_city        customer.c_city%TYPE;
	out_c_state       customer.c_state%TYPE;
	out_c_zip         customer.c_zip%TYPE;
	out_c_phone       customer.c_phone%TYPE;
	out_c_since       customer.c_since%TYPE;
	out_c_credit      customer.c_credit%TYPE;
	out_c_credit_lim  customer.c_credit_lim%TYPE;
	out_c_discount    customer.c_discount%TYPE;
	out_c_balance     customer.c_balance%TYPE;
	out_c_data        customer.c_data%TYPE;
	out_c_ytd_payment customer.c_ytd_payment%TYPE;


--       /* Goofy temporaty variables. */
	tmp_c_id     customer.c_id%TYPE;
	tmp_c_d_id   customer.c_d_id%TYPE;
	tmp_c_w_id   customer.c_w_id%TYPE;
	tmp_d_id     district.d_id%TYPE;
	tmp_w_id     warehouse.w_id%TYPE;
	tmp_h_amount history.h_amount%TYPE;

--       /* This one is not goofy. */
	tmp_h_data history.h_data%TYPE;

BEGIN

--	DBMS_OUTPUT.PUT_LINE('w_id = ' || in_w_id);
<<payment1>>
	BEGIN
	SELECT w_name, w_street_1, w_street_2, w_city, w_state, w_zip
	INTO out_w_name, out_w_street_1, out_w_street_2, out_w_city,
		out_w_state, out_w_zip
	FROM warehouse
	WHERE w_id = in_w_id
		AND rownum < 2;

	EXCEPTION
		WHEN TOO_MANY_ROWS THEN
			DBMS_OUTPUT.PUT_LINE('(1)oops ! more than one row in_w_id = ' || in_w_id);
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('(1)no rows - in_w_id = ' || in_w_id);
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO payment1;
			ELSIF SQLCODE = -1555 THEN
				GOTO payment1;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_payment;
			END IF;
	END;

--	DBMS_OUTPUT.PUT_LINE('out_w_name = ' || out_w_name || ' out_w_street_1 = ' || out_w_street_1);

<<payment2>>
	BEGIN
	UPDATE warehouse
	SET w_ytd = w_ytd + in_h_amount
	WHERE w_id = in_w_id;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('(2)no rows - in_w_id = ' || in_w_id);
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO payment2;
			ELSIF SQLCODE = -1555 THEN
				GOTO payment2;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_payment;
			END IF;
	END;

<<payment3>>
	BEGIN
	SELECT d_name, d_street_1, d_street_2, d_city, d_state, d_zip
	INTO out_d_name, out_d_street_1, out_d_street_2, out_d_city,
		out_d_state, out_d_zip
	FROM district
	WHERE d_id = in_d_id
		AND d_w_id = in_w_id
		AND rownum < 2;

	EXCEPTION
		WHEN TOO_MANY_ROWS THEN
			DBMS_OUTPUT.PUT_LINE('(3)oops ! more than one row in_d_id = ' || in_d_id || ' in_w_id = ' || in_w_id);
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('(3)no rows in_d_id = ' || in_d_id || ' in_w_id = ' || in_w_id);
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO payment3;
			ELSIF SQLCODE = -1555 THEN
				GOTO payment3;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_payment;
			END IF;
	END;

<<payment4>>
	BEGIN
	UPDATE district
	SET d_ytd = d_ytd + in_h_amount
	WHERE d_id = in_d_id
		AND d_w_id = in_w_id;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('(4)no rows in_d_id = ' || in_d_id || ' in_w_id = ' || in_w_id);
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO payment4;
			ELSIF SQLCODE = -1555 THEN
				GOTO payment4;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_payment;
			END IF;
	END;

--       /*
--        * Pick a customeromer by searching for c_last, should pick the one in the
--        * middle, not the first one.
--        */
	IF in_c_id = 0 THEN
<<payment5>>
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
				DBMS_OUTPUT.PUT_LINE('(5)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' in_c_last = ' || in_c_last);
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(5)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' in_c_last = ' || in_c_last);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO payment5;
				ELSIF SQLCODE = -1555 THEN
					GOTO payment5;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_payment;
				END IF;
		END;
	ELSE
		out_c_id := in_c_id;
	END IF;

<<payment6>>
	BEGIN
	SELECT c_first, c_middle, c_last, c_street_1, c_street_2, c_city,
		c_state, c_zip, c_phone, c_since, c_credit,
		c_credit_lim, c_discount, c_balance, c_data,
		c_ytd_payment
	INTO out_c_first, out_c_middle, out_c_last, out_c_street_1, out_c_street_2, out_c_city,
		out_c_state, out_c_zip, out_c_phone, out_c_since, out_c_credit,
		out_c_credit_lim, out_c_discount, out_c_balance, out_c_data,
		out_c_ytd_payment
	FROM customer
	WHERE c_w_id = in_c_w_id
		AND c_d_id = in_c_d_id
		AND c_id = out_c_id
		AND rownum < 2;

	EXCEPTION
		WHEN TOO_MANY_ROWS THEN
			DBMS_OUTPUT.PUT_LINE('(6)oops ! more than one row in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_c_id = ' || out_c_id);
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('(6)no rows in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id || ' out_c_id = ' || out_c_id);
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO payment6;
			ELSIF SQLCODE = -1555 THEN
				GOTO payment6;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_payment;
			END IF;
	END;

--       /* Check credit rating. */
        IF out_c_credit = 'BC' THEN
		tmp_c_id   := out_c_id;
		tmp_c_d_id := in_c_d_id;
		tmp_c_w_id := in_c_w_id;
		tmp_d_id   := in_d_id;
		tmp_w_id   := in_w_id;

                out_c_data := tmp_c_id || ' ' || tmp_c_d_id || ' ' || tmp_c_w_id || ' ' || tmp_d_id || ' ' || tmp_w_id;

<<payment7>>
		BEGIN
		UPDATE customer
		SET c_balance = out_c_balance - in_h_amount,
			c_ytd_payment = out_c_ytd_payment + 1,
			c_data = out_c_data
		WHERE c_id = out_c_id
			AND c_w_id = in_c_w_id
			AND c_d_id = in_c_d_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(7)no rows out_c_id = ' || out_c_id || ' in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO payment7;
				ELSIF SQLCODE = -1555 THEN
					GOTO payment7;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_payment;
				END IF;
		END;
	ELSE
<<payment8>>
		BEGIN
		UPDATE customer
		SET c_balance = out_c_balance - in_h_amount,
			c_ytd_payment = out_c_ytd_payment + 1
		WHERE c_id = out_c_id
			AND c_w_id = in_c_w_id
			AND c_d_id = in_c_d_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('(8)no rows out_c_id = ' || out_c_id || ' in_c_w_id = ' || in_c_w_id || ' in_c_d_id = ' || in_c_d_id);
			WHEN OTHERS THEN
				IF SQLCODE = -8177 THEN
					GOTO payment8;
				ELSIF SQLCODE = -1555 THEN
					GOTO payment8;
				ELSE
					DBMS_OUTPUT.PUT_LINE(SQLERRM);
					GOTO end_payment;
				END IF;
		END;
	END IF;

	tmp_h_data := out_w_name || ' ' || out_d_name;

<<payment9>>
	BEGIN
	INSERT INTO history (h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id,
		h_date, h_amount, h_data)
	VALUES (out_c_id, in_c_d_id, in_c_w_id, in_d_id, in_w_id,
		current_date, in_h_amount, tmp_h_data);
	EXCEPTION
		WHEN OTHERS THEN
			IF SQLCODE = -8177 THEN
				GOTO payment9;
			ELSIF SQLCODE = -1555 THEN
				GOTO payment9;
			ELSE
				DBMS_OUTPUT.PUT_LINE(SQLERRM);
				GOTO end_payment;
			END IF;
	END;

--       RETURN out_c_id;
<<end_payment>>
	NULL;
END payment;
/
set echo off;
spool off;

exit sql.sqlcode;
