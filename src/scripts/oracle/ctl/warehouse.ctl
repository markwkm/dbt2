--
-- This file is released under the terms of the Artistic License.  Please see
-- the file LICENSE, included in this package, for details.
-- Copyright (C) 2006 Anurag Vora & Oracle Corporation. All rights reserved.
-- /
unrecoverable
load
append
into table ware
append
fields terminated by '\t'
(
        w_id            ,
        w_name          ,
        w_street_1      ,
        w_street_2      ,
        w_city          ,
        w_state         ,
        w_zip           ,
        w_tax           ,
        w_ytd
)
