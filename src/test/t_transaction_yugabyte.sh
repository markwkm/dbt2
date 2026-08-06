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
	BUILDDB="${TOPDIR}/build/debug/dbt2-yugabyte-build-db"
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

if ! command -v yugabyted > /dev/null 2>&1; then
	echo "SKIP: yugabyted not found in PATH"
	exit ${SKIP}
fi
if ! command -v psql > /dev/null 2>&1; then
	echo "SKIP: psql not found in PATH"
	exit ${SKIP}
fi
# YugabyteDB serves the PostgreSQL wire protocol and the test drives
# it through the same libpq client the PostgreSQL tests use.
if ! "${TXNTEST}" 2>&1 | grep -q "^PostgreSQL"; then
	echo "SKIP: dbt2-transaction-test built without libpq support"
	exit ${SKIP}
fi
if [ ! -x "${BUILDDB}" ]; then
	echo "SKIP: dbt2-yugabyte-build-db not found: ${BUILDDB}"
	exit ${SKIP}
fi

BUILDDIR=$(cd "$(dirname "${BUILDDB}")" && pwd)
DATAGENDIR=$(cd "$(dirname "${DATAGEN}")" && pwd)
SCRIPTSDIR=$(cd "${TOPDIR}/src/scripts" && pwd)
PATH="${SCRIPTSDIR}/pgsql:${SCRIPTSDIR}:${PATH}"
PATH="${BUILDDIR}:${DATAGENDIR}:${PATH}"
export PATH

TESTDB="dbt2_test"
DBT2DBNAME="${TESTDB}"
export DBT2DBNAME
PGDATABASE="${TESTDB}"
export PGDATABASE
# The user an insecure cluster creates for its first database.
PGUSER="yugabyte"
export PGUSER

# 2 warehouses so the remote warehouse paths in the Payment and
# New-Order transactions can be exercised.
WAREHOUSES=2

oneTimeSetUp() {
	YBDIR="${SHUNIT_TMPDIR}/yb"

	# Run a private cluster in the test's temporary directory.  It
	# listens on the network rather than a socket, on a loopback
	# address derived from the process id, because yugabyted takes no
	# option for the port its processes listen on.
	PGHOST="127.$((($$ / 65536) % 256)).$((($$ / 256) % 256)).$((($$ % 254) + 1))"
	export PGHOST
	PGPORT=5433
	export PGPORT

	if ! yugabyted start --base_dir="${YBDIR}" \
			--advertise_address="${PGHOST}" --insecure \
			> "${SHUNIT_TMPDIR}/yugabyted.log" 2>&1; then
		cat "${SHUNIT_TMPDIR}/yugabyted.log" 1>&2
		echo "ERROR: yugabyted start failed" 1>&2
		exit 1
	fi

	READY=0
	# shellcheck disable=SC2034 # counting attempts, value unused
	for TRY in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 \
			21 22 23 24 25 26 27 28 29 30; do
		if psql -X -At -d yugabyte -c "SELECT 1;" > /dev/null 2>&1; then
			READY=1
			break
		fi
		sleep 1
	done
	if [ ${READY} -eq 0 ]; then
		cat "${SHUNIT_TMPDIR}/yugabyted.log" 1>&2
		echo "ERROR: YugabyteDB did not accept connections" 1>&2
		exit 1
	fi

	if ! "${BUILDDB}" -l "${PGPORT}" -w ${WAREHOUSES} \
			-i "${TOPDIR}/storedproc/pgsql/pgsql"; then
		echo "ERROR: dbt2-yugabyte-build-db failed" 1>&2
		exit 1
	fi
}

oneTimeTearDown() {
	if [ ! -d "${SHUNIT_TMPDIR}/yb" ]; then
		return 0
	fi
	yugabyted stop --base_dir="${SHUNIT_TMPDIR}/yb" > /dev/null 2>&1
	return 0
}

run_transaction() {
	"${TXNTEST}" -a yugabyte -d "${PGHOST}" -t "$1" -w ${WAREHOUSES}
}

db_query() {
	psql -X -At -c "$1"
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
	assertTrue "low stock count reported" $?

	return 0
}

SHUNIT2=$(command -v shunit2)
if [ "${SHUNIT2}" = "" ]; then
	echo "ERROR: shunit2 not found in PATH" 1>&2
	exit 1
fi
# shellcheck source=/dev/null
. "${SHUNIT2}"
