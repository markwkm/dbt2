--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /
unrecoverable
load
append
into table hist
append
fields terminated by '\t'
(
        h_c_id     ,
        h_c_d_id   ,
        h_c_w_id   ,
        h_d_id     ,
        h_w_id     ,
        h_date     date "yyyy-mm-dd hh24:mi:ss",
        h_amount   ,
        h_data
)
