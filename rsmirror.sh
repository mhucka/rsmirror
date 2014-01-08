#!/bin/sh
# -----------------------------------------------------------------------------
# Description:  Run rsync to back up a Mac OS X directory to a server.
# Author:	Michael Hucka <mhucka@caltech.edu>
# Date created: Sometime in 2008
# Organization: California Institute of Technology
# -----------------------------------------------------------------------------
#
# This is a script for mirroring a Mac OS X directory to a remote computer.
# It uses rsync over ssh, with settings that attempt to preserve Mac OS X
# file attributes even if the server is not a Mac or does not use an HFS+
# file system.  This is not intended to be used with an "rsync server"; it is
# intended for the situation where you simply have a remote computer with
# rsync and ssh installed.  In normal usage, you would invoke this script
# from a crontab entry to regularly mirror a directory on your local computer
# to the remote computer.
#
# Features:
# * Uses rsync flags suitable for preserving Mac attributes on non-Mac servers.
# * Uses compression, but turns it off for common binary file types.
# * Writes a log file and rsync's a copy of the log file to the server.
#
# Notes:
# * This requires rsync 3.0.5 or higher on both the client and backup server.
#
# * This requires the fileflags and crtimes patches to be applied on MacOS.
#   See http://rsync.samba.org/ftp/rsync/src/rsync-patches-3.0.5.tar.gz
#   As of 2011-01-19, the rsync supplied by MacPorts is 3.0.7 and includes
#   the necessary patches.
#
# * Make sure the remote machine uses a case-sensitive file system, or
#   else you may encounter problems with updating files that only changed
#   in the case of their names.
#
# * Make sure to change the configuration variables for each client.
#   Be careful to include a trailing '/' character in $REMOTE_DIR.
#
# * This writes a log file to a directory set by $LOG_DIR.  After it
#   finishes a backup, it runs rsync a 2nd time to copy only the log file
#   to the top-level directory on the destination, for convenient access.

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# Configuration variables
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

# Full path to rsync on this computer.
#
LOCAL_RSYNC="rsync"

# Path to rsync on the backup server.  Leave blank to use whatever the
# default may be on the remote server.
#
REMOTE_RSYNC=""

# The remote shell program and arguments to use when invoking rsync on the
# local host.  This is passed to rsync using the --rsh argument.  Only change
# this value from its default (which is "ssh") if you need to provide
# arguments to the ssh command.
#
RSYNC_RSH="ssh"

# The remote backup server's host name.
#
REMOTE_HOST="CHANGEME"

# Path to the local directory that we're backing up.
#
LOCAL_DIR="CHANGEME"

# Path where backups will be put on the backup server.  If this is a relative
# pathname, then it will be relative to the user's home directory on the
# remote system.  (E.g.: if your login is "jimmy" and REMOTE_DIR="backups/",
# then the mirrored files will be put in ~jimmy/backups/ on the remote host.)
#
REMOTE_DIR="CHANGEME"

# Full path to a file of personal files to exclude from the mirror.  See the
# rsync man page for info about how to use the --exclude-from option.  Change
# the next variable to an empty string (PERSONAL_EXCLUDES="") if you don't
# have anything to exclude.
#
PERSONAL_EXCLUDES=""

# Root name to use for the log file.  This will be concatenated with a date
# stamp to produce the final name of the log file that is written.
#
LOG_ROOT_NAME="CHANGEME"

# Full path to a directory where log files will be written by this script.
# Possible example: "$HOME/.logs/$LOG_ROOT_NAME"
#
LOG_DIR="CHANGEME"


# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# Body of script.  No more configuration should be necessary after this point.
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

# Test the version of rsync.

version=`"$LOCAL_RSYNC" --version 2>&1 | head -n 1 | sed 's/.* \([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p; d'`
x=`expr $version : '\([0-9]*\)\.[0-9]*\.[0-9]*'`
y=`expr $version : '[0-9]*\.\([0-9]*\)\.[0-9]*'`
z=`expr $version : '[0-9]*\.[0-9]*\.\([0-9]*\)' '|' 0`

if test $x -lt 3 || (test $x -eq 3 && test $y -lt 1 && test $z -lt 5); then
    echo "Requires at least rsync 3.0.5, but found only $x.$y.$z"
    exit 1
fi

# [Notes 2008-10-20] It is not clear to me whether --force-change should be
# used only for MacOS or for all clients.  Also, --fileflags does not exist
# on RHEL Server linux (and possibly others).  This leads to the following:

if [ "`uname`" = "Darwin" ]; then
  OS_FLAGS="--crtimes --acls --xattrs --fileflags --force-change"
  OS_EXCLUDES="--exclude cores --exclude .Spotlight-V100"
else
  OS_FLAGS="--iconv=UTF-8-MAC,UTF-8"
  OS_EXCLUDES="--exclude proc"
fi

# The following are hopefully generic to everything:

BASIC="-vaxH --stats --numeric-ids --fake-super --delete --delete-excluded --ignore-errors"
EXCLUDES="--exclude /dev $OS_EXCLUDES $PERSONAL_EXCLUDES"
NOCOMPRESS1="gz/zip/z/rpm/deb/iso/bz2/tgz/7z/mp3/mp4/m4p/mpg/mpeg/mov/avi"
NOCOMPRESS2="ogg/dmg/jpg/JPG/jpeg/gif/GIF/tif/tiff/png/PNG/NEF/pict/MYI/MYD"
COMPRESSION="-z --skip-compress=$NOCOMPRESS1/$NOCOMPRESS2"

FLAGS="$BASIC --rsh=\'$RSYNC_SSH\' $REMOTE_RSYNC $COMPRESSION $OS_FLAGS $EXCLUDES"

# Let's do this thing.

TIMESTAMP=`date '+%G-%m-%d-%H%M'`
LOGNAME="$LOG_ROOT_NAME-$TIMESTAMP.log"
LOGFILE="$LOG_DIR/$LOGNAME"

echo "Started at $TIMESTAMP"

mkdir -p $LOG_DIR

echo "Logging output to $LOGFILE"
echo "Running $LOCAL_RSYNC $FLAGS $LOCAL_DIR $REMOTE_HOST:$REMOTE_DIR/" > $LOGFILE

"$LOCAL_RSYNC" $FLAGS $LOCAL_DIR $REMOTE_HOST:$REMOTE_DIR/ >> $LOGFILE 2>&1

echo "Copying log file to remote directory."

"$LOCAL_RSYNC" $FLAGS -q $LOGFILE $REMOTE_HOST:$REMOTE_DIR/logs/$LOGNAME >> $LOGFILE 2>&1

echo "Done.  Ended at `date '+%G-%m-%d-%H%M'`"


# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# End of script.
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
