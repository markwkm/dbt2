add_test(NAME post-process
         COMMAND ${PROJECT_SOURCE_DIR}/src/scripts/test/t_post-process.sh
                 ${PROJECT_BINARY_DIR}/dbt2-post-process.sqlite3)
