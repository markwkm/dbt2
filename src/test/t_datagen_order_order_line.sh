#!/bin/sh

THISDIR=$(dirname "$0")
TOPDIR="${THISDIR}/../.."

# The location of the datagen binary may be given as the first argument,
# otherwise assume a debug build exists.
if [ $# -gt 0 ]; then
	DATAGEN="$1"
	shift
else
	DATAGEN="${TOPDIR}/build/debug/src/dbt2-datagen"
fi

if [ ! -x "${DATAGEN}" ]; then
	echo "ERROR: dbt2-datagen not found: ${DATAGEN}" 1>&2
	exit 1
fi

count_lines() {
	wc -l < "$1" | tr -d "[:space:]"
}

oneTimeSetUp() {
	DATAFILE_O="${SHUNIT_TMPDIR}/order.data"
	DATAFILE_OL="${SHUNIT_TMPDIR}/order_line.data"
	COLUMNS_O="1,2,3,4,6,7,8"
	COLUMNS_OL="1,2,3,4,5,6,8,9,10"
}

testSingleFile() {
	SCALE_FACTOR=1

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table orders
	assertTrue "datagen" $?
	COUNT=$(count_lines "${DATAFILE_O}")
	assertEquals "order cardinality" 30000 "$COUNT"

	# order_line rows can vary, can't predict and test number of rows
	# generated.
}

testPartitionedFileSplit() {
	SEED=15
	SCALE_FACTOR=10

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table orders \
			--seed $SEED
	assertTrue "datagen" $?
	COUNT=$(count_lines "${DATAFILE_O}")
	assertEquals "order cardinality" 300000 "$COUNT"

	# order_line rows can vary, and should be stable when we fix the seed, but
	# just test (further down) whether the data matches if it's partitioned.

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table orders \
			--seed $SEED -P 2 -p 1
	assertTrue "datagen" $?
	COUNT=$(count_lines "${DATAFILE_O}.1")
	assertEquals "order top half" 150000 "$COUNT"

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table orders \
			--seed $SEED -P 2 -p 2
	assertTrue "datagen" $?
	COUNT=$(count_lines "${DATAFILE_O}.2")
	assertEquals "order bottom half" 150000 "$COUNT"

	# Strip out timestamp column that is not stable, changes depending on when
	# data is created.

	cut -f "$COLUMNS_O" "${DATAFILE_O}" > "${SHUNIT_TMPDIR}/o.orig"

	cut -f "$COLUMNS_O" "${DATAFILE_O}.1" > "${SHUNIT_TMPDIR}/o.new"
	cut -f "$COLUMNS_O" "${DATAFILE_O}.2" >> "${SHUNIT_TMPDIR}/o.new"

	diff "${SHUNIT_TMPDIR}/o.orig" "${SHUNIT_TMPDIR}/o.new"
	assertEquals "order match" 0 $?

	cut -f "$COLUMNS_OL" "${DATAFILE_OL}" > "${SHUNIT_TMPDIR}/ol.orig"

	cut -f "$COLUMNS_OL" "${DATAFILE_OL}.1" > "${SHUNIT_TMPDIR}/ol.new"
	cut -f "$COLUMNS_OL" "${DATAFILE_OL}.2" >> "${SHUNIT_TMPDIR}/ol.new"

	diff "${SHUNIT_TMPDIR}/ol.orig" "${SHUNIT_TMPDIR}/ol.new"
	assertEquals "order_line match" 0 $?
}

SHUNIT2=$(command -v shunit2)
if [ "${SHUNIT2}" = "" ]; then
	echo "ERROR: shunit2 not found in PATH" 1>&2
	exit 1
fi
# shellcheck source=/dev/null
. "${SHUNIT2}"
