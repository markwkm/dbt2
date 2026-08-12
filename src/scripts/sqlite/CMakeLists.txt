set (PROGRAMFILES "")
foreach (FILE dbt2-sqlite-build-db
        )
    configure_file(${FILE}.in ${PROJECT_BINARY_DIR}/${FILE} @ONLY)
    set (PROGRAMFILES ${PROGRAMFILES} ${PROJECT_BINARY_DIR}/${FILE})
endforeach()

install (
    PROGRAMS
    ${PROGRAMFILES}
    ${PROJECT_SOURCE_DIR}/src/scripts/sqlite/dbt2-sqlite-plans
    ${PROJECT_SOURCE_DIR}/src/scripts/sqlite/dbt2-sqlite-start-db
    ${PROJECT_SOURCE_DIR}/src/scripts/sqlite/dbt2-sqlite-stop-db
    DESTINATION "bin"
)
