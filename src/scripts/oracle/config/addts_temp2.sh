#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

addtempts.sh temp_0 $TMPTSLOC/temp_0_0 1993M 10M>temp_0_0.out 2>&1  
wait
wait
mv *.out ${WSRLDB}

