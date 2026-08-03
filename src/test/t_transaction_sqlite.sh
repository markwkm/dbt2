#!/bin/sh

THISDIR=$(dirname "$0")
TOPDIR="${THISDIR}/../.."

# Binary and script locations may be given as arguments, otherwise
# assume a debug build exists.
if [ $# -gt 0 ]; then
	DATAGEN="$1"
	shift
else
	DATAGEN="${TOPDIR}/build/debug/src/dbt2-datagen"
fi
if [ $# -gt 0 ]; then
	TXNTEST="$1"
	shift
else
	TXNTEST="${TOPDIR}/build/debug/src/dbt2-transaction-test"
fi
if [ $# -gt 0 ]; then
	BUILDDB="$1"
	shift
else
	BUILDDB="${TOPDIR}/build/debug/dbt2-sqlite-build-db"
fi

if [ ! -x "${DATAGEN}" ]; then
	echo "ERROR: dbt2-datagen not found: ${DATAGEN}" 1>&2
	exit 1
fi
if [ ! -x "${TXNTEST}" ]; then
	echo "ERROR: dbt2-transaction-test not found: ${TXNTEST}" 1>&2
	exit 1
fi

# Exit code registered with CTest as SKIP_RETURN_CODE so missing
# prerequisites report as skipped instead of failed.
SKIP=77

if ! command -v sqlite3 > /dev/null 2>&1; then
	echo "SKIP: sqlite3 not found in PATH"
	exit ${SKIP}
fi
if ! "${TXNTEST}" 2>&1 | grep -q "^SQLite:"; then
	echo "SKIP: dbt2-transaction-test built without SQLite support"
	exit ${SKIP}
fi
if [ ! -x "${BUILDDB}" ]; then
	echo "SKIP: dbt2-sqlite-build-db not found: ${BUILDDB}"
	exit ${SKIP}
fi

# Two warehouses so the remote warehouse paths in the Payment and
# New-Order transactions can be exercised.
WAREHOUSES=2

oneTimeSetUp() {
	DATADIR="${SHUNIT_TMPDIR}/data"
	DBFILE="dbt2.db"

	mkdir -p "${DATADIR}"
	if ! ${DATAGEN} -d "${DATADIR}" -w ${WAREHOUSES}; then
		echo "ERROR: dbt2-datagen failed" 1>&2
		exit 1
	fi
	if ! "${BUILDDB}" -d "${SHUNIT_TMPDIR}/${DBFILE}" -f "${DATADIR}" \
			-w ${WAREHOUSES}; then
		echo "ERROR: dbt2-sqlite-build-db failed" 1>&2
		exit 1
	fi
}

run_transaction() {
	"${TXNTEST}" -a sqlite -d "${SHUNIT_TMPDIR}/${DBFILE}" -t "$1" \
			-w ${WAREHOUSES}
}

db_query() {
	sqlite3 "${SHUNIT_TMPDIR}/${DBFILE}" "$1"
}

testDelivery() {
	BEFORE=$(db_query "SELECT count(*) FROM new_order;")

	OUTPUT=$(run_transaction d)
	RC=$?
	echo "${OUTPUT}"
	assertTrue "delivery" ${RC}

	# One new_order row is consumed per district of the warehouse.
	AFTER=$(db_query "SELECT count(*) FROM new_order;")
	assertEquals "new_order rows consumed" $((BEFORE - 10)) "${AFTER}"

	return 0
}

testNewOrder() {
	BEFORE=$(db_query "SELECT count(*) FROM orders;")

	OUTPUT=$(run_transaction n)
	RC=$?
	echo "${OUTPUT}"
	assertTrue "new order" ${RC}

	# About 1% of New-Order transactions intentionally roll back.
	AFTER=$(db_query "SELECT count(*) FROM orders;")
	if echo "${OUTPUT}" | grep -q "transaction rolled back"; then
		assertEquals "order row rolled back" "${BEFORE}" "${AFTER}"
	else
		assertEquals "order row created" $((BEFORE + 1)) "${AFTER}"
		echo "${OUTPUT}" | grep -q "^total_amount = 0.00$"
		assertFalse "total_amount returned" $?
	fi

	return 0
}

testOrderStatus() {
	OUTPUT=$(run_transaction o)
	RC=$?
	echo "${OUTPUT}"
	assertTrue "order status" ${RC}

	# Every customer has an order in the initial population.
	echo "${OUTPUT}" | grep -q "^o_id = 0$"
	assertFalse "existing order found" $?

	return 0
}

testPayment() {
	BEFORE=$(db_query "SELECT count(*) FROM history;")

	OUTPUT=$(run_transaction p)
	RC=$?
	echo "${OUTPUT}"
	assertTrue "payment" ${RC}

	AFTER=$(db_query "SELECT count(*) FROM history;")
	assertEquals "history row created" $((BEFORE + 1)) "${AFTER}"

	return 0
}

testStockLevel() {
	OUTPUT=$(run_transaction s)
	RC=$?
	echo "${OUTPUT}"
	assertTrue "stock level" ${RC}

	echo "${OUTPUT}" | grep -q "^low_stock = "
	assertTrue "low stock count returned" $?

	return 0
}

SHUNIT2=$(command -v shunit2)
if [ "${SHUNIT2}" = "" ]; then
	echo "ERROR: shunit2 not found in PATH" 1>&2
	exit 1
fi
# shellcheck source=/dev/null
. "${SHUNIT2}"
