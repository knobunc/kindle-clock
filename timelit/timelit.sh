#!/bin/sh

BASEDIR="/mnt/us/timelit"

# if the Kindle is not being used as clock, then just quit
test -f "$BASEDIR/clockisticking" || exit


# find the current minute of the day
MinuteOTheDay="$(env TZ='EST+5EDT,M3.2.0/2,M11.1.0/2' date -R +"%H%M")";

# check if there is at least one image for this minute 
lines="$(find "$BASEDIR/images/quote_$MinuteOTheDay"* 2>/dev/null | wc -l)"
if [ $lines -eq 0 ]; then
    echo "no images found for '$MinuteOTheDay'"
	exit
else
    echo "$lines files found for '$MinuteOTheDay'"
fi


# randomly pick a png file for that minute (since we have multiple for some minutes)
ThisMinuteImage=$( find "$BASEDIR/images/quote_$MinuteOTheDay"* 2>/dev/null | python -c "import sys; import random; print(''.join(random.sample(sys.stdin.readlines(), int(sys.argv[1]))).rstrip())" 1)

echo $ThisMinuteImage > "$BASEDIR/clockisticking"

# Flip the path to show the source if desired
if [ -f "$BASEDIR/showsource" ]; then
	# find the matching image with metadata
	ThisMinuteImage=$(echo $ThisMinuteImage | sed 's/.png//')_credits.png
	ThisMinuteImage=$(echo $ThisMinuteImage | sed 's/images/images\/metadata/')
fi

# Do a full repaint every 20 minutes
clearFlag=""
if echo $MinuteOTheDay | grep -q '^..[024]0$'; then
        clearFlag="-f"
fi

# show that image
eips $clearFlag -g $ThisMinuteImage

# Sync the clock over ntp daily
if [ "$MinuteOTheDay" -eq '0000' ]; then
    ntpdate pool.ntp.org
fi
