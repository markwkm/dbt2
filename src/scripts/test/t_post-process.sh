#!/bin/sh

THISDIR=$(dirname "$0")
TOPDIR="${THISDIR}/../../.."

# The location of the generated sqlite3 post-process script may be given as
# the first argument, otherwise assume a debug build exists.
if [ $# -gt 0 ]; then
	POSTPROCESS="$1"
	shift
else
	POSTPROCESS="${TOPDIR}/build/debug/dbt2-post-process.sqlite3"
fi

oneTimeSetUp() {
	ACTUALOUTPUT="${SHUNIT_TMPDIR}/summary.rst"
	EXPECTEDOUTPUT="${TOPDIR}/src/scripts/test/summary.rst.expected"
	export PATH="${TOPDIR}/build/debug:${TOPDIR}/src/scripts:${PATH}"
}

testPostProcessR() {
	if ! command -v R > /dev/null 2>&1; then
		startSkipping
		assertTrue "R not installed" 0
		endSkipping
		return 0
	fi

	# shellcheck disable=SC2086
	find ${TOPDIR}/src/scripts/test -name "mix-*.log" -print0 | \
			xargs -0 ${TOPDIR}/src/scripts/dbt2-post-process.r \
			> "$ACTUALOUTPUT"
	diff "$ACTUALOUTPUT" "$EXPECTEDOUTPUT"
	assertEquals "match" 0 $?

	return 0
}

testPostProcessSQLite() {
	if ! command -v sqlite3 > /dev/null 2>&1; then
		startSkipping
		assertTrue "sqlite3 not installed" 0
		endSkipping
		return 0
	fi
	if [ ! -x "${POSTPROCESS}" ]; then
		fail "dbt2-post-process.sqlite3 not found: ${POSTPROCESS}"
		return 0
	fi

	# shellcheck disable=SC2086
	find ${TOPDIR}/src/scripts/test -name "mix-*.log" -print0 | \
			xargs -0 "${POSTPROCESS}" \
			> "$ACTUALOUTPUT"
	diff "$ACTUALOUTPUT" "$EXPECTEDOUTPUT"
	assertEquals "match" 0 $?

	return 0
}

SHUNIT2=$(command -v shunit2)
if [ "${SHUNIT2}" = "" ]; then
	echo "ERROR: shunit2 not found in PATH" 1>&2
	exit 1
fi
# shellcheck source=/dev/null
. "${SHUNIT2}"
