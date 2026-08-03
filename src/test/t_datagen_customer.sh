#!/bin/sh

THISDIR=$(dirname "$0")
# shellcheck source=src/test/datagen_common.sh
. "${THISDIR}/datagen_common.sh"

oneTimeSetUp() {
	DATAFILE="${SHUNIT_TMPDIR}/customer.data"
	COLUMNS="1,2,3,4,5,6,7,8,9,10,11,12,14,15,16,17,18,19,20,21"
}

testSingleFile() {
	SCALE_FACTOR=1

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table customer
	assertTrue "datagen" $?
	COUNT=$(count_lines "${DATAFILE}")
	assertEquals "cardinality" 30000 "$COUNT"

	return 0
}

testPartitionedFileSplit() {
	SEED=3
	SCALE_FACTOR=10

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table customer \
			--seed $SEED
	assertTrue "datagen" $?
	COUNT=$(count_lines "${DATAFILE}")
	assertEquals "cardinality" 300000 "$COUNT"

	# Generate the chunks concurrently to also catch any interference
	# between simultaneous datagen invocations.

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table customer \
			--seed $SEED -P 2 -p 1 &
	PID1=$!
	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table customer \
			--seed $SEED -P 2 -p 2 &
	PID2=$!
	wait $PID1
	assertTrue "datagen chunk 1" $?
	wait $PID2
	assertTrue "datagen chunk 2" $?

	COUNT=$(count_lines "${DATAFILE}.1")
	assertEquals "top half" 150000 "$COUNT"
	COUNT=$(count_lines "${DATAFILE}.2")
	assertEquals "bottom half" 150000 "$COUNT"

	# Strip out timestamp column that is not stable, changes depending on when
	# data is created.

	cut -f "$COLUMNS" "${DATAFILE}" > "${SHUNIT_TMPDIR}/c.orig"

	cut -f "$COLUMNS" "${DATAFILE}.1" > "${SHUNIT_TMPDIR}/c.new"
	cut -f "$COLUMNS" "${DATAFILE}.2" >> "${SHUNIT_TMPDIR}/c.new"

	diff "${SHUNIT_TMPDIR}/c.orig" "${SHUNIT_TMPDIR}/c.new"
	assertEquals "match" 0 $?

	return 0
}

# shellcheck source=/dev/null
. "${SHUNIT2}"
