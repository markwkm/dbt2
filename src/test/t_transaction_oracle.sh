#!/bin/sh

THISDIR=$(dirname "$0")
TOPDIR="${THISDIR}/../.."

# Binary locations may be given as arguments, otherwise assume a
# debug build exists.
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
	BUILDDB="${TOPDIR}/build/debug/dbt2-oracle-build-db"
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

if ! command -v sqlplus > /dev/null 2>&1; then
	echo "SKIP: sqlplus not found in PATH"
	exit ${SKIP}
fi
if ! command -v sqlldr > /dev/null 2>&1; then
	echo "SKIP: sqlldr not found in PATH"
	exit ${SKIP}
fi
if ! "${TXNTEST}" 2>&1 | grep -q "^Oracle:"; then
	echo "SKIP: dbt2-transaction-test built without Oracle support"
	exit ${SKIP}
fi
if [ ! -x "${BUILDDB}" ]; then
	echo "SKIP: dbt2-oracle-build-db not found: ${BUILDDB}"
	exit ${SKIP}
fi

# The generated strings are multi-byte; without a matching client
# character set the transaction output comes back with substitution
# characters.
NLS_LANG="AMERICAN_AMERICA.AL32UTF8"
export NLS_LANG

# An Oracle server cannot run as a throwaway process in the test's
# temporary directory, so this test uses an existing database, or
# creates one itself in an Oracle Database Free environment.  The
# test connects as dbt/dbt, the account dbt2-transaction-test is
# compiled to use, and DROPS and recreates the dbt2 tables and
# stored procedures in that account's schema.  The tables are left
# in place afterwards for inspection; the next run drops them.
#
# The DBT2ORACLE environment variable (an EZConnect string) names
# the database.  When it is not set, the test probes Oracle Database
# Free's fixed local address and uses it if the dbt account answers.
# When nothing answers and the test can run commands as the oracle
# software owner, it manages the FREE database itself: a FREE
# database that exists but is not running is started and the dbt
# account is created if it is missing -- the official container
# images ship the FREE database already created but stopped, and a
# container restart stops a database a previous run left running.
# When no FREE database exists, the test creates one from the
# software home's seed template, which takes about ten minutes.
# Either way the database is left running: subsequent runs find it
# through the probe.
probe_connect() {
	# Match a marker that cannot appear in an ORA- error message.
	sqlplus -S -L "dbt/dbt@$1" <<-EOF 2> /dev/null | grep -q "^CONNECTED$"
		SET HEADING OFF FEEDBACK OFF PAGESIZE 0
		SELECT 'CONNECTED' FROM dual;
	EOF
}

# Database management commands must run as the oracle software
# owner: directly, through su as root, or through su with the fixed
# password the official container images set on the oracle account.
run_as_oracle() {
	if [ "$(id -un)" = "oracle" ]; then
		/bin/sh -c "$1"
	elif [ "$(id -u)" -eq 0 ]; then
		su -s /bin/sh oracle -c "$1"
	else
		echo oracle | su -s /bin/sh oracle -c "$1" 2> /dev/null
	fi
}

CREATE_DATABASE=0
START_DATABASE=0
if [ "${DBT2ORACLE}" = "" ]; then
	DBT2ORACLE="//localhost:1521/FREEPDB1"
	if probe_connect "${DBT2ORACLE}"; then
		echo "using the Oracle database at ${DBT2ORACLE}"
	elif [ "${ORACLE_HOME}" = "" ] || \
			[ ! -f "${ORACLE_HOME}/bin/dbca" ]; then
		echo "SKIP: no Oracle database found at ${DBT2ORACLE};" \
				"set DBT2ORACLE (EZConnect string)"
		exit ${SKIP}
	elif ! run_as_oracle "true"; then
		echo "SKIP: cannot run database commands as the oracle user"
		exit ${SKIP}
	elif grep -q "^FREE:" /etc/oratab 2> /dev/null; then
		echo "starting the Oracle database at ${DBT2ORACLE}"
		START_DATABASE=1
	else
		echo "creating the Oracle database at ${DBT2ORACLE}"
		CREATE_DATABASE=1
	fi
fi

ORACLE_CONNECT="dbt/dbt@${DBT2ORACLE}"

# 2 warehouses so the remote warehouse paths in the Payment and
# New-Order transactions can be exercised.
WAREHOUSES=2

run_sql() {
	sqlplus -S -L "${ORACLE_CONNECT}" <<-EOF
		WHENEVER SQLERROR EXIT 1
		SET HEADING OFF FEEDBACK OFF PAGESIZE 0
		$1
	EOF
}

db_query() {
	run_sql "$1" | tr -d " \t"
}

# Create the FREE database and its FREEPDB1 pluggable database from
# the seed template the Oracle Database Free software home ships,
# with the same parameters the software's own configuration script
# uses, then register with the listener by address, because a
# container hostname often does not resolve to a routable address
# and the registration process's default hostname-based
# registration then never reaches the listener, and create the dbt
# account.  The SYS password is fixed to oracle, matching the
# official container images.  The SQL script is written under /tmp
# because the oracle user cannot read the shUnit2 temporary
# directory.
create_database() {
	if ! run_as_oracle "'${ORACLE_HOME}/bin/netca' \
			/orahome '${ORACLE_HOME}' /instype typical \
			/inscomp client,oraclenet,javavm,server,ano \
			/insprtcl tcp /cfg local /authadp NO_VALUE \
			/responseFile '${ORACLE_HOME}/network/install/netca_typ.rsp' \
			/silent /orahnam dbhomeFree \
			/listenerparameters DEFAULT_SERVICE=FREE" \
			> "${SHUNIT_TMPDIR}/netca.log" 2>&1; then
		cat "${SHUNIT_TMPDIR}/netca.log" 1>&2
		echo "ERROR: listener configuration failed" 1>&2
		exit 1
	fi
	run_as_oracle "'${ORACLE_HOME}/bin/lsnrctl' start LISTENER" \
			> "${SHUNIT_TMPDIR}/lsnrctl.log" 2>&1

	if ! run_as_oracle "printf 'oracle\noracle\noracle\n' | \
			'${ORACLE_HOME}/bin/dbca' -silent -createDatabase \
			-templateName FREE_Database.dbc -characterSet AL32UTF8 \
			-createAsContainerDatabase true -numberOfPDBs 1 \
			-pdbName FREEPDB1 -sid FREE -gdbName FREE \
			-J-Doracle.assistants.dbca.validate.DBCredentials=false \
			-ignorePrereqs \
			-J-Doracle.assistants.skipAvailableSharedMemoryCheck=true \
			-skipDatapatch true -customScripts \
			'${ORACLE_HOME}/assistants/dbca/postdb_creation.sql'" \
			> "${SHUNIT_TMPDIR}/dbca.log" 2>&1; then
		cat "${SHUNIT_TMPDIR}/dbca.log" 1>&2
		echo "ERROR: database creation failed" 1>&2
		exit 1
	fi

	TMPSQL=$(mktemp /tmp/dbt2_oracle_XXXXXX.sql)
	chmod 644 "${TMPSQL}"
	cat > "${TMPSQL}" <<-EOF
		WHENEVER SQLERROR EXIT 1
		ALTER SYSTEM SET local_listener =
		    '(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))'
		    SCOPE=BOTH;
		ALTER SYSTEM REGISTER;
		ALTER SESSION SET CONTAINER = FREEPDB1;
		CREATE USER dbt IDENTIFIED BY "dbt"
		    DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
		GRANT DB_DEVELOPER_ROLE TO dbt;
	EOF
	run_as_oracle "ORACLE_SID=FREE '${ORACLE_HOME}/bin/sqlplus' \
			-S / as sysdba @'${TMPSQL}'" \
			> "${SHUNIT_TMPDIR}/setup.log" 2>&1
	RC=$?
	rm -f "${TMPSQL}"
	if [ ${RC} -ne 0 ]; then
		cat "${SHUNIT_TMPDIR}/setup.log" 1>&2
		echo "ERROR: database setup failed" 1>&2
		exit 1
	fi
}

# Start the FREE database that exists but does not answer: the
# official container images ship the FREE database created but
# stopped, and a container restart stops a database a previous run
# left running.  Start the listener and the instance, register with
# the listener by address (see create_database), open the pluggable
# database, and create the dbt account, without stopping on errors
# because any of these steps may already be done; the probe at the
# end decides whether the database came up.
start_database() {
	run_as_oracle "'${ORACLE_HOME}/bin/lsnrctl' start LISTENER" \
			> "${SHUNIT_TMPDIR}/lsnrctl.log" 2>&1

	TMPSQL=$(mktemp /tmp/dbt2_oracle_XXXXXX.sql)
	chmod 644 "${TMPSQL}"
	cat > "${TMPSQL}" <<-EOF
		STARTUP
		ALTER SYSTEM SET local_listener =
		    '(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))'
		    SCOPE=BOTH;
		ALTER SYSTEM REGISTER;
		ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
		ALTER SESSION SET CONTAINER = FREEPDB1;
		CREATE USER dbt IDENTIFIED BY "dbt"
		    DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
		GRANT DB_DEVELOPER_ROLE TO dbt;
		EXIT
	EOF
	run_as_oracle "ORACLE_SID=FREE '${ORACLE_HOME}/bin/sqlplus' \
			-S / as sysdba @'${TMPSQL}'" \
			> "${SHUNIT_TMPDIR}/startup.log" 2>&1
	rm -f "${TMPSQL}"

	if ! probe_connect "${DBT2ORACLE}"; then
		cat "${SHUNIT_TMPDIR}/startup.log" 1>&2
		echo "ERROR: the FREE database does not answer after" \
				"starting it" 1>&2
		exit 1
	fi
}

oneTimeSetUp() {
	DATADIR="${SHUNIT_TMPDIR}/data"

	if [ ${CREATE_DATABASE} -eq 1 ]; then
		create_database
	elif [ ${START_DATABASE} -eq 1 ]; then
		start_database
	fi

	if [ "$(db_query "SELECT 1 FROM dual;")" != "1" ]; then
		echo "ERROR: cannot connect to ${DBT2ORACLE} as dbt" 1>&2
		exit 1
	fi

	mkdir -p "${DATADIR}"
	if ! ${DATAGEN} -d "${DATADIR}" -w ${WAREHOUSES}; then
		echo "ERROR: dbt2-datagen failed" 1>&2
		exit 1
	fi

	if ! "${BUILDDB}" -d "${DBT2ORACLE}" -f "${DATADIR}" \
			-F "${TOPDIR}/storedproc/oracle" -r -w ${WAREHOUSES}; then
		echo "ERROR: dbt2-oracle-build-db failed" 1>&2
		exit 1
	fi
}

run_transaction() {
	"${TXNTEST}" -a oracle -d "${DBT2ORACLE}" -t "$1" -w ${WAREHOUSES}
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
