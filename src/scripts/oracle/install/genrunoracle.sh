#!/bin/bash
##############################################################################
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
# Copyright (C) 2006-2008 Gurudas Pai & Oracle Corporation. All rights reserved.

##############################################################################

f_genrunoracle()
{
echo "Generating run related files..."
# Copy build_db.sh script to install directory
cp ${SCONFIGDIR}/build_db.sh ${ISWARE}/build_db.sh

# Copy load_db.sh script to intsall directory
cp ${SCONFIGDIR}/load_db.sh ${ISWARE}/load_db.sh

# Copy dbt_run.sh script to install directory
cp ${SCONFIGDIR}/run_db.sh ${ISWARE}/run_db.sh

# Copy validate.sh script to install directory
cp ${SCONFIGDIR}/validate.sh ${ISWARE}/validate.sh
	
# Copy loganalysis.sh script to install directory
cp ${SCONFIGDIR}/loganalysis.sh	${ISWARE}/loganalysis.sh

# Copy collectmatrix.sh script to install directory
cp ${SCONFIGDIR}/collectmetrics.sh ${ISWARE}/collectmetrics.sh
cp ${SCONFIGDIR}/count.c ${ISWARE}/count.c
	
# Copy result.sh script to install directory
cp ${SCONFIGDIR}/result.sh ${ISWARE}/result.sh
	
# Copy oracle-dbt2.sh script to install directory
cp ${SCONFIGDIR}/oracle-dbt2.sh ${ISWARE}/oracle-dbt2.sh

# Copy create_sp.sh script to install directory
cp ${SCONFIGDIR}/create_sp.sh ${ISWARE}/create_sp.sh

# Copy os-stats.sh script to install directory
cp ${SCONFIGDIR}/os-stats.sh ${ISWARE}/os-stats.sh

# Copy mix_analyzer.pl script to install directory
cp ${SRCSCRIPTS}/mix_analyzer.pl ${ISWARE}/mix_analyzer.pl
}
