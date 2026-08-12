string (TIMESTAMP APPDATA_RELEASE_DATE "%Y-%m-%d")

configure_file (AppRun.in ${PROJECT_BINARY_DIR}/AppRun @ONLY)
configure_file (org.osdl.dbt2.appdata.xml.in
                ${PROJECT_BINARY_DIR}/org.osdl.dbt2.appdata.xml @ONLY)

# Keep in sync with PYTHONMMVER in appimage/Containerfile.
set (PYTHONMMVER 3.11)

find_program(APPIMAGE NAMES appimagetool)

if (APPIMAGE)
    set (APPIMAGETOOL ${APPIMAGE})
else ()
    set (APPIMAGETOOL /usr/local/squashfs-root/AppRun)
endif ()

# The AppDir is a sibling of the build directory, where the install step
# staged it with DESTDIR=../AppDir.  The paths below are relative to the top
# of the build tree, which is why the target sets WORKING_DIRECTORY rather
# than running in this subdirectory's binary directory.

set (DRIVER3 ../AppDir/usr/bin/dbt2-driver3)
set (GNUPLOT ../AppDir/usr/bin/gnuplot)
set (PSQL ../AppDir/usr/bin/psql)

add_custom_target(appimage
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    COMMAND ! [ -d "/usr/local/share/licenses" ] ||
            cp -pr /usr/local/share/licenses ../AppDir/usr/share
    COMMAND ! [ -d "/usr/local/lib/python${PYTHONMMVER}" ] ||
            mkdir -p ../AppDir/usr/lib/
    COMMAND ! [ -d "/usr/local/lib/python${PYTHONMMVER}" ] ||
            cp -pr /usr/local/lib/python${PYTHONMMVER} ../AppDir/usr/lib/
    COMMAND mkdir -p ../AppDir/usr/share/licenses/dbt2-${PROJECT_VERSION}
    COMMAND cp -p ../../LICENSE
            ../AppDir/usr/share/licenses/dbt2-${PROJECT_VERSION}/
    COMMAND mkdir -p ../AppDir/usr/bin ../AppDir/usr/share/metainfo
    COMMAND cp -p org.osdl.dbt2.appdata.xml ../AppDir/usr/share/metainfo
    COMMAND cp -p ${CMAKE_CURRENT_SOURCE_DIR}/dbt2.svg
                  ${CMAKE_CURRENT_SOURCE_DIR}/org.osdl.dbt2.desktop
                  AppRun ../AppDir
    COMMAND cp -p `command -v gnuplot`
                  `command -v jq`
                  `command -v perl`
                  `command -v psql`
                  `command -v python3`
                  `command -v rst2html5`
                  `command -v spar`
                  `command -v sqlite3`
                  `command -v toml`
                  ../AppDir/usr/bin/
    COMMAND sed -i -e "s#/usr#././#g"
                ../AppDir/usr/bin/gnuplot
                ../AppDir/usr/bin/jq
                ../AppDir/usr/bin/perl
                ../AppDir/usr/bin/psql
                ../AppDir/usr/bin/python3
                ../AppDir/usr/bin/spar
                ../AppDir/usr/bin/sqlite3
                ../AppDir/usr/bin/toml
    COMMAND mkdir -p ../AppDir/etc/perl
                     ../AppDir/etc/perl/Carp
                     ../AppDir/etc/perl/Exporter
                     ../AppDir/etc/perl/Getopt
                     ../AppDir/etc/perl/warnings
    COMMAND cp -p `find /usr -type f -name Carp.pm | head -n 1`
                  `find /usr -type f -name Exporter.pm | head -n 1`
                  `find /usr -type f -name constant.pm | head -n 1`
                  `find /usr -type f -name open.pm | head -n 1`
                  `find /usr -type f -name overload.pm | head -n 1`
                  `find /usr -type f -name overloading.pm | head -n 1`
                  `find /usr -type f -name strict.pm | head -n 1`
                  `find /usr -type f -name vars.pm | head -n 1`
                  `find /usr -type f -name warnings.pm | head -n 1`
               ../AppDir/etc/perl/
    COMMAND cp -p `find /usr -type f -name Heavy.pm | grep Carp | head -n 1`
               ../AppDir/etc/perl/Carp/
    COMMAND cp -p `find /usr -type f -name Heavy.pm | grep Exporter | head -n 1`
               ../AppDir/etc/perl/Exporter/
    COMMAND cp -p `find /usr -type f -name Long.pm | grep Getopt | head -n 1`
               ../AppDir/etc/perl/Getopt/
    COMMAND cp -p `find /usr -type f -name register.pm | grep warnings | head -n 1`
               ../AppDir/etc/perl/warnings/
    COMMAND sed -i "1s/.*/#!\\\\/usr\\\\/bin\\\\/env python3/"
            ../AppDir/usr/bin/rst2html5
    COMMAND cp -p `command -v dbt-plot`
                  `command -v dbt-plot-transaction-distribution.gnuplot`
                  `command -v dbt-plot-transaction-rate.gnuplot`
                  `command -v dbt-pgsql-generate-db-report`
                  `command -v dbt-pgsql-generate-index-report`
                  `command -v dbt-pgsql-generate-table-report`
                  ../AppDir/usr/bin/
    COMMAND cp -p `command -v ts`
                  `command -v ts-pgsql-stat`
                  `command -v ts-plot-collectd`
                  `command -v ts-plot-pgsql`
                  `command -v ts-plot-pidstat`
                  `command -v ts-plot-queries`
                  `command -v ts-plot-sar`
                  `command -v ts-plot-spar`
                  `command -v ts-process-pidstat`
                  `command -v ts-profile`
                  `command -v ts-report-pid`
                  `command -v ts-report-sar`
                  `command -v ts-sysstat`
                  ../AppDir/usr/bin/
    COMMAND curl -o ../AppDir/usr/bin/stackcollapse-perf.pl -fSsL
            https://raw.githubusercontent.com/brendangregg/FlameGraph/master/stackcollapse-perf.pl
    COMMAND curl -o ../AppDir/usr/bin/flamegraph.pl -fSsL
            https://raw.githubusercontent.com/brendangregg/FlameGraph/master/flamegraph.pl
    COMMAND chmod +x ../AppDir/usr/bin/stackcollapse-perf.pl
            ../AppDir/usr/bin/flamegraph.pl
    COMMAND sed -i "1s/.*/#!\\\\/usr\\\\/bin\\\\/env perl/"
                ../AppDir/usr/bin/flamegraph.pl
                ../AppDir/usr/bin/stackcollapse-perf.pl
    COMMAND mkdir -p ../AppDir/usr/share/licenses/FlameGraph
    COMMAND curl -o ../AppDir/usr/share/licenses/FlameGraph/cddl1.txt -fSsL
            https://raw.githubusercontent.com/brendangregg/FlameGraph/master/docs/cddl1.txt
    COMMAND mkdir -p ../AppDir/usr/lib/
    COMMAND cp -paL
               `ldd ${DRIVER3} | grep libev\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${DRIVER3} | grep libnsl\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libcairo\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libfreetype\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libfribidi\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libgraphite2\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep harfbuzz\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libbsd\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libpango-1\\\\\\\\.0\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libpangoft2-1\\\\\\\\.0\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libpangocairo-1\\\\\\\\.0\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libpixman-1\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libpng16\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libX11\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libXdmcp\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libXext\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libXrender\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libXau\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libxcb\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libxcb-shm\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${GNUPLOT} | grep libxcb-render\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${PSQL} | grep libcrypto\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${PSQL} | grep libpq\\\\\\\\. | cut -d \" \" -f 3`
               `ldd ${PSQL} | grep libssl\\\\\\\\. | cut -d \" \" -f 3`
               ../AppDir/usr/lib/
    COMMAND VERSION=${PROJECT_VERSION} ARCH=`uname -m` ${APPIMAGETOOL}
            --no-appstream ../AppDir
)
