--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
--
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- Copyright The DBT-2 Authors
--
-- Based on TPC-C Standard Specification Revision 5.11 Clause 2.5.2.
--
-- Output parameters for CHAR columns are declared VARCHAR2: a CHAR
-- OUT parameter is blank padded past the caller's buffer, which the
-- OCI caller receives as a truncated value with the indicator set.
--

CREATE OR REPLACE PROCEDURE payment(in_w_id     warehouse.w_id%TYPE,
					in_d_id     district.d_id%TYPE,
					in_c_id     customer.c_id%TYPE,
					in_c_w_id   customer.c_w_id%TYPE,
					in_c_d_id   customer.c_d_id%TYPE,
					in_c_last   customer.c_last%TYPE,
					in_h_amount history.h_amount%TYPE,
					out_w_name     OUT warehouse.w_name%TYPE,
					out_w_street_1 OUT warehouse.w_street_1%TYPE,
					out_w_street_2 OUT warehouse.w_street_2%TYPE,
					out_w_city     OUT warehouse.w_city%TYPE,
					out_w_state    OUT VARCHAR2,
					out_w_zip      OUT VARCHAR2,
					out_d_name     OUT district.d_name%TYPE,
					out_d_street_1 OUT district.d_street_1%TYPE,
					out_d_street_2 OUT district.d_street_2%TYPE,
					out_d_city     OUT district.d_city%TYPE,
					out_d_state    OUT VARCHAR2,
					out_d_zip      OUT VARCHAR2,
					out_c_id         OUT customer.c_id%TYPE,
					out_c_first      OUT customer.c_first%TYPE,
					out_c_middle     OUT VARCHAR2,
					out_c_last       OUT customer.c_last%TYPE,
					out_c_street_1   OUT customer.c_street_1%TYPE,
					out_c_street_2   OUT customer.c_street_2%TYPE,
					out_c_city       OUT customer.c_city%TYPE,
					out_c_state      OUT VARCHAR2,
					out_c_zip        OUT VARCHAR2,
					out_c_phone      OUT VARCHAR2,
					out_c_since      OUT VARCHAR2,
					out_c_credit     OUT VARCHAR2,
					out_c_credit_lim OUT customer.c_credit_lim%TYPE,
					out_c_discount   OUT customer.c_discount%TYPE,
					out_c_balance    OUT customer.c_balance%TYPE,
					out_c_data       OUT customer.c_data%TYPE) AS

	out_c_ytd_payment customer.c_ytd_payment%TYPE;

	tmp_count  INTEGER;
	tmp_h_data history.h_data%TYPE;

BEGIN

	SELECT w_name, w_street_1, w_street_2, w_city, w_state, w_zip
	INTO out_w_name, out_w_street_1, out_w_street_2, out_w_city,
		out_w_state, out_w_zip
	FROM warehouse
	WHERE w_id = in_w_id
	FOR UPDATE;

	UPDATE warehouse
	SET w_ytd = w_ytd + in_h_amount
	WHERE w_id = in_w_id;

	SELECT d_name, d_street_1, d_street_2, d_city, d_state, d_zip
	INTO out_d_name, out_d_street_1, out_d_street_2, out_d_city,
		out_d_state, out_d_zip
	FROM district
	WHERE d_id = in_d_id
		AND d_w_id = in_w_id
	FOR UPDATE;

	UPDATE district
	SET d_ytd = d_ytd + in_h_amount
	WHERE d_id = in_d_id
		AND d_w_id = in_w_id;

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

	SELECT c_first, c_middle, c_last, c_street_1, c_street_2, c_city,
		c_state, c_zip, c_phone,
		TO_CHAR(c_since, 'YYYY-MM-DD HH24:MI:SS'), c_credit,
		c_credit_lim, c_discount, c_balance, c_data,
		c_ytd_payment
	INTO out_c_first, out_c_middle, out_c_last, out_c_street_1,
		out_c_street_2, out_c_city, out_c_state, out_c_zip,
		out_c_phone, out_c_since, out_c_credit, out_c_credit_lim,
		out_c_discount, out_c_balance, out_c_data, out_c_ytd_payment
	FROM customer
	WHERE c_w_id = in_c_w_id
		AND c_d_id = in_c_d_id
		AND c_id = out_c_id
	FOR UPDATE;

	-- Check credit rating.
	IF out_c_credit = 'BC' THEN
		out_c_data := out_c_id || ' ' || in_c_d_id || ' '
				|| in_c_w_id || ' ' || in_d_id || ' ' || in_w_id
				|| ' ' || TO_CHAR(in_h_amount, 'FM99990.00');

		UPDATE customer
		SET c_balance = c_balance - in_h_amount,
			c_ytd_payment = c_ytd_payment + in_h_amount,
			c_payment_cnt = c_payment_cnt + 1,
			c_data = SUBSTR(out_c_data || ' ' || c_data, 1, 500)
		WHERE c_id = out_c_id
			AND c_w_id = in_c_w_id
			AND c_d_id = in_c_d_id;

		SELECT SUBSTR(c_data, 1, 200)
		INTO out_c_data
		FROM customer
		WHERE c_id = out_c_id
			AND c_w_id = in_c_w_id
			AND c_d_id = in_c_d_id;
	ELSE
		UPDATE customer
		SET c_balance = c_balance - in_h_amount,
			c_ytd_payment = c_ytd_payment + in_h_amount,
			c_payment_cnt = c_payment_cnt + 1
		WHERE c_id = out_c_id
			AND c_w_id = in_c_w_id
			AND c_d_id = in_c_d_id;
	END IF;

	tmp_h_data := out_w_name || '    ' || out_d_name;
	INSERT INTO history (h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id,
		h_date, h_amount, h_data)
	VALUES (out_c_id, in_c_d_id, in_c_w_id, in_d_id, in_w_id,
		current_timestamp, in_h_amount, tmp_h_data);

	-- The balance as of after this payment.
	out_c_balance := out_c_balance - in_h_amount;

END payment;
/
