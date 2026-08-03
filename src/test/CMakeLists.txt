add_test(NAME datagen_customer
         COMMAND ${CMAKE_SOURCE_DIR}/src/test/t_datagen_customer.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME datagen_district
         COMMAND ${CMAKE_SOURCE_DIR}/src/test/t_datagen_district.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME datagen_history
         COMMAND ${CMAKE_SOURCE_DIR}/src/test/t_datagen_history.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME datagen_item
         COMMAND ${CMAKE_SOURCE_DIR}/src/test/t_datagen_item.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME datagen_new_order
         COMMAND ${CMAKE_SOURCE_DIR}/src/test/t_datagen_new_order.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME datagen_order_order_line
         COMMAND ${CMAKE_SOURCE_DIR}/src/test/t_datagen_order_order_line.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME datagen_stock
         COMMAND ${CMAKE_SOURCE_DIR}/src/test/t_datagen_stock.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME datagen_warehouse
         COMMAND ${CMAKE_SOURCE_DIR}/src/test/t_datagen_warehouse.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME transaction_mysql
         COMMAND ${CMAKE_SOURCE_DIR}/src/test/t_transaction_mysql.sh
                 $<TARGET_FILE:${DATAGEN}> $<TARGET_FILE:${TXN_TEST}>
                 ${CMAKE_BINARY_DIR}/dbt2-mysql-build-db)
set_tests_properties(transaction_mysql
                     PROPERTIES LABELS integration SKIP_RETURN_CODE 77)
add_test(NAME transaction_pgsql_c
         COMMAND ${CMAKE_SOURCE_DIR}/src/test/t_transaction_pgsql.sh
                 $<TARGET_FILE:${DATAGEN}> $<TARGET_FILE:${TXN_TEST}>
                 ${CMAKE_BINARY_DIR}/dbt2-pgsql-build-db c)
add_test(NAME transaction_pgsql_client
         COMMAND ${CMAKE_SOURCE_DIR}/src/test/t_transaction_pgsql.sh
                 $<TARGET_FILE:${DATAGEN}> $<TARGET_FILE:${TXN_TEST}>
                 ${CMAKE_BINARY_DIR}/dbt2-pgsql-build-db client)
add_test(NAME transaction_pgsql_plpgsql
         COMMAND ${CMAKE_SOURCE_DIR}/src/test/t_transaction_pgsql.sh
                 $<TARGET_FILE:${DATAGEN}> $<TARGET_FILE:${TXN_TEST}>
                 ${CMAKE_BINARY_DIR}/dbt2-pgsql-build-db plpgsql)
set_tests_properties(transaction_pgsql_c transaction_pgsql_client
                     transaction_pgsql_plpgsql
                     PROPERTIES LABELS integration SKIP_RETURN_CODE 77)
add_test(NAME transaction_sqlite
         COMMAND ${CMAKE_SOURCE_DIR}/src/test/t_transaction_sqlite.sh
                 $<TARGET_FILE:${DATAGEN}> $<TARGET_FILE:${TXN_TEST}>
                 ${CMAKE_BINARY_DIR}/dbt2-sqlite-build-db)
set_tests_properties(transaction_sqlite
                     PROPERTIES LABELS integration SKIP_RETURN_CODE 77)
