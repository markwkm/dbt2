add_test(NAME datagen_customer
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_datagen_customer.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME datagen_district
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_datagen_district.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME datagen_history
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_datagen_history.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME datagen_item
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_datagen_item.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME datagen_new_order
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_datagen_new_order.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME datagen_order_order_line
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_datagen_order_order_line.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME datagen_stock
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_datagen_stock.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME datagen_warehouse
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_datagen_warehouse.sh
                 $<TARGET_FILE:${DATAGEN}>)
add_test(NAME transaction_cockroach
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_transaction_cockroach.sh
                 $<TARGET_FILE:${DATAGEN}> $<TARGET_FILE:${TXN_TEST}>
                 ${PROJECT_BINARY_DIR}/dbt2-cockroach-build-db)
set_tests_properties(transaction_cockroach
                     PROPERTIES LABELS integration SKIP_RETURN_CODE 77)
add_test(NAME transaction_mysql
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_transaction_mysql.sh
                 $<TARGET_FILE:${DATAGEN}> $<TARGET_FILE:${TXN_TEST}>
                 ${PROJECT_BINARY_DIR}/dbt2-mysql-build-db)
set_tests_properties(transaction_mysql
                     PROPERTIES LABELS integration SKIP_RETURN_CODE 77)
add_test(NAME transaction_oracle
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_transaction_oracle.sh
                 $<TARGET_FILE:${DATAGEN}> $<TARGET_FILE:${TXN_TEST}>
                 ${PROJECT_BINARY_DIR}/dbt2-oracle-build-db)
set_tests_properties(transaction_oracle
                     PROPERTIES LABELS integration SKIP_RETURN_CODE 77)
add_test(NAME transaction_pgsql_c
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_transaction_pgsql.sh
                 $<TARGET_FILE:${DATAGEN}> $<TARGET_FILE:${TXN_TEST}>
                 ${PROJECT_BINARY_DIR}/dbt2-pgsql-build-db c)
add_test(NAME transaction_pgsql_client
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_transaction_pgsql.sh
                 $<TARGET_FILE:${DATAGEN}> $<TARGET_FILE:${TXN_TEST}>
                 ${PROJECT_BINARY_DIR}/dbt2-pgsql-build-db client)
add_test(NAME transaction_pgsql_plpgsql
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_transaction_pgsql.sh
                 $<TARGET_FILE:${DATAGEN}> $<TARGET_FILE:${TXN_TEST}>
                 ${PROJECT_BINARY_DIR}/dbt2-pgsql-build-db plpgsql)
set_tests_properties(transaction_pgsql_c transaction_pgsql_client
                     transaction_pgsql_plpgsql
                     PROPERTIES LABELS integration SKIP_RETURN_CODE 77)
add_test(NAME transaction_yugabyte
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_transaction_yugabyte.sh
                 $<TARGET_FILE:${DATAGEN}> $<TARGET_FILE:${TXN_TEST}>
                 ${PROJECT_BINARY_DIR}/dbt2-yugabyte-build-db)
set_tests_properties(transaction_yugabyte
                     PROPERTIES LABELS integration SKIP_RETURN_CODE 77)
add_test(NAME transaction_sqlite
         COMMAND ${PROJECT_SOURCE_DIR}/src/test/t_transaction_sqlite.sh
                 $<TARGET_FILE:${DATAGEN}> $<TARGET_FILE:${TXN_TEST}>
                 ${PROJECT_BINARY_DIR}/dbt2-sqlite-build-db)
set_tests_properties(transaction_sqlite
                     PROPERTIES LABELS integration SKIP_RETURN_CODE 77)
