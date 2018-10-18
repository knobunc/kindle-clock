#!/bin/sh

# This refreshes the files on the kindle from an rsync with the target host.
#
# It assumes that you have ssh keys set up to run without needing a password.
#
# The expectation is that it will be run periodically from /etc/crontab/root:
# e.g., for every 15 mins:
#   */15 * * * * sh /mnt/us/utils/update.sh
# or every day, 5 mins after midnight:
#   5 0 * * * sh /mnt/us/utils/update.sh

RSYNC_SOURCE="fiji@limey.net:kindle/kindle-clock"

# The target filesystem doesn't allow modification of mtime, setting of user, or setting of permissions
RSYNC_OPTIONS="-rltD --omit-dir-times"

cd /mnt/us

# Update all of the files in util and completely replace them with the new stuff
/usr/bin/rsync $RSYNC_OPTIONS --delete-delay --delay-updates "${RSYNC_SOURCE}/utils/" utils

# Update all of the files in timelit and completely replace them with the new stuff
/usr/bin/rsync $RSYNC_OPTIONS --delete "${RSYNC_SOURCE}/timelit/" timelit

# Update the launchpad init file, but leave the rest of the directory alone
/usr/bin/rsync $RSYNC_OPTIONS "${RSYNC_SOURCE}/launchpad/" launchpad

# Restart launchpad
/etc/init.d/launchpad restart
