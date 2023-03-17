#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

addts.sh stok_0 $DATAFILESLOC/stok_0_0 6426M 803M>stok_0_0.out 2>&1 & 
addts.sh istok_0 $DATAFILESLOC/istok_0_0 482M 60M>istok_0_0.out 2>&1 & 
wait
addts.sh ware_0 $DATAFILESLOC/ware_0_0 26M 3M>ware_0_0.out 2>&1 & 
addts.sh item_0 $DATAFILESLOC/item_0_0 29M 3M>item_0_0.out 2>&1 & 
wait
addts.sh ordl_0 $DATAFILESLOC/ordl_0_0 7226M 903M>ordl_0_0.out 2>&1 & 
addts.sh iordr1_0 $DATAFILESLOC/iordr1_0_0 182M 22M>iordr1_0_0.out 2>&1 & 
wait
addts.sh iordr2_0 $DATAFILESLOC/iordr2_0_0 266M 33M>iordr2_0_0.out 2>&1 & 
addts.sh nord_0 $DATAFILESLOC/nord_0_0 62M 7M>nord_0_0.out 2>&1 & 
wait
addts.sh dist_0 $DATAFILESLOC/dist_0_0 29M 3M>dist_0_0.out 2>&1 & 
addtempts.sh temp_0 $DATAFILESLOC/temp_0_0 4795M 10M>temp_0_0.out 2>&1 & 
wait
addts.sh ordr_0 $DATAFILESLOC/ordr_0_0 314M 39M>ordr_0_0.out 2>&1 & 
addts.sh hist_0 $DATAFILESLOC/hist_0_0 506M 63M>hist_0_0.out 2>&1 & 
wait
addts.sh iitem_0 $DATAFILESLOC/iitem_0_0 26M 3M>iitem_0_0.out 2>&1 & 
addts.sh iware_0 $DATAFILESLOC/iware_0_0 26M 3M>iware_0_0.out 2>&1 & 
wait
addts.sh icust1_0 $DATAFILESLOC/icust1_0_0 177M 22M>icust1_0_0.out 2>&1 & 
addts.sh icust2_0 $DATAFILESLOC/icust2_0_0 362M 45M>icust2_0_0.out 2>&1 & 
wait
addts.sh idist_0 $DATAFILESLOC/idist_0_0 26M 3M>idist_0_0.out 2>&1 & 
addts.sh cust_0 $DATAFILESLOC/cust_0_0 5786M 723M>cust_0_0.out 2>&1 & 
wait
addts.sh sp_0 $DATAFILESLOC/sp_0_0 300M 1M>sp_0_0.out 2>&1 &
wait
wait

