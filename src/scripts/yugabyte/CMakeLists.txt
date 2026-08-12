set (PROGRAMFILES "")
foreach (FILE dbt2-yugabyte-build-db
              dbt2-yugabyte-create-indexes
              dbt2-yugabyte-create-tables
              dbt2-yugabyte-load-db
        )
    configure_file(${FILE}.in ${PROJECT_BINARY_DIR}/${FILE} @ONLY)
    set (PROGRAMFILES ${PROGRAMFILES} ${PROJECT_BINARY_DIR}/${FILE})
endforeach()

install (
    PROGRAMS
    ${PROGRAMFILES}
    DESTINATION "bin"
)
