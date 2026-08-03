#!/bin/sh

THISDIR=$(dirname "$0")
# shellcheck source=src/test/datagen_common.sh
. "${THISDIR}/datagen_common.sh"

oneTimeSetUp() {
	SEED=23

	mkdir -p "${SHUNIT_TMPDIR}/1"

	# Generate 1 warehouse.
	$DATAGEN -d "${SHUNIT_TMPDIR}/1" -w 1 --table warehouse --seed $SEED

	# Generate a 10 warehouses datafile and ten 1 warehouse data files.
	# Generate the chunks concurrently to also catch any interference
	# between simultaneous datagen invocations.
	SCALE_FACTOR=10
	mkdir -p "${SHUNIT_TMPDIR}/${SCALE_FACTOR}"
	DATAFILE="${SHUNIT_TMPDIR}/${SCALE_FACTOR}/warehouse.data"
	$DATAGEN -d "${SHUNIT_TMPDIR}/${SCALE_FACTOR}" -w $SCALE_FACTOR \
			--table warehouse --seed $SEED
	for PART in 1 2 3 4 5 6 7 8 9 10; do
		$DATAGEN -d "${SHUNIT_TMPDIR}/${SCALE_FACTOR}" -w $SCALE_FACTOR \
				--table warehouse --seed $SEED -P $SCALE_FACTOR -p $PART &
	done
	wait
	for PART in 1 2 3 4 5 6 7 8 9 10; do
		cat "${DATAFILE}.${PART}" >> "${DATAFILE}.rebuilt"
	done

	# Generate a 100 warehouse datafile and two 50 warehouse data files.
	SCALE_FACTOR=100
	mkdir -p "${SHUNIT_TMPDIR}/${SCALE_FACTOR}"
	DATAFILE="${SHUNIT_TMPDIR}/${SCALE_FACTOR}/warehouse.data"
	$DATAGEN -d "${SHUNIT_TMPDIR}/${SCALE_FACTOR}" -w $SCALE_FACTOR \
			--table warehouse --seed $SEED
	$DATAGEN -d "${SHUNIT_TMPDIR}/${SCALE_FACTOR}" -w $SCALE_FACTOR \
			--table warehouse --seed $SEED -P 2 -p 1 &
	PID1=$!
	$DATAGEN -d "${SHUNIT_TMPDIR}/${SCALE_FACTOR}" -w $SCALE_FACTOR \
			--table warehouse --seed $SEED -P 2 -p 2 &
	PID2=$!
	wait $PID1
	wait $PID2
}

testSingleFileCardinality() {
	SCALE_FACTOR=1
	DATAFILE="${SHUNIT_TMPDIR}/1/warehouse.data"

	COUNT=$(count_lines "${DATAFILE}")
	assertEquals "cardinality" $SCALE_FACTOR "$COUNT"

	return 0
}

testPartitionedFileByLine() {
	SCALE_FACTOR=10
	DATAFILE="${SHUNIT_TMPDIR}/${SCALE_FACTOR}/warehouse.data"

	COUNT=$(count_lines "${DATAFILE}")
	assertEquals "cardinality" $SCALE_FACTOR "$COUNT"

	diff "${DATAFILE}" "${DATAFILE}.rebuilt"
	assertEquals "match" 0 $?

	return 0
}

testPartitionedFileSplit() {
	SCALE_FACTOR=100
	DATAFILE="${SHUNIT_TMPDIR}/${SCALE_FACTOR}/warehouse.data"

	COUNT=$(count_lines "${DATAFILE}")
	assertEquals "cardinality" $SCALE_FACTOR "$COUNT"

	cat "${DATAFILE}.1" "${DATAFILE}.2" > "${DATAFILE}.rebuilt"
	diff "${DATAFILE}" "${DATAFILE}.rebuilt"
	assertEquals "match" 0 $?

	return 0
}

# shellcheck source=/dev/null
. "${SHUNIT2}"
