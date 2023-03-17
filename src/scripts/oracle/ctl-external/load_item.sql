--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /
create or replace directory data_dir as '#LOCATION#';
drop table item_et;
create table item_et(
	i_id     number(6,0),
	i_im_id  number,
	i_name   varchar2(24),
	i_price  number,
	i_data   varchar2(50)
)
organization external (
type ORACLE_LOADER
default directory data_dir
access parameters (
		records delimited by newline
		badfile 'item_et.bad'
		logfile 'item_et.log'
		fields terminated by '\t'
		missing field values are null
	)
	location (
		'item.data'
	)
)
parallel 5
reject limit unlimited;
insert into item select * from item_et;
exit sql.sqlcode;
