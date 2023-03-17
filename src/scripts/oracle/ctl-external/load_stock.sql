--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /
create or replace directory data_dir as '#LOCATION#';
drop table stock_et;
create table stock_et(
	s_i_id        number(6,0),
	s_w_id        number(5,0),
	s_quantity    number,
	s_dist_01     char(24),
	s_dist_02     char(24),
	s_dist_03     char(24),
	s_dist_04     char(24),
	s_dist_05     char(24),
	s_dist_06     char(24),
	s_dist_07     char(24),
	s_dist_08     char(24),
	s_dist_09     char(24),
	s_dist_10     char(24),
	s_ytd         number,
	s_order_cnt   number,
	s_remote_cnt  number,
	s_data        varchar2(50)
)
organization external (
type ORACLE_LOADER
default directory data_dir
access parameters (
		records delimited by newline
		badfile 'stock_et.bad'
		logfile 'stock_et.log'
		fields terminated by '\t'
		missing field values are null
	)
	location (
		'stock.data'
	)
)
parallel 5
reject limit unlimited;
insert into stock select * from stock_et;
exit sql.sqlcode;
