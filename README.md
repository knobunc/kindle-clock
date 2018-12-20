# Literary Clock Scripts

See source repository -- https://github.com/knobunc/kindle-clock

## What is this?

This is a repo to make installation and maintenance of the "literary
clock" for the Kindle a little easier.  All credit to tjaap, you can
see his instructable at:
https://www.instructables.com/id/Literary-Clock-Made-From-E-reader/


## How to Install

1. Jailbreak your Kindle, install launchpad, python, and usbnet.  Instructions
   are at step 2 of https://www.instructables.com/id/Literary-Clock-Made-From-E-reader/
   1. I would make a directory of all of the uninstall scripts on the device too, so
      removal is easier
2. git clone the repo to somewhere you can rsync from
3. Install your private key in `/mnt/us/usbnet/etc/dot.ssh` so rsync will work for updates
4. ssh into the kindle
   1. If you want to use usbnet rather than wifi (on Linux):
   2. Copy the `launchpad/startClock.ini` to the `launchpad` directory on the USB filesystem
      on the Kindle and hit `shift shift spacebar` to reread the launchpad config (or just
      Restart, the timing can be tricky)
   3. Start USBNet with `shift n`
   4. Enable the network interface
```
sudo ifconfig usb0 192.168.2.1/24
```
   5. And ssh in (`-a` disables agent forwarding so we can test our key).  There is no password, hit enter.
```
ssh -a root@192.168.2.2
```
5. On the kindle rsync the utils directory:
```
/usr/bin/rsync -rltD --omit-dir-times --delete-delay --delay-updates f@l.net:kindle/kindle-clock/utils/ /mnt/us/utils
```
6. Install the needed cron jobs:
```
mntroot rw
cat >> /etc/crontab/root <<EOF
* * * * * sh /mnt/us/timelit/timelit.sh
5 0 * * * sh /mnt/us/utils/update.sh > /mnt/us/updatelog 2>&1
EOF
mntroot ro
```
7. Add a boot script to cleanup the clockisticking file... since it shouldn't be after a boot
```
mntroot rw
cp /mnt/us/utils/clean-clock /etc/init.d/
cd /etc/rcS.d
ln -s ../init.d/clean-clock S77clean-clock
mntroot ro
```
8. Sync everything over with an update:
```
cd /mnt/us
sh /mnt/us/utils/update.sh
```
9. Tell launchpad to reload its config:
```
/etc/init.d/launchpad restart
```
10. Type `shift c` to start the clock (and to end it).  You may need to
wait a moment between the `shift` and the `c` for it to register
correctly.


## Usage

Commands added to launchpad:
* `shift c`: Starts or stops the clock
* `shift n`: Starts or stops usbnet
* `shift u`: Kicks off a manual update

While the clock is running:
* `next page` or `previous page`: Toggles display of the source of the quotes


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
