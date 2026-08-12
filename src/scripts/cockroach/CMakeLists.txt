set (PROGRAMFILES "")
foreach (FILE dbt2-cockroach-build-db
              dbt2-cockroach-create-db
              dbt2-cockroach-create-indexes
              dbt2-cockroach-create-tables
              dbt2-cockroach-db-stat
              dbt2-cockroach-drop-db
              dbt2-cockroach-load-db
        )
    configure_file(${FILE}.in ${PROJECT_BINARY_DIR}/${FILE} @ONLY)
    set (PROGRAMFILES ${PROGRAMFILES} ${PROJECT_BINARY_DIR}/${FILE})
endforeach()

install (
    PROGRAMS
    ${PROGRAMFILES}
    DESTINATION "bin"
)
