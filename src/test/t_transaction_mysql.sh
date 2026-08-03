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
	BUILDDB="${TOPDIR}/build/debug/dbt2-mysql-build-db"
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

if ! command -v mysql > /dev/null 2>&1; then
	echo "SKIP: mysql not found in PATH"
	exit ${SKIP}
fi
if ! "${TXNTEST}" 2>&1 | grep -q "^MySQL:"; then
	echo "SKIP: dbt2-transaction-test built without MySQL support"
	exit ${SKIP}
fi
if [ ! -x "${BUILDDB}" ]; then
	echo "SKIP: dbt2-mysql-build-db not found: ${BUILDDB}"
	exit ${SKIP}
fi
MYSQLD=""
for CANDIDATE in "$(command -v mysqld 2> /dev/null)" \
		"$(command -v mariadbd 2> /dev/null)" /usr/sbin/mysqld \
		/usr/sbin/mariadbd /usr/libexec/mysqld; do
	if [ ! "${CANDIDATE}" = "" ] && [ -x "${CANDIDATE}" ]; then
		MYSQLD="${CANDIDATE}"
		break
	fi
done
if [ "${MYSQLD}" = "" ]; then
	echo "SKIP: MySQL server binary not found"
	exit ${SKIP}
fi

# dbt2-mysql-build-db resolves the dbt2 wrapper and the generated
# scripts from the PATH.
BUILDDIR=$(cd "$(dirname "${BUILDDB}")" && pwd)
SCRIPTSDIR=$(cd "${TOPDIR}/src/scripts" && pwd)
PATH="${BUILDDIR}:${SCRIPTSDIR}/mysql:${SCRIPTSDIR}:${PATH}"
export PATH

TESTDB="dbt2_test"

# 2 warehouses so the remote warehouse paths in the Payment and
# New-Order transactions can be exercised.
WAREHOUSES=2

oneTimeSetUp() {
	DATADIR="${SHUNIT_TMPDIR}/data"
	MYSQLDATA="${SHUNIT_TMPDIR}/mysqldata"
	SOCK="${SHUNIT_TMPDIR}/mysql.sock"

	# Run a private server in the test's temporary directory,
	# listening only on a socket there, allowed to load data files
	# from any path.
	if command -v mariadb-install-db > /dev/null 2>&1; then
		if ! mariadb-install-db --no-defaults --datadir="${MYSQLDATA}" \
				--skip-test-db --auth-root-authentication-method=normal \
				> "${SHUNIT_TMPDIR}/initdb.log" 2>&1; then
			cat "${SHUNIT_TMPDIR}/initdb.log" 1>&2
			echo "ERROR: mariadb-install-db failed" 1>&2
			exit 1
		fi
	else
		if ! "${MYSQLD}" --no-defaults --initialize-insecure \
				--datadir="${MYSQLDATA}" \
				> "${SHUNIT_TMPDIR}/initdb.log" 2>&1; then
			cat "${SHUNIT_TMPDIR}/initdb.log" 1>&2
			echo "ERROR: mysqld --initialize-insecure failed" 1>&2
			exit 1
		fi
	fi
	"${MYSQLD}" --no-defaults --datadir="${MYSQLDATA}" --socket="${SOCK}" \
			--pid-file="${SHUNIT_TMPDIR}/mysql.pid" --skip-networking \
			--skip-log-bin --secure-file-priv= \
			> "${SHUNIT_TMPDIR}/mysqld.log" 2>&1 &
	READY=0
	# shellcheck disable=SC2034 # counting attempts, value unused
	for TRY in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 \
			21 22 23 24 25 26 27 28 29 30; do
		if mysql -u root -S "${SOCK}" -e "SELECT 1;" > /dev/null 2>&1; then
			READY=1
			break
		fi
		sleep 1
	done
	if [ ${READY} -eq 0 ]; then
		cat "${SHUNIT_TMPDIR}/mysqld.log" 1>&2
		echo "ERROR: MySQL server did not start" 1>&2
		exit 1
	fi

	mkdir -p "${DATADIR}"
	if ! ${DATAGEN} -d "${DATADIR}" -w ${WAREHOUSES}; then
		echo "ERROR: dbt2-datagen failed" 1>&2
		exit 1
	fi
	if ! "${BUILDDB}" -d "${TESTDB}" -f "${DATADIR}" \
			-F "${TOPDIR}/storedproc/mysql" -S "${SOCK}" -u root \
			-w ${WAREHOUSES}; then
		echo "ERROR: dbt2-mysql-build-db failed" 1>&2
		exit 1
	fi
}

oneTimeTearDown() {
	if command -v mysqladmin > /dev/null 2>&1; then
		mysqladmin -u root -S "${SOCK}" shutdown > /dev/null 2>&1
	elif [ -f "${SHUNIT_TMPDIR}/mysql.pid" ]; then
		kill "$(cat "${SHUNIT_TMPDIR}/mysql.pid")" > /dev/null 2>&1
	fi
	return 0
}

run_transaction() {
	DBT2DBNAME="${TESTDB}" "${TXNTEST}" -a mysql -d "${SOCK}" -t "$1" \
			-w ${WAREHOUSES}
}

db_query() {
	mysql -u root -S "${SOCK}" -D "${TESTDB}" -sN -e "$1"
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
