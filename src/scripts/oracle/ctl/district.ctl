--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /
unrecoverable
load
append
into table dist
append
fields terminated by '\t'
(
        d_id        , 
        d_w_id      ,
        d_name      ,
        d_street_1  ,
        d_street_2  ,
        d_city      ,
        d_state     ,
        d_zip       ,
        d_tax       ,
        d_ytd       ,
        d_next_o_id
)
