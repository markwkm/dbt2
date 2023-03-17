--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /

create or replace directory data_dir as '#LOCATION#';
drop table order_et;
create table order_et(
        o_id          number,
        o_d_id        number,
        o_w_id        number,
        o_c_id        number,
        o_entry_d     date,
        o_carrier_id  number,
        o_ol_cnt      number,
        o_all_local   number
)
organization external (
type ORACLE_LOADER
default directory data_dir
access parameters (
		records delimited by newline
		badfile 'order_et.bad'
		logfile 'order_et.log'
		fields terminated by '\t'
		missing field values are null
		( o_id, o_d_id, o_w_id, o_c_id, 
			o_entry_d char date_format date mask "yyyy-mm-dd hh24:mi:ss", o_carrier_id, o_ol_cnt, o_all_local
		)
	)
	location (
		'order.data'
	)
)
parallel 5
reject limit unlimited;
insert into orders select * from order_et;
exit sql.sqlcode;
