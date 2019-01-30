
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
