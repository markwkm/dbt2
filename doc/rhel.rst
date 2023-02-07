RHEL
====

These instructions are for setting up the development environment for building
the test kit.  The software will be installed into the current user's
environment as opposed to the system-wide environment.  It can be installed
system-wide if so desired.  Explicit version numbers for some things are shown
but maybe not necessarily be required as such.

install git::

    yum install openssl-dev curl-devel expat-devel
    wget http://kernel.org/pub/software/scm/git/git-1.7.3.2.tar.bz2
	tar jxvf git-1.7.3.2.tar.bz2
	cd git-1.7.3.2
	make
	make install

install R::

    yum install tetex-latex xdg-utils bzip2-devel gcc-gfortran libX11-devel \
            pcre-devel tcl-devel tk-devel libXmu
    cpan install File::Copy::Recursive
    wget http://cran.cnr.berkeley.edu/bin/linux/redhat/el5/x86_64/R-2.10.0-2.el5.x86_64.rpm \
        http://cran.cnr.berkeley.edu/bin/linux/redhat/el5/x86_64/R-core-2.10.0-2.el5.x86_64.rpm \
        http://cran.cnr.berkeley.edu/bin/linux/redhat/el5/x86_64/R-devel-2.10.0-2.el5.x86_64.rpm \
        http://cran.cnr.berkeley.edu/bin/linux/redhat/el5/x86_64/libRmath-2.10.0-2.el5.x86_64.rpm \
        http://cran.cnr.berkeley.edu/bin/linux/redhat/el5/x86_64/libRmath-devel-2.10.0-2.el5.x86_64.rpm
    # One of the R rpms doesn't recognize that File::Copy::Recursive was
    # installed by cpan so use --nodeps.
    rpm -ivh --nodeps libRmath-2.10.0-2.el5.x86_64.rpm \
            libRmath-devel-2.10.0-2.el5.x86_64.rpm R-2.10.0-2.el5.x86_64.rpm \
            R-core-2.10.0-2.el5.x86_64.rpm R-devel-2.10.0-2.el5.x86_64.rpm

install cmake::

    yum install gcc-c++

install dbttools::

    git clone git://osdldbt.git.sourceforge.net/gitroot/osdldbt/dbttools
    cd dbttools

install dbt2::

    git clone git://osdldbt.git.sourceforge.net/gitroot/osdldbt/dbt2
