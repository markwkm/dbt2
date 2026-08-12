cmake_minimum_required (VERSION 3.10...4.0)
project (dbt2 VERSION 0.61.7 LANGUAGES C)

if (CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message (FATAL_ERROR
             "In-source builds are not allowed.  Use a separate build "
             "directory, e.g. \"cmake -S . -B build/release\", and remove "
             "the CMakeCache.txt file and CMakeFiles directory that this "
             "attempt created in the source directory.")
endif ()

set (CMAKE_C_STANDARD 99)
set (CMAKE_C_STANDARD_REQUIRED ON)

# Without a build type the compiler is invoked with no optimization flags,
# which is never what is wanted when measuring a database.

if (NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set (CMAKE_BUILD_TYPE Release CACHE STRING
         "Build type: Debug, Release, RelWithDebInfo or MinSizeRel." FORCE)
endif ()

enable_testing()

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    set (SHELLOPTIONS "set -x")
endif ()

set (
    HOMEPAGE
    "Database Test 2 (DBT-2) project page: https://github.com/osdldbt/dbt2"
)

add_subdirectory (appimage)
add_subdirectory (man)
add_subdirectory (src)
add_subdirectory (storedproc)

# CPack rules for creating distribution files.

set (CPACK_PACKAGE_NAME "dbt2")
set (CPACK_PACKAGE_DESCRIPTION_SUMMARY "Database Test 2")
set (CPACK_PACKAGE_VENDOR "osdl")

# CPack derives CPACK_PACKAGE_VERSION and its components from the project
# version.  Only the file name needs overriding, to leave off the system
# name that the default would append.

set (CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${PROJECT_VERSION}")

set (CPACK_INSTALL_CMAKE_PROJECTS "")

set (CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_SOURCE_DIR}/README")
set (CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE")

set (CPACK_SOURCE_GENERATOR "TBZ2;TXZ;ZIP")
set (CPACK_SOURCE_PACKAGE_FILE_NAME "${PROJECT_NAME}-${PROJECT_VERSION}")

# These patterns are regular expressions that CPack writes into the
# generated CPack configuration and parses a second time when it runs, so
# every backslash has to survive two rounds of CMake string parsing.

set (CPACK_SOURCE_IGNORE_FILES
     "\\\\.bz2\\$"
     "\\\\.gz\\$"
     "\\\\.xz\\$"
     "\\\\.Z\\$"
     "\\\\.zip\\$"
     "/CMakeCache\\\\.txt\\$"
     "/CMakeFiles/"
     "/cmake_install\\\\.cmake\\$"
     "/CPackConfig\\\\.cmake\\$"
     "/\\\\.github/"
     "/\\\\.gitignore\\$"
     "/\\\\_CPack\\\\_Packages/"
     "/CPackSourceConfig\\\\.cmake\\$"
     "/CTestTestfile\\\\.cmake\\$"
)

include (CPack)
