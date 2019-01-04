#!/bin/sh

# This refreshes the files on the kindle from an rsync with the target host.
#
# It assumes that you have ssh keys set up to run without needing a password.
#
# The expectation is that it will be run periodically from /etc/crontab/root:
# e.g., for every 15 mins:
#   */15 * * * * sh /mnt/us/utils/update.sh > /mnt/us/updatelog 2>&1
# or every day, 5 mins after midnight:
#   5 0 * * * sh /mnt/us/utils/update.sh > /mnt/us/updatelog 2>&1

RSYNC_SOURCE="fiji@limey.net:kindle/kindle-clock"

# The target filesystem doesn't allow modification of mtime, setting of user, or setting of permissions
RSYNC_OPTIONS="-vi -rltD --omit-dir-times"

cd /mnt/us

# Update all of the files in util and completely replace them with the new stuff
# To do this manually:
#  /usr/bin/rsync -rltD --omit-dir-times --delete-delay --delay-updates fiji@limey.net:kindle/kindle-clock/utils/ utils
echo "Updating utils..." > updatestatus
/usr/bin/rsync $RSYNC_OPTIONS --delete-delay --delay-updates "${RSYNC_SOURCE}/utils/" utils

# Update all of the files in timelit and completely replace them with the new stuff
# BUT ignore the images, we do that later
# AND do not update the showsource and clockisticking state files
echo "Updating timelit..." > updatestatus
/usr/bin/rsync $RSYNC_OPTIONS --delete-delay --exclude /images --exclude /showsource --exclude /clockisticking "${RSYNC_SOURCE}/timelit/" timelit

# Update the images, but we don't care about the times
echo "Updating images..." > updatestatus
/usr/bin/rsync $RSYNC_OPTIONS --size-only --delete-delay "${RSYNC_SOURCE}/timelit/images/" timelit/images

# Update the launchpad init file, but leave the rest of the directory alone
echo "Updating launchpad..." > updatestatus
/usr/bin/rsync $RSYNC_OPTIONS "${RSYNC_SOURCE}/launchpad/" launchpad

# Restart launchpad so the command changes take effect
/etc/init.d/launchpad restart

echo "Update complete!"
sleep 1
rm updatestatus

