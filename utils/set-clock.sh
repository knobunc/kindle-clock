#!/bin/sh

# This sets the clock by ntp

NTPSERVER=time.google.com
TIMEOUT=30

killall ntpdate
ping -c 1 "$NTPSERVER" || exit 1

ntpdate "$NTPSERVER" & pid=$!

count=1
while [ $count -lt $TIMEOUT ]; do
    if [ -e "/proc/$pid" ]; then
        break
    fi
    sleep 1
done

if [ -e "/proc/$pid" ]; then
    kill $pid
fi

fg
exit $?
