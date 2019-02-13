
# For Highlighting
```
alias hl="egrep -E '^|<<[^>]+(>>|$)|^[^<>]+>>'"
find_times.pl ~/Calibre\ Library/James\ Joyce/Dubliners\ \(3196\)/*epub | hl
```

# To regen books with '9n:1' in the matches
```
make_books.pl "$(ag '\|9n:1' books -l | sort | cut -f 2 -d / | sed 's/\.dmp$//' | uniq | paste -sd \|)"
```

# To find all 2* matches
```
process_books.pl books/ '^2[a-z]?(:\d)?$' 100
```

# To find failing 3 matches
```
process_books.pl books/ '^3:0$' 100
```

# To re-run the matches with the new rules
```
test_books.pl books/ '91(:\d)?$' 100
```

# To run the tests
```
prove t/*pl -j 8
```


## The Matches

```
1   - Definite.  2330 hours; 2330h.
1a  - Definite.  21:00 local time.  2330 GMT
1b  - Definite.  04h24m
1c  - Definite.  GMT 19.34
2   - Strong.    22:00
2a  - Definite.  11:56 p.m.
3   - Strong.    19.40.
3a  - Weak.      0030 on Saturday
3b  - Weak.      1900 tonight.                     Low numbers need attention 'one'
3c  - Weak.      on the 10.26
3d  - Strong.    seven the next evening.
3e  - Never.     --
3f  - 80% right?
3g  - Strong.    Monday at five Leo
3h  - Strong.    At about one Emily announced
3i  - Strong.    at a little before ten the night
3j  - Strong.    at two the previous afternoon
4   - Strong.    20.36 Rimmer stood...
5   - Strong.    eight-fifteen at night
5a  - Weak.      23.10                               Could do some cleanup
5b  - Strong.    at eleven-thirty
5d  - Strong.    due ... at five-thirty P.M.
5f  - Definite.  on the six forty-five train
5g  - Strong.    twelve by Big Ben
5h  - Definite.  In ten minutes it would be one
6   - Definite.  six o’clock
9   - Weak.      About seven                         Needs work
9b  - Strong.    there at eleven.
9c  - Strong.    end of phrase times
9d  - BAD.       It was ten                          BAD
9e  - Eliminate -- save "Anyway, <<after two|9:0>>, he sat politely in his dean of extension"
9f  - Strong.    Call it three.
9g  - Strong.    starting at seven.
9h  - Strong.    past eleven at night.
9j  - Strong.    Two-fifteen
9k  - Strong.    Around one.
9l  - Strong.    0517.
9m  - Strong.    At 12.30
y9n - Never.     until 1543                           These deliberately never match
9o  - Strong.    tomorrow at one
9p  - Strong.    13.40.                               Some minor rough edges
9q  - Weak.      make it five,
y9r - Strong.    young boy, about eleven or twelve,   These deliberately never match
9s  - Strong.    Daily, about eleven,
9t  - Weak.      At twelve                            Needs work
9u  - Strong.    at six                               Minor tweaking around 'one'
9v  - Strong.    at six,                              Needs some tweaks around ages
9w  - Strong.    by eight                             Minor tweaking around 'one' and 'two'
9x  - Definite.  about ten,
9y  - Definite.  Four now.                            James Joyce special
10  - Strong.    twenty minutes to twelve
10a - Mixed.     ten to midnight,                     Needs work, completely mixed
10b - Never.     two of 13
10c - Strong.    struck eleven.
10d - Strong.    at ten to midnight                   Recheck for 'three to one'
11  - Strong.    clock struck thirteen.
11a - Strong.    Ten minutes before the clock struck nine
11b - Stong.     It showed two                        Never matches
12  - Definite.  stroke of three.
13  - Definite.  Vespers
14  - Definite.  eleven o’clock and twenty-four minutes p.m.
14a - Definite.  What o'clock ... One hour and a quarter,
15  - XXX Need to re-run... bell times were missing
16  - Strong.    well before Prime,                   Need to re-check, added _P_rime
17  - Definite.  nearer to one than half past.
18  - BAD.       about 2300,                          Needs work, too muddled
19  - Definite.  new day was still a minute away.
20  - Definite.  the hour of eleven
20a - Strong.    or eleven                            Continuation
20b - Strong.    From two until five                  Need to check 'three to one'
21  - Definite.  In 5 minutes it would be 11

90  - Strong.    between eleven and <<
91  - Strong.    >> and three
```

- Mask out tennis scores if it looks tennissy? "male collegians his game is built around his serve. At 0–15, his first serve is flat" -- Wallace, Suppose