rsmirror
========

A shell script for mirroring a Mac OS X directory to a remote computer.  It uses rsync over ssh, with settings that attempt to preserve Mac OS X file attributes even if the server is not a Mac or does not use an HFS+ file system.

----
*Author*:       Michael Hucka (http://www.cds.caltech.edu/~mhucka)

*Copyright*:    Copyright (C) 2008-2014 by the California Institute of Technology, Pasadena, USA.

*License*:      This code is licensed under the LGPL version 2.1.  Please see the Please see the file [../COPYING.txt](https://raw.github.com/mhucka/rsmirror/master/COPYING.txt) for details.

*Project page*: http://mhucka.github.io/rsmirror

*Repository*:   https://github.com/mhucka/rsmirror


Requirements
------------

1. This requires `rsync` 3.0.5 or higher on both the client and backup server.

2. This requires the `fileflags` and `crtimes` patches for `rsync` to be applied on Mac OS X systems.  For more information, see the `rsync` patch directory (which, for version 3.0.5, is http://rsync.samba.org/ftp/rsync/src/rsync-patches-3.0.5.tar.gz).  As of 2011-01-19, the version of `rsync` supplied by MacPorts is 3.0.7 and includes the necessary patches.


Background
----------

Sometimes you want to mirror one or more directories to a remote machine, for example to keep off-site file backups for emergencies, or for remote access (e.g., if you regularly work from two sites), or simply to use as an alternative to a cloud-based backup system.  The tried and true secure scheme is to use `rsync` over ssh between Unix/Linux-based systems.  However, when copying files from Mac OS X systems to non-Mac systems, one has to provide a number of arguments to `rsync` to preserve as many of the Mac OS X file attributes as possible (and the copy of `rsync` on the server may need to be patched to support the arguments).  This script encapsulates these arguments, plus adds a few additional useful features for situations where you are regularly mirroring a directory to a remote machine (such as making it delete files from the remote copy if they are no longer present in the source directory being mirrored).


Installation
------------

The installation is simple.

**1.** Copy `rsmirror.sh` to a directory of your choosing, and make sure it is executable.

**2.** Copy `sample.config` to a location of your choosing, renaming it to something suitable (perhaps named after the directory you are going to mirror).  If you want to create multiple mirroring configurations, copy `sample.config` as many times as you need and give each copy a different name.

**3.** Edit the configuration file(s).  Set the values for the different variables inside.  The comments explain the purposes of the variables.

**4.** Test your configurations, first by invoking `rsmirror.sh -n -c CONFIG` (where the `-n` flag tells rsmirror.sh to echo what it will do without actually doing it, and `CONFIG` is the path to a configuration file from steps 2-3), and then by invoking `rsmirror.sh -c CONFIG` and checking that it appears to have done what you expected.

Once that is done, you can invoke `rsmirror.sh -c CONFIG` whenever you want to mirror the directory.  You may find it convenient to set up a cron job to perform the task on a nightly basis.


Usage
-----

`rsmirror.sh` takes three arguments, one required and two optional:

* `-c CONFIG` is a required argument; `CONFIG` must be the pathname of a configuration file.

* `-n` means do a "dry run": explain what would be done without actually doing it.

* `-q` means be quiet: don't print informative messages.  (However, if logging is configured, then `rsmirror.sh` will still write the log file.)


License
-------

Copyright (C) 2008-2014 by the California Institute of Technology, Pasadena, USA.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or any later version.

This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY, WITHOUT EVEN THE IMPLIED WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  The software and documentation provided hereunder is on an "as is" basis, and the California Institute of Technology has no obligations to provide maintenance, support, updates, enhancements or modifications.  In no event shall the California Institute of Technology be liable to any party for direct, indirect, special, incidental or consequential damages, including lost profits, arising out of the use of this software and its documentation, even if the California Institute of Technology has been advised of the possibility of such damage.  See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with this library in the file named "COPYING.txt" included with the software distribution.
