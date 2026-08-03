#!/bin/sh

THISDIR=$(dirname "$0")
TOPDIR="${THISDIR}/../.."

# Binary and script locations and the flavor to test may be given as
# arguments, otherwise assume a debug build exists.
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
	BUILDDB="${TOPDIR}/build/debug/dbt2-pgsql-build-db"
fi
if [ $# -gt 0 ]; then
	FLAVOR="$1"
	shift
else
	FLAVOR="plpgsql"
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

if ! command -v psql > /dev/null 2>&1; then
	echo "SKIP: psql not found in PATH"
	exit ${SKIP}
fi
if ! "${TXNTEST}" 2>&1 | grep -q "^PostgreSQL"; then
	echo "SKIP: dbt2-transaction-test built without PostgreSQL support"
	exit ${SKIP}
fi
if [ ! -x "${BUILDDB}" ]; then
	echo "SKIP: dbt2-pgsql-build-db not found: ${BUILDDB}"
	exit ${SKIP}
fi
if ! command -v pg_config > /dev/null 2>&1; then
	echo "SKIP: pg_config not found in PATH"
	exit ${SKIP}
fi
PGBIN=$(pg_config --bindir)
if [ ! -x "${PGBIN}/initdb" ] || [ ! -x "${PGBIN}/pg_ctl" ]; then
	echo "SKIP: PostgreSQL server binaries not found in ${PGBIN}"
	exit ${SKIP}
fi

# The stored functions are tested as pl/pgsql or pl/C, and the client
# flavor tests the client side SQL over libpq.  The pl/C functions
# are built with pgxs and loaded without being installed, which needs
# the server development headers and PostgreSQL 18 for
# extension_control_path.
DBMS="pgsql"
UDFTYPE="plpgsql"
case "${FLAVOR}" in
(plpgsql)
	;;
(client)
	# The client side SQL over libpq is registered under the
	# cockroach dbms name.
	DBMS="cockroach"
	;;
(c)
	UDFTYPE="c"
	if [ ! -f "$(pg_config --includedir-server)/postgres.h" ]; then
		echo "SKIP: PostgreSQL server development headers not found"
		exit ${SKIP}
	fi
	PGMAJOR=$(pg_config --version | awk '{print $2}' | cut -d . -f 1)
	if [ "${PGMAJOR}" -lt 18 ]; then
		echo "SKIP: PostgreSQL 18 or later required to load the extension"
		echo "without installing it"
		exit ${SKIP}
	fi
	if ! command -v make > /dev/null 2>&1; then
		echo "SKIP: make not found in PATH"
		exit ${SKIP}
	fi
	;;
(*)
	echo "ERROR: unknown flavor: ${FLAVOR}" 1>&2
	exit 1
	;;
esac

# dbt2-pgsql-build-db resolves the dbt2 wrapper, the generated
# scripts, the plain scripts, and the datagen binary from the PATH.
BUILDDIR=$(cd "$(dirname "${BUILDDB}")" && pwd)
DATAGENDIR=$(cd "$(dirname "${DATAGEN}")" && pwd)
SCRIPTSDIR=$(cd "${TOPDIR}/src/scripts" && pwd)
PATH="${BUILDDIR}:${DATAGENDIR}:${SCRIPTSDIR}/pgsql:${SCRIPTSDIR}:${PATH}"
export PATH

PLCDIR=$(cd "${TOPDIR}/storedproc/pgsql" && pwd)/c

TESTDB="dbt2_test"
PGDATABASE="${TESTDB}"
export PGDATABASE

# 2 warehouses so the remote warehouse paths in the Payment and
# New-Order transactions can be exercised.
WAREHOUSES=2

oneTimeSetUp() {
	PGDATA="${SHUNIT_TMPDIR}/pgdata"
	PGOPTS="-k ${SHUNIT_TMPDIR} -c listen_addresses=''"

	# Run a private server in the test's temporary directory,
	# listening only on a socket there.
	if ! "${PGBIN}/initdb" -A trust -N -D "${PGDATA}" \
			> "${SHUNIT_TMPDIR}/initdb.log" 2>&1; then
		cat "${SHUNIT_TMPDIR}/initdb.log" 1>&2
		echo "ERROR: initdb failed" 1>&2
		exit 1
	fi
	PGHOST="${SHUNIT_TMPDIR}"
	export PGHOST
	# Use a port number derived from the process id instead of the
	# default so the private server cannot collide with any other.
	PGPORT=$((10240 + $$ % 50000))
	export PGPORT
	PGOPTS="${PGOPTS} -c port=${PGPORT}"

	# Build the pl/C functions and stage the extension files where
	# extension_control_path can load them, with the library named
	# relative to dynamic_library_path.
	if [ "${FLAVOR}" = "c" ]; then
		cp -r "${PLCDIR}" "${SHUNIT_TMPDIR}/plc"
		if ! make -C "${SHUNIT_TMPDIR}/plc" \
				> "${SHUNIT_TMPDIR}/plc-build.log" 2>&1; then
			cat "${SHUNIT_TMPDIR}/plc-build.log" 1>&2
			echo "ERROR: pl/C stored function build failed" 1>&2
			exit 1
		fi
		mkdir -p "${SHUNIT_TMPDIR}/extension"
		cp "${SHUNIT_TMPDIR}/plc/dbt2.control" \
				"${SHUNIT_TMPDIR}"/plc/dbt2--*.sql \
				"${SHUNIT_TMPDIR}/extension/"
		sed -i "s|'\$libdir/dbt2'|'dbt2'|" \
				"${SHUNIT_TMPDIR}/extension/dbt2.control"
		PGOPTS="${PGOPTS} -c \
extension_control_path='\$system:${SHUNIT_TMPDIR}'"
		PGOPTS="${PGOPTS} -c \
dynamic_library_path='\$libdir:${SHUNIT_TMPDIR}/plc'"
	fi

	if ! "${PGBIN}/pg_ctl" -D "${PGDATA}" -l "${SHUNIT_TMPDIR}/pg.log" \
			-o "${PGOPTS}" -w start; then
		cat "${SHUNIT_TMPDIR}/pg.log" 1>&2
		echo "ERROR: pg_ctl start failed" 1>&2
		exit 1
	fi

	if ! "${BUILDDB}" -i "${TOPDIR}/storedproc/pgsql/pgsql" -s "${UDFTYPE}" \
			-w ${WAREHOUSES} "${TESTDB}"; then
		echo "ERROR: dbt2-pgsql-build-db failed" 1>&2
		exit 1
	fi
}

oneTimeTearDown() {
	"${PGBIN}/pg_ctl" -D "${SHUNIT_TMPDIR}/pgdata" -w stop \
			> /dev/null 2>&1
	return 0
}

run_transaction() {
	"${TXNTEST}" -a "${DBMS}" -d "${PGHOST}" -t "$1" -w ${WAREHOUSES}
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
