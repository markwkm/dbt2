# shellcheck shell=sh
# Common setup for the datagen tests.  Sourced, not executed: expects the
# caller to set THISDIR and consumes the caller's positional parameters.

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

SHUNIT2=$(command -v shunit2)
if [ "${SHUNIT2}" = "" ]; then
	echo "ERROR: shunit2 not found in PATH" 1>&2
	exit 1
fi

count_lines() {
	wc -l < "$1" | tr -d "[:space:]"
}
