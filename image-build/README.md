
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


1  - Definite.  2330 hours; 2330h.
1a - Definite.  21:00 local time.  2330 GMT
1b - Definite.  04h24m
1c - Definite.  GMT 19.34
2  - Strong.    22:00
2a - Definite.  11:56 p.m.
3  - Strong.    19.40.
3a - Weak.      0030 on Saturday
3b - Weak.      1900 tonight.
3c - Weak.      on the 10.26
3d - Strong.    seven the next evening.
3e - BAD                                           BAD
3f - 80% right?
3g - Strong.    Monday at five Leo
3h - Strong.    At about one Emily announced
3i - Strong.    at a little before ten the night
3j - Strong.    at two the previous afternoon
4  - Strong.    20.36 Rimmer stood...
5  - Strong.    eight-fifteen at night
5a - Weak.      23.10                               Could do some cleanup
5b - Strong.    at eleven-thirty
5d - Strong.    due ... at five-thirty P.M.
5f - Definite.  on the six forty-five train
5g - Strong.    twelve by Big Ben
5h - Definite.  In ten minutes it would be one
6  - Definite.  six o’clock
9  - Weak.      About seven                         Needs work
9b - Strong.    there at eleven.
9c - Strong.    end of phrase times
9d - BAD.       It was ten                          BAD
9e - Eliminate -- save "Anyway, <<after two|9:0>>, he sat politely in his dean of extension"
9f - Strong.    Call it three.
9g - Strong.    starting at seven.
9h - Strong.    past eleven at night.
9j - Strong.    Two-fifteen
9k - Strong.    Around one.
9l - Strong.    0517.
9m - Strong.    At 12.30
y9n- Never.     until 1543                           These deliberately never match
9o - Strong.    tomorrow at one
9p - Strong.    13.40.                               Some minor rough edges


Need to match:
--------------

"Who at this hour? Three, good Heavens! <<Three already>>!"