set (PROGRAMFILES "")
foreach (FILE dbt2-mysql-build-db
              dbt2-mysql-load-stored-procs
              dbt2-mysql-plans
        )
    configure_file(${FILE}.in ${PROJECT_BINARY_DIR}/${FILE} @ONLY)
    set (PROGRAMFILES ${PROGRAMFILES} ${PROJECT_BINARY_DIR}/${FILE})
endforeach()

install (
    PROGRAMS
    ${PROGRAMFILES}
    ${PROJECT_SOURCE_DIR}/src/scripts/mysql/dbt2-mysql-start-db
    ${PROJECT_SOURCE_DIR}/src/scripts/mysql/dbt2-mysql-stop-db
    DESTINATION "bin"
)
