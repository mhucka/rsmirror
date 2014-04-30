rsmirror
========

A shell script for mirroring one or more directories to a remote computer, with a particular emphasis on handling Mac OS X files.  It uses `rsync` over `ssh`, with settings that attempt to preserve Mac OS X file attributes.

----
*Author*:       Michael Hucka (http://www.cds.caltech.edu/~mhucka)

*Copyright*:    Copyright (C) 2008-2014 by the California Institute of Technology, Pasadena, USA.

*License*:      This code is licensed under the LGPL version 2.1.  Please see the file [../COPYING.txt](https://raw.github.com/mhucka/rsmirror/master/COPYING.txt) for details.

*Project page*: http://mhucka.github.io/rsmirror

*Repository*:   https://github.com/mhucka/rsmirror


Background
----------

Sometimes you want to mirror one or more directories to a remote machine on a regular basis.  The tried and true, secure approach is to use `rsync` over `ssh` between Unix/Linux-based systems.  However, properly configuring `rsync` for mirroring can be a challenge, particularly when transferring Mac OS X files, because one has to provide a number of arguments to `rsync` to preserve as many of the Mac OS X file attributes as possible.  (It also requires using a suitable version of `rsync`.)  Moreover, one may want to establish a timeout to limit the maximum duration for the entire process, log the results of all activities, and more.

This script encapsulates these arguments, plus it adds additional features useful for situations where you regularly mirror a directory to a remote machine.  For example, it tells rsync to delete files from the remote copy if they are no longer present in the source directory being mirrored.  It also tries to do a best effort for the case when the remote is not a Mac OS X system (and thus lacks the necessary support for some HFS+ file system features).  Finally, this script provides some useful conveniences, such as support for configuration files, logging, and the ability to mail a log to a destination address upon completion.  The script is written to use the plain Bourne `sh` shell, for increased portability.


Requirements and strong recommendations
---------------------------------------

1. This requires `rsync` 3.0.5 or higher on both the client and backup server.  (Important: **OS X provides a much older version of `rsync`, even in Mac OS X 10.9 Mavericks&mdash;do not use the default Mac OS X version**.)

2. This requires the "fileflags", "hfs-compression" and "crtimes" patches for `rsync` to be applied on Mac OS X systems.  As of 2011-01-19, the version of `rsync` supplied by MacPorts is 3.0.7 and it includes the necessary patches.  If you need to compile your own copy, see the `rsync` distribution's patch directory for more information.  (For version 3.0.5,  http://rsync.samba.org/ftp/rsync/src/rsync-patches-3.0.5.tar.gz)

3. You are *strongly* advised to configure the remote machine's file system to be case-sensitive.  This is the default on Linux, but on Mac OS X, a **different-from-the-defaults setting must be used when formatting the disk**.  Without a case-sensitive destination file system, you will encounter problems copying a directory that contains both a file with a certain name and a subdirectory with the same name, as well as when a file changes only in the case of its name from one occasion to another.


Installation
------------

Prior to installing and attempting to run `rsmirror`, you may want to set up password-less `ssh` connections between your local and remote computers.  If this is unfamiliar, please search the Internet for instructions on how to set up password-less ssh logins.

The installation process for `rsmirror` itself is simple:

**1.** Copy `rsmirror` to a directory of your choosing, and make sure it is executable.

**2.** Copy `sample.config` to a location of your choosing, renaming it to something suitable for your situation.  If you want to create multiple mirroring configurations, copy `sample.config` as many times as you need and give each copy a different name.

**3.** Edit the configuration file(s).  Set the values for the different variables inside.  The comments inside the sample configuration file explain the purposes of the variables.

**4.** Do a basic test of your configuration by invoking `rsmirror -n -c CONFIG`, where `CONFIG` signifies the path to the configuration file from steps 2-3.  The `-n` flag tells `rsmirror` to do a dry run.  The test process will attempt to run the remote `rsync`, but will not transfer any files; if any configuration or connectivity problems exist, they will probably be revealed by doing this.

Once the above are done, you can invoke `rsmirror -c CONFIG` whenever you want to mirror the directory.  You may find it convenient to set up a cron job to perform the task on a nightly basis.  (Note, however, that this will not work unless you also set up password-less `ssh` connections between your local and remote computers, as mentioned above.)


Usage
-----

`rsmirror` takes five arguments, one required and two optional:

* `-c` is a required argument; it must be followed by the pathname of a configuration file.  A sample configuration file is provided as `sample.config` in this directory.

* `-h` means print a summary of the usage and available arguments.

* `-m` means skip the test to determine whether the remote host is running Mac&nbsp;OS&nbsp;X; assume that it is.

* `-n` means do a "dry run": explain what would be done without actually doing it.

* `-o` means skip the test to determine whether the remote host is running Mac&nbsp;OS&nbsp;X; assume that it is *not*.

* `-q` means be quiet: don't print informative messages.  (However, if logging is configured, then `rsmirror` will still write the log file.)

* `-s` means skip some paranoid security checks.  Without this, `rsmirror` will complain about a few things such as when the owner of the process is different from the owner of the configuration file.

* `-v` means print the version information and then exit.

Please read the comments in the file `sample.config` for information about the configuration file variables available.

When you first configure a new host, you will probably want to use the `-n` (dry run) option to make `rsmirror` show what would be done, without doing it.  As part of this, `rsmirror` will still attempt to connect to the remote host and run its normal tests, so doing a dry run will often reveal problems of `ssh` connectivity and remote command invocation.  

Once your configuration is debugged, invoking `rsmirror` will usually be very simple and along the lines of the following:

~~~~~sh
rsmirror -c /path/to/my.config
~~~~~

If you are running `rsmirror` from `cron`, you will probably want to use the `-q` option to make `rsmirror` less chatty.  It will then only report errors and exit with an error code if something goes wrong, which is usually what you want when running a process from `cron`:

~~~~~sh
rsmirror -q -c /path/to/my.config
~~~~~


Return values
-------------

`rsmirror` returns a status code depending on the results of its actions. The numeric codes are grouped for easier interpretation; the possible codes are the following:

* 0: normal return; no errors.

* 1&ndash;99: if the number is between 1 and 99, it is the status code returned by rsync in the case of an rsync error.

* above 100: if the number is above 100, it is an error code produced by `rsmirror` itself.


Contributing
------------

I welcome improvements of all kinds, to the code and to the documentation.
Please feel free to contact me or do the following:

1. Fork this repo.  See the links at the top of the github page.
2. Create your feature branch (`git checkout -b my-new-feature`) and write
your changes to the code or documentation.
3. Commit your changes (`git commit -am 'Describe your changes here'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Create a new pull request to notify me of your suggested changes.

Here are some suggestions for what could be improved or added to `rsmirror`:

* If the option to email the log is enabled, make `rsmirror` compress the log before mailing it.

* Add an option to print the output from rsync to the console, for debugging.  Currently, `rsmirror` only writes the rsync output to the log file.

* For better security, make `rsmirror` read the configuration file and look only for variable settings, instead of what it does currently, which is to source the configuration file.


License
-------

Copyright (C) 2008-2014 by the California Institute of Technology, Pasadena, USA.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or any later version.

This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY, WITHOUT EVEN THE IMPLIED WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  The software and documentation provided hereunder is on an "as is" basis, and the California Institute of Technology has no obligations to provide maintenance, support, updates, enhancements or modifications.  In no event shall the California Institute of Technology be liable to any party for direct, indirect, special, incidental or consequential damages, including lost profits, arising out of the use of this software and its documentation, even if the California Institute of Technology has been advised of the possibility of such damage.  See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with this library in the file named "COPYING.txt" included with the software distribution.
