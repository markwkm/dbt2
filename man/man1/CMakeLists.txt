execute_process(
    COMMAND sed -n "s/^.*(\\(.*\\)).*$/\\1/p;q" ${PROJECT_SOURCE_DIR}/ChangeLog
    OUTPUT_VARIABLE MANDATE
)

set (MANFILES "")
foreach (file dbt2
              dbt2-build
              dbt2-report
              dbt2-run
        )
    configure_file(${file}.1.rst.in ${PROJECT_BINARY_DIR}/man/man1/${file}.1.rst)
    execute_process(
        COMMAND rst2man ${PROJECT_BINARY_DIR}/man/man1/${file}.1.rst
        OUTPUT_FILE ${PROJECT_BINARY_DIR}/man/man1/${file}.1
    )
    set (MANFILES ${MANFILES} ${PROJECT_BINARY_DIR}/man/man1/${file}.1)
endforeach()

install(FILES ${MANFILES} DESTINATION "share/man/man1")
