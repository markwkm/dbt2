add_test(NAME post-process
         COMMAND ${CMAKE_SOURCE_DIR}/src/scripts/test/t_post-process.sh
                 ${CMAKE_BINARY_DIR}/dbt2-post-process.sqlite3)
