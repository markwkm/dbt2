--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /
unrecoverable
load
append
into table ordl
append
fields terminated by '\t'
(
        ol_o_id        ,
        ol_d_id        ,
        ol_w_id        ,
        ol_number      ,
        ol_i_id        ,
        ol_supply_w_id ,
        ol_delivery_d  date "yyyy-mm-dd hh24:mi:ss",
        ol_quantity    ,
        ol_amount      ,
        ol_dist_info
)
