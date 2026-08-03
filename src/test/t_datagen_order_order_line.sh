#!/bin/sh

THISDIR=$(dirname "$0")
# shellcheck source=src/test/datagen_common.sh
. "${THISDIR}/datagen_common.sh"

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

	return 0
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

	# Generate the chunks concurrently to also catch any interference
	# between simultaneous datagen invocations.

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table orders \
			--seed $SEED -P 2 -p 1 &
	PID1=$!
	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table orders \
			--seed $SEED -P 2 -p 2 &
	PID2=$!
	wait $PID1
	assertTrue "datagen chunk 1" $?
	wait $PID2
	assertTrue "datagen chunk 2" $?

	COUNT=$(count_lines "${DATAFILE_O}.1")
	assertEquals "order top half" 150000 "$COUNT"
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

	return 0
}

# shellcheck source=/dev/null
. "${SHUNIT2}"
