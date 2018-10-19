# Literary Clock Scripts

## What is this?

This is a repo to make installation and maintenance of the "literary
clock" for the Kindle a little easier.  All credit to tjaap, you can
see his instructable at:
https://www.instructables.com/id/Literary-Clock-Made-From-E-reader/


## How to Install

1. Jailbreak your Kindle, install launchpad and usbnet.  Instructions
   are at step 2 of https://www.instructables.com/id/Literary-Clock-Made-From-E-reader/
2. git clone the repo to somewhere you can rsync from
3. ssh into the kindle
4. On the kindle rsync the utils directory:
```
/usr/bin/rsync -rltD --omit-dir-times --delete-delay --delay-updates fiji@limey.net:kindle/kindle-clock/utils/ /mnt/us/utils
```
5. Install the needed cron jobs:
```
cat >> /etc/crontab/root <<EOF
* * * * * sh /mnt/us/timelit/timelit.sh
5 0 * * * sh /mnt/us/utils/update.sh > /mnt/us/updatelog 2>&1
EOF
```
6. Add a boot script to cleanup the clockisticking file... since it shouldn't be after a boot
```
mntroot rw
cp /mnt/us/utils/clean-clock /etc/init.d/
cd /etc/rcS.d
ln -s ../init.d/clean-clock S77clean-clock
mntroot ro
```
7. Tell launchpad to reload its config:
```
/etc/init.d/launchpad restart
```
8. Type `shift c` to start the clock (and to end it).  You may need to
wait a moment between the shift and the c for it to register
correctly.


## Links

* Main guide:
  * https://www.instructables.com/id/Literary-Clock-Made-From-E-reader/

* Various details about kindle and hacking:
  * https://grenville.wordpress.com/2011/09/25/kindle-jailbreak-usb-networking/
  * https://www.turnkeylinux.org/blog/kindle-root

* All k3w Kindle commands:
  * http://blog.diannegorman.net/2010/09/kindle-3-keyboard-shortcuts-et-al/

* A web version of the clock:
  * http://jenevoldsen.com/literature-clock/

* My version of the quotes:
  * https://docs.google.com/spreadsheets/d/1Y6jlhHDkpwyFxv8mav74SQwXLYGfCX6AJ9-ZOyZAFig/edit#gid=402741642
