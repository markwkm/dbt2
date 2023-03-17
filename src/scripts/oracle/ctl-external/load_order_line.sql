--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /

create or replace directory data_dir as '#LOCATION#';
drop table order_line_et;
create table order_line_et(
        ol_o_id        number,
        ol_d_id        number,
        ol_w_id        number,
        ol_number      number,
        ol_i_id        number,
        ol_supply_w_id number,
        ol_delivery_d  date,
        ol_quantity    number,
        ol_amount      number,
        ol_dist_info   char(24)
)
organization external (
type ORACLE_LOADER
default directory data_dir
access parameters (
		records delimited by newline
		badfile 'order_line_et.bad'
		logfile 'order_line_et.log'
		fields terminated by '\t'
		missing field values are null
		( ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id,
			ol_delivery_d char date_format date mask "yyyy-mm-dd hh24:mi:ss", ol_quantity, ol_amount, ol_dist_info
		)
	)
	location (
		'order_line.data'
	)
)
parallel 5
reject limit unlimited;
insert into order_line select * from order_line_et;
exit sql.sqlcode;
