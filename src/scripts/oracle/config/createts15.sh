#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

addts.sh stok_0 $DATAFILESLOC/stok_0_0 1226M 153M>stok_0_0.out 2>&1 & 
addts.sh istok_0 $DATAFILESLOC/istok_0_0 111M 13M>istok_0_0.out 2>&1 & 
wait
addts.sh ware_0 $DATAFILESLOC/ware_0_0 26M 3M>ware_0_0.out 2>&1 & 
addts.sh item_0 $DATAFILESLOC/item_0_0 26M 3M>item_0_0.out 2>&1 & 
wait
addts.sh ordl_0 $DATAFILESLOC/ordl_0_0 1376M 172M>ordl_0_0.out 2>&1 & 
addts.sh iordr1_0 $DATAFILESLOC/iordr1_0_0 55M 6M>iordr1_0_0.out 2>&1 & 
wait
addts.sh iordr2_0 $DATAFILESLOC/iordr2_0_0 71M 8M>iordr2_0_0.out 2>&1 & 
addts.sh nord_0 $DATAFILESLOC/nord_0_0 32M 4M>nord_0_0.out 2>&1 & 
wait
addts.sh dist_0 $DATAFILESLOC/dist_0_0 26M 3M>dist_0_0.out 2>&1 & 
addtempts.sh temp_0 $DATAFILESLOC/temp_0_0 1990M 10M>temp_0_0.out 2>&1 & 
wait
addts.sh ordr_0 $DATAFILESLOC/ordr_0_0 80M 10M>ordr_0_0.out 2>&1 & 
addts.sh hist_0 $DATAFILESLOC/hist_0_0 116M 14M>hist_0_0.out 2>&1 & 
wait
addts.sh iitem_0 $DATAFILESLOC/iitem_0_0 26M 3M>iitem_0_0.out 2>&1 & 
addts.sh iware_0 $DATAFILESLOC/iware_0_0 26M 3M>iware_0_0.out 2>&1 & 
wait
addts.sh icust1_0 $DATAFILESLOC/icust1_0_0 54M 6M>icust1_0_0.out 2>&1 & 
addts.sh icust2_0 $DATAFILESLOC/icust2_0_0 89M 11M>icust2_0_0.out 2>&1 & 
wait
addts.sh idist_0 $DATAFILESLOC/idist_0_0 26M 3M>idist_0_0.out 2>&1 & 
addts.sh cust_0 $DATAFILESLOC/cust_0_0 1106M 138M>cust_0_0.out 2>&1 & 
wait
addts.sh sp_0 $DATAFILESLOC/sp_0_0 300M 1M>sp_0_0.out 2>&1 &
wait
wait
