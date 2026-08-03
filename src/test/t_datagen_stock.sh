#!/bin/sh

THISDIR=$(dirname "$0")
# shellcheck source=src/test/datagen_common.sh
. "${THISDIR}/datagen_common.sh"

oneTimeSetUp() {
	DATAFILE="${SHUNIT_TMPDIR}/stock.data"
}

testSingleFile() {
	SCALE_FACTOR=1

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table stock
	assertTrue "datagen" $?
	COUNT=$(count_lines "${DATAFILE}")
	assertEquals "cardinality" 100000 "$COUNT"

	return 0
}

testPartitionedFileSplit() {
	SEED=19
	SCALE_FACTOR=10

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table stock \
			--seed $SEED
	assertTrue "datagen" $?
	COUNT=$(count_lines "${DATAFILE}")
	assertEquals "cardinality" 1000000 "$COUNT"

	# Generate the chunks concurrently to also catch any interference
	# between simultaneous datagen invocations.

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table stock \
			--seed $SEED -P 2 -p 1 &
	PID1=$!
	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table stock \
			--seed $SEED -P 2 -p 2 &
	PID2=$!
	wait $PID1
	assertTrue "datagen chunk 1" $?
	wait $PID2
	assertTrue "datagen chunk 2" $?

	COUNT=$(count_lines "${DATAFILE}.1")
	assertEquals "top half" 500000 "$COUNT"
	COUNT=$(count_lines "${DATAFILE}.2")
	assertEquals "bottom half" 500000 "$COUNT"

	cat "${DATAFILE}.1" "${DATAFILE}.2" > "${DATAFILE}.rebuilt"
	diff "${DATAFILE}" "${DATAFILE}.rebuilt"
	assertEquals "match" 0 $?

	return 0
}

# shellcheck source=/dev/null
. "${SHUNIT2}"
