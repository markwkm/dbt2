--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /
create or replace directory data_dir as '#LOCATION#';
drop table history_et;
create table history_et(
	h_c_id     number,
	h_c_d_id   number,
	h_c_w_id   number,
	h_d_id     number,
	h_w_id     number,
	h_date     date,
	h_amount   number,
	h_data     varchar2(24)
)
organization external (
type ORACLE_LOADER
default directory data_dir
access parameters (
		records delimited by newline
		badfile 'history_et.bad'
		logfile 'history_et.log'
		fields terminated by '\t'
		missing field values are null
		( h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id,
			h_date char date_format date mask "yyyy-mm-dd hh24:mi:ss", h_amount, h_data
		)
	)
	location (
		'history.data'
	)
)
parallel 5
reject limit unlimited;
insert into history select * from history_et;
exit sql.sqlcode;
