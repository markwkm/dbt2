#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_collectmetrics ()
{

l_result=${WSRMETRICS}
l_pathname=${WSRMETRICS}/

for i in $CLIENTS;do
	
	scp  $USER@$i:${WCLOG}/mix.log ${WSRMETRICS}/"$i"mix.log	
	mixlog=$l_pathname/"$i"mix.log

	if test ! -f $mixlog ; then echo "mix.log not generated on $i";continue;fi 
	cd ${WSWARE}
	
	l_outdir=$l_result/tmp_"$i"
	mkdir -p $l_outdir ;

	./mix_analyzer.pl --infile $mixlog --outdir $l_outdir --noplot --nostat | tee ${l_result}/metrics-$i.log
done
}
f_collectmetrics $*
