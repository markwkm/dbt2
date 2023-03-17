--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /
create or replace directory data_dir as '#LOCATION#';
drop table warehouse_et;
create table warehouse_et(
	w_id            number(5,0),
	w_name          varchar2(10),
	w_street_1      varchar2(20),
	w_street_2      varchar2(20),
	w_city          varchar2(20),
	w_state         char(2),
	w_zip           char(9),
	w_tax           number,
	w_ytd           number
)
organization external (
type ORACLE_LOADER
default directory data_dir
access parameters (
		records delimited by newline
		badfile 'warehouse_et.bad'
		logfile 'warehouse_et.log'
		fields terminated by '\t'
		missing field values are null
	)
	location (
		'warehouse.data'
	)
)
parallel 5
reject limit unlimited;
insert into warehouse select * from warehouse_et;
exit sql.sqlcode;
