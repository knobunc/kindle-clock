
# For Highlighting
```
alias hl="egrep -E '^|<<[^>]+(>>|$)|^[^<>]+>>'"
find_times.pl ~/Calibre\ Library/James\ Joyce/Dubliners\ \(3196\)/*epub | hl
```

# To regen books with '9n:1' in the matches
```
make_books.pl "$(ag '\|9n:1' -l | sort | cut -f 2 -d / | cut -f 1 -d - | uniq | paste -sd \|)"
```

# To find all 2* matches
```
process_books.pl books/ '^2[a-z]?(:\d)?$' 100
```

# To find failing 3 matches
```
process_books.pl books/ '^3:0$' 100
```

# To run the tests
```
prove t/*pl -j 8
```
