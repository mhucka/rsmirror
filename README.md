rsmirror
========

A shell script for mirroring a Mac OS X directory to a remote computer.  It uses rsync over ssh, with settings that attempt to preserve Mac OS X file attributes even if the server is not a Mac or does not use an HFS+ file system.

----
*Author*: Michael Hucka (http://www.cds.caltech.edu/~mhucka)

*Copyright*: Copyright (C) 2011-2014 by the California Institute of Technology, Pasadena, USA.

*License*: This code is licensed under the LGPL version 2.1.  Please see the Please see the file [../COPYING.txt](https://raw.github.com/mhucka/rsmirror/master/COPYING.txt) for details.

*Repository*: https://github.com/mhucka/rsmirror


Requirements
------------

1. This requires rsync 3.0.5 or higher on both the client and backup server.

2. This requires the fileflags and crtimes patches for rsync to be applied on Mac OS systems.  For more information, see the rsync patch directory (which, for version 3.0.5, is http://rsync.samba.org/ftp/rsync/src/rsync-patches-3.0.5.tar.gz).  As of 2011-01-19, the rsync supplied by MacPorts is 3.0.7 and includes the necessary patches.


Background
----------


Usage
-----

There are three parts to using this.

### Installing the plug-in

### Configuring the plug-in


License
-------

Copyright (C) 2011-2014 by the California Institute of Technology, Pasadena, USA.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or any later version.

This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY, WITHOUT EVEN THE IMPLIED WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  The software and documentation provided hereunder is on an "as is" basis, and the California Institute of Technology has no obligations to provide maintenance, support, updates, enhancements or modifications.  In no event shall the California Institute of Technology be liable to any party for direct, indirect, special, incidental or consequential damages, including lost profits, arising out of the use of this software and its documentation, even if the California Institute of Technology has been advised of the possibility of such damage.  See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with this library in the file named "COPYING.txt" included with the software distribution.
