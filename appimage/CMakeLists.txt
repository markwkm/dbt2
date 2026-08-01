string (TIMESTAMP APPDATA_RELEASE_DATE "%Y-%m-%d")

configure_file (AppRun.in ${CMAKE_BINARY_DIR}/AppRun @ONLY)
configure_file (org.osdl.dbt2.appdata.xml.in
                ${CMAKE_BINARY_DIR}/org.osdl.dbt2.appdata.xml @ONLY)
