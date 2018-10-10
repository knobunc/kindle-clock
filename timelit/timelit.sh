#!/bin/sh

# if the Kindle is not being used as clock, then just quit
test -f /mnt/us/timelit/clockisticking || exit


# find the current minute of the day
MinuteOTheDay="$(env TZ=EST5EDT date -R +"%H%M")";

# check if there is at least one image for this minute 
lines="$(find /mnt/us/timelit/images/quote_$MinuteOTheDay* 2>/dev/null | wc -l)"
if [ $lines -eq 0 ]; then
	echo 'no images found for '$MinuteOTheDay
	exit
else
	echo $lines' files found for '$MinuteOTheDay
fi


# randomly pick a png file for that minute (since we have multiple for some minutes)
ThisMinuteImage=$( find /mnt/us/timelit/images/quote_$MinuteOTheDay* 2>/dev/null | python -c "import sys; import random; print(''.join(random.sample(sys.stdin.readlines(), int(sys.argv[1]))).rstrip())" 1)

echo $ThisMinuteImage > /mnt/us/timelit/clockisticking

# Flip the path to show the source if desired
if [ -f /mnt/us/timelit/showsource ]; then
	# find the matching image with metadata
	ThisMinuteImage=$(echo $ThisMinuteImage | sed 's/.png//')_credits.png
	ThisMinuteImage=$(echo $ThisMinuteImage | sed 's/images/images\/metadata/')
fi

# clear the screen
eips -c

# show that image
eips -g $ThisMinuteImage

