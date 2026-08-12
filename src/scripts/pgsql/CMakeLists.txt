set (PROGRAMFILES "")
foreach (FILE dbt2-pgsql-build-db
              dbt2-pgsql-drop-stored-procs
              dbt2-pgsql-load-db
              dbt2-pgsql-plans
              dbt2-pgsql-set-param
        )
    configure_file(${FILE}.in ${PROJECT_BINARY_DIR}/${FILE} @ONLY)
    set (PROGRAMFILES ${PROGRAMFILES} ${PROJECT_BINARY_DIR}/${FILE})
endforeach()

install (
    PROGRAMS
    ${PROGRAMFILES}
    ${PROJECT_SOURCE_DIR}/src/scripts/pgsql/dbt2-pgsql-check-db
    ${PROJECT_SOURCE_DIR}/src/scripts/pgsql/dbt2-pgsql-create-db
    ${PROJECT_SOURCE_DIR}/src/scripts/pgsql/dbt2-pgsql-create-indexes
    ${PROJECT_SOURCE_DIR}/src/scripts/pgsql/dbt2-pgsql-create-tables
    ${PROJECT_SOURCE_DIR}/src/scripts/pgsql/dbt2-pgsql-drop-db
    ${PROJECT_SOURCE_DIR}/src/scripts/pgsql/dbt2-pgsql-drop-tables
    ${PROJECT_SOURCE_DIR}/src/scripts/pgsql/dbt2-pgsql-init-db
    ${PROJECT_SOURCE_DIR}/src/scripts/pgsql/dbt2-pgsql-load-stored-procs
    ${PROJECT_SOURCE_DIR}/src/scripts/pgsql/dbt2-pgsql-report
    ${PROJECT_SOURCE_DIR}/src/scripts/pgsql/dbt2-pgsql-start-db
    ${PROJECT_SOURCE_DIR}/src/scripts/pgsql/dbt2-pgsql-stop-db
    DESTINATION "bin"
)
