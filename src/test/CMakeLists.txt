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
