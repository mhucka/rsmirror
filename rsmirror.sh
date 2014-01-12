#!/bin/sh -x
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
# file system.
#
# Note that this is not intended to be used with an "rsync server", which is
# a machine running rsync as a service; it is intended for the situation
# where you simply have a remote computer with rsync and ssh installed.  In
# normal usage, you would invoke this script from a crontab entry to
# regularly mirror a directory on your local computer to the remote computer.
#
# Features:
# * Uses configuration files, for easy management of multiple mirrors
# * Uses rsync flags suitable for preserving Mac OS X file attributes, and
#   flags suitable for mirroring (e.g., deleting nonexistent files on server).
# * Uses compression, but turns it off for common binary file types.
# * Writes a log file.
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
# * This has the option of writing a log file to a directory set by $LOG_DIR.

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# Default values for configuration variables.
# Don't set the values here; use a configuration file and the -c flag.
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

# [Required] Path to the local directory that we're backing up.
#
LOCAL_DIR=CHANGEME

# [Required] The remote backup server's host name.
#
REMOTE_HOST=CHANGEME

# [Required] Path where backups will be put on the backup server.  If this is
# a relative pathname, then it will be relative to the user's home directory
# on the *remote* system.  (E.g.: if your login is "jimmy" and
# REMOTE_DIR="backups", then the mirrored files will be put in
# ~jimmy/backups/ on the remote host.)
#
REMOTE_DIR=CHANGEME

# [Optional] Full path to rsync on this computer.
#
LOCAL_RSYNC=rsync

# [Optional] Path to rsync on the backup server.  Leave blank to use whatever
# the default may be on the remote server.
#
REMOTE_RSYNC=

# [Optional] Full path to a file containging a list of files to exclude from
# the mirror.  See the rsync man page for info about how to use the
# --exclude-from option.  Note that rsmirror already excludes some things,
# notably .Spotlight-V100 files on Mac OS X, /dev, and on Linux, /proc.
#
EXTRA_EXCLUDES=

# [Optional] Full path to a directory where log files will be written by this
# script.  If set, a log file with the following name,
#
#     [CONFIG]-[DATE].log
#
# will be written in the directory, where [CONFIG] is the name of the given
# config file (via -c) minus any suffix, and [DATE] is the current date.  If
# not set, no log file will be written.  Note that you are highly advised to
# set up logging.  Possible example: "$HOME/.logs".
#
LOG_DIR=

# [Optional] Overall timeout, in seconds.  If set to a value X, rsmirror will
# quit after either the underlying rsync process has finished, or X seconds
# have elapsed, whichever comes sooner.  Set to an empty string if no timeout
# is desired.  Note: this is different from the timeout options that rsync
# provides, and does not represent any of them.
#
TIMEOUT=

# [Optional] The remote shell program and arguments to use when invoking
# rsync on the local host.  This is passed to rsync using the --rsh argument.
# Only change this value from its default (which is "ssh") if you need to
# provide arguments to the ssh command.
#
RSYNC_RSH=ssh

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# Body of script.  No more configuration should be necessary after this point.
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

# Read and check the command line arguments.

print_usage() {
    echo "Usage: $0 -c config [-n] [-q]" 1>&2
}

while getopts ":c:nq" option; do
    case "${option}" in
        c)
            config_file=${OPTARG}
            ;;
        n)
            dry_run="-n"
            ;;
        q)
            quiet=y
            ;;
    esac
done

if [ -z "$config_file" ]; then
    print_usage
    exit 1
fi

if [ ! -r "$config_file" ]; then
    echo "Unable to read configuration file $config_file"
    exit 1
fi

# Read the configuration file.

. $config_file

# Test the version of rsync.

version=$("$LOCAL_RSYNC" --version 2>&1 | head -n 1 | sed 's/.* \([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p; d')
x=$(expr $version : '\([0-9]*\)\.[0-9]*\.[0-9]*')
y=$(expr $version : '[0-9]*\.\([0-9]*\)\.[0-9]*')
z=$(expr $version : '[0-9]*\.[0-9]*\.\([0-9]*\)' '|' 0)

if test $x -lt 3 || (test $x -eq 3 && test $y -lt 1 && test $z -lt 5); then
    echo "Requires at least rsync 3.0.5, but found only $x.$y.$z"
    exit 1
fi

# Start the timeout timer, if one is set.

mainpid=$$
if [ "$TIMEOUT" -gt 0 ] 2>/dev/null; then
    msg="Configured timeout reached: terminating '$0 -c $config_file'"
    (sleep $TIMEOUT; echo $msg; kill $mainpid > /dev/null 2>&1) & watchdogpid=$!
fi

# Set up flags.

# [Notes 2008-10-20] It is not clear to me whether --force-change should be
# used only for MacOS or for all clients.  Also, --fileflags does not exist
# on RHEL Server linux (and possibly others).  This leads to the following:

if [ "`uname`" = "Darwin" ]; then
  os_flags="--crtimes --acls --xattrs --fileflags --force-change --hfs-compression --protect-decmpfs"
  os_excludes="--exclude .Spotlight-V100 --exclude /private/var/vm"
else
  os_flags="--iconv=UTF-8-MAC,UTF-8"
  os_excludes="--exclude /proc"
fi

if [ -n "${REMOTE_RSYNC}" ]; then
    remote_rsync="--rsync-path ${REMOTE_RSYNC}"
fi

# The following are hopefully generic to everything:

basic="-vaxH --stats --numeric-ids --fake-super --delete --delete-excluded --ignore-errors"
excludes="--exclude /dev $os_excludes $EXTRA_EXCLUDES"
nocompress1="gz/zip/z/rpm/deb/iso/bz2/tgz/7z/mp3/mp4/m4p/mpg/mpeg/mov/avi"
nocompress2="ogg/dmg/jpg/JPG/jpeg/gif/GIF/tif/tiff/png/PNG/NEF/pict/MYI/MYD"
compression="-z --skip-compress=$nocompress1/$nocompress2"

if [ -n "$RSYNC_SSH" ]; then
    flags="$basic --rsh=\'$RSYNC_SSH\' $remote_rsync $compression $os_flags $excludes"
else
    flags="$basic $remote_rsync $compression $os_flags $excludes"
fi

# Let's do this thing.

if [ -z "$dry_run" -a -n "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

timestamp=$(date '+%G-%m-%d:%H%M')
configname=$(basename $config_file)
logbasename=${configname%.*}
logname="$logbasename-$timestamp.log"

cleanup() {
  rm -f "$log_file"
  [ -e "$temp_log_dir" ] && rmdir "$temp_log_dir"
}

if [ "$LOG_DIR" != "" ]; then
    log_file="$LOG_DIR/$logname"
else
    temp_log_dir=$(mktemp -d /tmp/rsmirror-$logbasename.XXX)
    log_file="$temp_log_dir/$logname"
    trap "cleanup" EXIT
fi

if [ -z "$quiet" ]; then
    echo "Started at $timestamp"
fi


if [ -z "$dry_run" ]; then
    if [ "$LOG_DIR" != "" -a -z "$quiet" ]; then
        echo "Logging output to $log_file"
    fi
    echo "Using configuration file $config_file" > "$log_file"
    echo "Running $LOCAL_RSYNC $flags $LOCAL_DIR $REMOTE_HOST:$REMOTE_DIR/" > "$log_file"
else
    if [ "$LOG_DIR" != "" -a -z "$quiet"  ]; then
        echo "Will log output to $log_file"
    fi
    echo "Will use configuration file $config_file"
    echo "Will run $LOCAL_RSYNC $flags $LOCAL_DIR $REMOTE_HOST:$REMOTE_DIR/"
fi

if [ -z "$dry_run" ]; then
    "$LOCAL_RSYNC" $dry_run $flags "$LOCAL_DIR" $REMOTE_HOST:"$REMOTE_DIR"/ >> "$log_file" 2>&1
    if [ $? -ne 0 ]; then
	if [ "$LOG_DIR" != "" ]; then
	    echo "rsync returned an error -- check $log_file"
	else
	    echo "rsync returned error -- turn on logging for details"
	fi
    fi
fi

if [ -z "$quiet" ]; then
    echo "Done.  Ended at `date '+%G-%m-%d:%H%M'`"
fi

if [ "$TIMEOUT" -gt 0 ] 2>/dev/null; then
    kill $watchdogpid
fi

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# End of script.
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
