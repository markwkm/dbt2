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
	BUILDDB="${TOPDIR}/build/debug/dbt2-cockroach-build-db"
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

if ! command -v cockroach > /dev/null 2>&1; then
	echo "SKIP: cockroach not found in PATH"
	exit ${SKIP}
fi
if ! command -v psql > /dev/null 2>&1; then
	echo "SKIP: psql not found in PATH"
	exit ${SKIP}
fi
# The CockroachDB client side SQL is compiled against libpq, which the
# usage message reports as PostgreSQL support.
if ! "${TXNTEST}" 2>&1 | grep -q "^PostgreSQL"; then
	echo "SKIP: dbt2-transaction-test built without libpq support"
	exit ${SKIP}
fi
if [ ! -x "${BUILDDB}" ]; then
	echo "SKIP: dbt2-cockroach-build-db not found: ${BUILDDB}"
	exit ${SKIP}
fi

BUILDDIR=$(cd "$(dirname "${BUILDDB}")" && pwd)
DATAGENDIR=$(cd "$(dirname "${DATAGEN}")" && pwd)
PATH="${BUILDDIR}:${DATAGENDIR}:${PATH}"
export PATH

TESTDB="dbt2_test"
# dbt2-cockroach-build-db takes no database name argument; the scripts
# it calls and the psql that datagen pipes its data into both read the
# name from the environment.
DBT2DBNAME="${TESTDB}"
export DBT2DBNAME
PGDATABASE="${TESTDB}"
export PGDATABASE
# An insecure single node cluster has only the root user.
PGUSER="root"
export PGUSER
# A cluster that exists for the length of one test has no reason to
# report usage back to Cockroach Labs.
COCKROACH_SKIP_ENABLING_DIAGNOSTIC_REPORTING="true"
export COCKROACH_SKIP_ENABLING_DIAGNOSTIC_REPORTING

# 2 warehouses so the remote warehouse paths in the Payment and
# New-Order transactions can be exercised.
WAREHOUSES=2

oneTimeSetUp() {
	CRDBDATA="${SHUNIT_TMPDIR}/crdbdata"
	CRDBPIDFILE="${SHUNIT_TMPDIR}/cockroach.pid"

	# Run a private single node cluster in the test's temporary
	# directory, reachable only through a socket there.  Three ports
	# are still needed because the cluster always listens on the
	# network: one for the node to node protocol, one for SQL, and one
	# for the web interface.  They are derived from the process id, in
	# groups of three, so concurrent runs cannot overlap.
	PGPORT=$((10240 + ($$ % 18000) * 3))
	CRDBSQLPORT=$((PGPORT + 1))
	CRDBHTTPPORT=$((PGPORT + 2))
	export PGPORT

	# The socket is named for the node to node port rather than the
	# SQL port, which is the number libpq builds its socket path from,
	# so PGPORT is set to that one.
	PGHOST="${SHUNIT_TMPDIR}"
	export PGHOST

	# The cluster sizes its caches as a share of the system memory and
	# reserves disk for temporary storage and for an emergency
	# ballast, which is far more than a 2 warehouse database needs on
	# a system shared with other tests.
	if ! cockroach start-single-node --insecure \
			--store="path=${CRDBDATA},ballast-size=0" \
			--listen-addr="localhost:${PGPORT}" \
			--sql-addr="localhost:${CRDBSQLPORT}" \
			--http-addr="localhost:${CRDBHTTPPORT}" \
			--socket-dir="${SHUNIT_TMPDIR}" \
			--pid-file="${CRDBPIDFILE}" \
			--cache=64MiB --max-sql-memory=256MiB \
			--max-disk-temp-storage=1GiB --background \
			> "${SHUNIT_TMPDIR}/cockroach.log" 2>&1; then
		cat "${SHUNIT_TMPDIR}/cockroach.log" 1>&2
		echo "ERROR: cockroach start-single-node failed" 1>&2
		exit 1
	fi

	# --background returns once the cluster answers on the network,
	# which it does before the socket exists, so wait for a connection
	# through the socket to succeed.
	READY=0
	# shellcheck disable=SC2034 # counting attempts, value unused
	for TRY in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 \
			21 22 23 24 25 26 27 28 29 30; do
		if psql -X -At -d postgres -c "SELECT 1;" > /dev/null 2>&1; then
			READY=1
			break
		fi
		sleep 1
	done
	if [ ${READY} -eq 0 ]; then
		cat "${SHUNIT_TMPDIR}/cockroach.log" 1>&2
		echo "ERROR: CockroachDB did not accept connections" 1>&2
		exit 1
	fi

	if ! "${BUILDDB}" -l "${PGPORT}" -w ${WAREHOUSES}; then
		echo "ERROR: dbt2-cockroach-build-db failed" 1>&2
		exit 1
	fi
}

oneTimeTearDown() {
	# CockroachDB has no command to stop a node; a termination signal
	# drains it and shuts it down.  Wait for the process to go away so
	# it cannot still be writing to the store while shUnit2 removes
	# the temporary directory.
	if [ ! -f "${CRDBPIDFILE}" ]; then
		return 0
	fi
	CRDBPID=$(cat "${CRDBPIDFILE}")
	kill "${CRDBPID}" > /dev/null 2>&1
	# shellcheck disable=SC2034 # counting attempts, value unused
	for TRY in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 \
			21 22 23 24 25 26 27 28 29 30; do
		if ! kill -0 "${CRDBPID}" > /dev/null 2>&1; then
			break
		fi
		sleep 1
	done
	return 0
}

run_transaction() {
	"${TXNTEST}" -a cockroach -d "${PGHOST}" -t "$1" -w ${WAREHOUSES}
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
