--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /

create or replace directory data_dir as '#LOCATION#';
drop table new_order_et;
create table new_order_et(
        no_o_id       number,
        no_d_id       number,
        no_w_id       number
)
organization external (
type ORACLE_LOADER
default directory data_dir
access parameters (
		records delimited by newline
		badfile 'new_order_et.bad'
		logfile 'new_order_et.log'
		fields terminated by '\t'
		missing field values are null
	)
	location (
		'new_order.data'
	)
)
parallel 5
reject limit unlimited;
insert into new_order select * from new_order_et;
exit sql.sqlcode;
