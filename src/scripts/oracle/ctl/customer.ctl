--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /
unrecoverable
load
append
into table cust
append
fields terminated by '\t'
(
        c_id            ,
        c_d_id          ,
        c_w_id          ,
        c_first         ,
        c_middle        ,
        c_last          ,
        c_street_1      ,
        c_street_2      ,
        c_city          ,
        c_state         ,
        c_zip           ,
        c_phone         ,
        c_since         date "yyyy-mm-dd hh24:mi:ss",
        c_credit        ,
        c_credit_lim    ,
        c_discount      ,
        c_balance       ,
        c_ytd_payment   ,
        c_payment_cnt   ,
        c_delivery_cnt  ,
        c_data          char(500)
)
