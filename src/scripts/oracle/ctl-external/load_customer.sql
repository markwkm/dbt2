--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /

create or replace directory data_dir as '#LOCATION#';
drop table customer_et;
create table customer_et(
	c_id            number(5,0),
	c_d_id          number(2,0),
	c_w_id          number(5,0),
	c_first         varchar2(16),
	c_middle        char(2),
	c_last          varchar2(16),
	c_street_1      varchar2(20),
	c_street_2      varchar2(20),
	c_city          varchar2(20),
	c_state         char(2),
	c_zip           char(9),
	c_phone         char(16),
	c_since         date,
	c_credit        char(2),
	c_credit_lim    number,
	c_discount      number,
	c_balance       number,
	c_ytd_payment   number,
	c_payment_cnt   number,
	c_delivery_cnt  number,
	c_data          varchar2(500)
)
organization external (
type ORACLE_LOADER
default directory data_dir
access parameters (
		records delimited by newline
		badfile 'customer_et.bad'
		logfile 'customer_et.log'
		fields terminated by '\t'
		missing field values are null
		( c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone,
			c_since char date_format date mask "yyyy-mm-dd hh24:mi:ss", c_credit, c_credit_lim, c_discount, c_balance,
			c_ytd_payment, c_payment_cnt, c_delivery_cnt, c_data char(500)
		)
	)
	location (
		'customer.data'
	)
)
parallel 5
reject limit unlimited;
insert into customer select * from customer_et;
exit sql.sqlcode;
