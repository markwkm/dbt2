--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /
create or replace directory data_dir as '#LOCATION#';
drop table district_et;
create table district_et(
	d_id        number(2,0), 
	d_w_id      number(5,0),
	d_name      varchar2(10),
	d_street_1  varchar2(20),
	d_street_2  varchar2(20),
	d_city      varchar2(20),
	d_state     char(2),
	d_zip       char(9),
	d_tax       number,
	d_ytd       number,
	d_next_o_id number
)
organization external (
type ORACLE_LOADER
default directory data_dir
access parameters (
		records delimited by newline
		badfile 'district_et.bad'
		logfile 'district_et.log'
		fields terminated by '\t'
		missing field values are null
	)
	location (
		'district.data'
	)
)
parallel 5
reject limit unlimited;
insert into district select * from district_et;
exit sql.sqlcode;
