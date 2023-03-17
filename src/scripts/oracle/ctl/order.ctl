--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /
unrecoverable
load
append
into table ordr
append
fields terminated by '\t'
(
        o_id          ,
        o_d_id        ,
        o_w_id        ,
        o_c_id        ,
        o_entry_d     date "yyyy-mm-dd hh24:mi:ss",
        o_carrier_id  ,
        o_ol_cnt      ,
        o_all_local
)
