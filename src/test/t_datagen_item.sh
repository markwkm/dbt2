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
	DATAFILE="${SHUNIT_TMPDIR}/item.data"
}

testSingleFile() {
	SCALE_FACTOR=1

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table item
	assertTrue "datagen" $?
	COUNT=$(count_lines "${DATAFILE}")
	assertEquals "cardinality" 100000 "$COUNT"
}

testPartitionedFileSplit() {
	SEED=9
	SCALE_FACTOR=10

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table item \
			--seed $SEED
	assertTrue "datagen" $?
	COUNT=$(count_lines "${DATAFILE}")
	assertEquals "cardinality" 100000 "$COUNT"

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table item \
			--seed $SEED -P 2 -p 1
	assertTrue "datagen" $?
	COUNT=$(count_lines "${DATAFILE}.1")
	assertEquals "top half" 50000 "$COUNT"

	$DATAGEN -d "$SHUNIT_TMPDIR" -w $SCALE_FACTOR --table item \
			--seed $SEED -P 2 -p 2
	assertTrue "datagen" $?
	COUNT=$(count_lines "${DATAFILE}.2")
	assertEquals "bottom half" 50000 "$COUNT"

	cat "${DATAFILE}.1" "${DATAFILE}.2" > "${DATAFILE}.rebuilt"
	diff "${DATAFILE}" "${DATAFILE}.rebuilt"
	assertEquals "match" 0 $?
}

SHUNIT2=$(command -v shunit2)
if [ "${SHUNIT2}" = "" ]; then
	echo "ERROR: shunit2 not found in PATH" 1>&2
	exit 1
fi
# shellcheck source=/dev/null
. "${SHUNIT2}"
