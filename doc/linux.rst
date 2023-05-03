Linux
=====

If you want readprofile data, you need to give the user **sudo** access to run
**readprofile.  Root privileges are required to clear the counter data.
Additionally, the Linux kernel needs to be booted with `profile=2` in the
kernel command line.  Here is a **sudo** configuration example of passwordless
access for user *postgres* to run **readprofile -r**::

    postgres ALL = NOPASSWD: /usr/sbin/readprofile -r

The number of open files will likely need to be raised for the on the systems
that are driving the database when using the thread based driver and client
programs.

To increase this for a user edit `/etc/security/limits.conf`.  Here is an
example for the user *postgres*::

    postgres         soft    nofile          40000
    postgres         hard    nofile          40000

The Linux kernel parameter also needs to be adjusted because the user limits
cannot be set above the operating system limits.  Edit `/etc/sysctl.conf`::

    fs.file-max = 40000

This can be verified in `/proc/sys/fs/file-max`.


Additionally the driver for this workload may need to create more threads
than allowed by default.  To increase the thread per process limit for the
user in `/etc/security/limits.conf`::

    postgres         soft    nproc           32768
    postgres         hard    nproc           32768


Similarly in `/etc/sysctl.conf` for the same reasons as above::

    kernel.threads-max = 32768


This can be verified in `/proc/sys/kernel/threads-max`.

One of the shared memory parameters will likely needs to be raised on the
database system in order to accommodate increasing the shared_buffers parameter
in PostgreSQL.  One way to do this permanently is to edit `/etc/sysctl.conf`
and add::

    kernel.shmmax = 41943040
