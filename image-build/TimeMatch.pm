package TimeMatch;

use Modern::Perl '2017';

use utf8;

use Exporter::Easy (
  EXPORT => [ qw( do_match extract_times ) ],
);


# Special named times
my $midnight_noon_re =
    qr{ ( high \s+ )? noon | noonday | mid[-\s]*day | noontime | noontide
      | midnight (?! \s+ oil )
      # Ecclesiastical times -- https://en.wikipedia.org/wiki/Liturgy_of_the_Hours
      | matins | lauds | terce | sext | vespers | compline | vigils | nocturns
      | night \s+ office
      | ( dawn | early \s+ morning | mid-morning | mid-?day | mid-afternoon | evening | night )
        \s+ prayer
      # Missing Prime and None
      }xin;

# Numbers 1-9 as words
my $low_num_re = qr{ one | two | three | four | five | six | seven | eight | nine }xi;

# The hours 1-12 as words
my $hour12_word_re = qr{ $low_num_re | ten | eleven | twelve | $midnight_noon_re }xi;
my $hour_word_re   = $hour12_word_re;

# The hours 13-24 as words
my $hour24_word_re = qr{ $hour_word_re | thirteen | fourteen | fifteen
                       | sixteen | seventeen | eighteen | nineteen
                       | twenty ( - ( one | two | three | four ) )?
                       }xin;

my $fraction_re = qr{ quarter | 1/4
                    | third   | 1/3
                    | half    | 1/2
                    | third \s+ quarter | three \s+ quarters | 3/4
                    }xin;

my $till_re = qr{ before | to | of | after | past | till | ['‘’]til | short \s+ of }xin;

# The minutes
my $min_word_re =
    qr{ # 1-9
        ( oh [\s-] | \b )? $low_num_re
        | # 10-19
        ( ten | eleven | twelve | thirteen | fourteen | fifteen |
            sixteen | seventeen | eighteen | nineteen )
        | # 20-59
        ( twenty | thirty | forty | fifty ) ( ( -| \s+ ) $low_num_re )?
      }xin;
my $sec_word_re = $min_word_re;

# Hour digits
my $hour_dig_re     = qr{ [01]?\d | 2[0-4] }xin;       # 00-24
my $hour12_dig_re   = qr{ [1-9] | 1[0-2] }xin;         # 1-12
my $hour24nz_dig_re = qr{ 0?[1-9] | 1\d | 2[0-4] }xin; # 01-24
my $hour24_dig_re   = $hour_dig_re;

# Min / sec digits
my $minsec_dig_re  = qr{ [0-5]?\d | 60 }xin;
my $minsec0_dig_re = qr{ [0-5]\d | 60 }xin;

# The minutes / seconds as words or numbers
my $min_re = qr{ $minsec_dig_re | $min_word_re }xin;
my $min0_re = qr{ $minsec0_dig_re | $min_word_re }xin;
my $sec_re = $min_re;

# The hours as words or numbers
my $hour_re   = qr{ $hour24_dig_re | $hour12_word_re }xin;
my $hour12_re = qr{ $hour12_dig_re | $hour12_word_re }xin;
my $hour24_re = qr{ $hour24_dig_re | $hour24_word_re }xin;

# The am / pm permutations
my $ampm_re = qr{ [ap]m \b | [ap][.] \s* m[.]? | pee \s+ em }xin;

# Oclocks
my $oclock_re = qr{ o( ['‘’´] \s* | f \s+ the \s+ )?clock s? }xin;

# Boundary before and after
my $bb_re = qr{ (?<= [\[—\s"'(‘’“”] ) | \A }xin;
my $ba_re = qr{ \b | (?= [—/"'‘’“”\s.…,:;?] ) | \z }xin;

# Match stuff from the start of the string to here.
# This must have an anchor for the start before it, specifically \G
# and it must be matched and included in the results
# i.e.:  \G ( $not_in_match )
my $not_in_match    = qr{ [—…,:;?/""''‘’“”\s([] | \G [-.]? | [^\d\w] [-.] }xin;

# Relative words
my $at_words     = qr{ until | at | before }xin;
my $rel_words    = qr{ ( shortly | just | well | long | a \s+ little ) \s+ ( before | after )
                     | ( ( just ) \s+ )? about
                     | after
                     | almost
                     | approximately
                     | around
                     | nearly
                     | near ( \s+ on )?
                     | past
                     | towards
                     }xin;
my $rel_at_words = qr{ $at_words | $rel_words }xin;

# Weekdays
my $weekday_re = qr{ monday | tuesday | wendesday | thursday | friday | saturday | sunday }xin;

# Times of day
my $timeday_re = qr{ day | morning | night }xin;

# Bible books
my $bible_book_re = qr{ Acts | Amos | Baruch | [12] \s+ Chronicles | Colossians
                      | [12] \s+ Corinthians | Daniel | Deuteroronomy | Ecclesiastes
                      | Ephesians | Esther | Exodus | Ezekiel | Ezra | Galatians
                      | Genesis | Habakkuk | Haggai | Hebrews | Hosea | Isaiah
                      | James | Jeremiah | Job | Joel | John | [123] \s+ John
                      | Jonah | Joshua | Jude | Judges | Judith | [12] \s+ Kings
                      | Lamentations | Leviticus | Luke | [12] \s+ Maccabees
                      | Malachi | Mark | Matthew | Micah | Nahum | Numbers | Obadiah
                      | [12] \s+ Peter | Philemon | Philippians | Proverbs | Psalms
                      | Revelation | Romans | Ruth | [12] \s+ Samuel | Sirach
                      | Solomon | [12] \s+ Thessalonians | [12] \s+ Timothy
                      | Titus | Tobit | Wisdom | Zechariah | Zephaniah
                      }xin;

# The months
my $month_re = qr{ January | February | March | April | May | June
                 | July | August | September | October | November | December }xin;
my $special_day_re = qr{ Christmas | Easter | New \s+ Year s? }xin;

# Time periods
my $time_periods_re = qr{ ( year | week | day | hour | half | minute | second ) s? }xin;

# Things that never follow times
my $never_follow_times_re =
    qr{ with | that | which | point | time | stage | of | who
      | after | since
      | degrees
      | centimeters | cm | meters | kilometers | km
      | inches | feet | ft | yards | yd | miles | mi
      | cubic | square
      | hundred | thousand | million | billion
      | ( \w+ \s+)? $time_periods_re
      | thirds | halves | quarters
      | dollars | cents | pounds | shillings | pennies | yuan
      | kids | children | men | women | girls | boys | families | people
      | rounds | turns | lines
      | books  | volumes | plates | illustrations
      }xin;

    # Set the branch state variable
my $branch = "x";


sub do_match {
    my ($line) = @_;

    #$line =~ s{ ( $not_in_match*? ) ((just)?) }{[$1]>$2<}gxi;
    #return $line;

    ## Shortcircuit if it just has a number in the line
    # e.g "Twenty-one" since these are probably chapters
    if ($line =~ m{ \A [\n\s]* $min_word_re ( [-\s]+ $low_num_re )? [\n\s]* \z }xin) {
        return $line;
    }

    ## Does this look like a "timey" paragraph
    my $is_timey = 0;
    $is_timey = 1
        if $line =~
            m{ \b (struck   |
                   hour     |
                   minute   |
                   clock    |
                   watch    |
                   $midnight_noon_re |
                   train \s+ time s? |
                   time \s+ are \s+ you \s+ meeting |
                   ( return | returned | back ) \s* $rel_at_words |
                   reported
                   ) \b
             }xin;

    ## Mask out some patterns and apply them first
    my ($masks) = get_masks();

    ## Get the matches and apply them
    my ($r) = get_matches();

    my @parts = $line;
    foreach my $r (@$masks, @$r) {
        my @new;
        foreach my $part (@parts) {
            if ($part !~ m{<<}) {
                while ($part ne '') {
                    if ($part =~ m{$r}p) {
                        my $match =
                            sprintf("%s<<%s%s|%s>>%s",
                                    map { defined ? $_ : "" }
                                    $+{pr}, $+{t1}, $+{t2}, $branch, $+{po});
                        my ($leadin, $leadout) = map { defined ? $_ : "" } ($+{li}, $+{lo});

                        push @new, ${^PREMATCH} . $leadin, $match;
                        $part = $leadout . ${^POSTMATCH};
                    }
                    else {
                        push @new, $part;
                        $part = '';
                    }
                }
            }
            else {
                push @new, $part;
            }
        }
        @parts = @new;
    }
    $line = join '', @parts;

    ## Fixups
    # Change TIMEY to $is_timey's value
    $line =~ s{<< ([^|>]+) [|] (\d+ \w?) :TIMEY >>}{<<$1|$2:$is_timey>>}xg;

    # Get absolute words out
    $line =~ s{<< ( ( at | by ) \s )}{$1<<}xgi;

    # Undo the masks
    $line =~ s{<< ( [^>]+ ) \|xx >>}{$1}xgi;

    return $line;
}

sub get_masks {
    state @r;
    return(\@r)
        if @r;

    # Take out compound numbers, dates never look like:
    # 12,000
    # 14.000
    push @r,qr{ $bb_re
                (?<t1> ( \d{1,3} ( [,] \d{3} )+
                       | \d{1,3} ( [.] \d{3} )+
                       )
                )
                $ba_re
                (?{ $branch = "xx"; })
              }xin;

    # odds of five to one
    push @r,qr{ (?<pr> \s+ odds \s+ of \s+ )
                (?<t1> $min_re \s+ to \s+ $min_re )
                \b
                (?{ $branch = "xx"; })
              }xin;

    # one's
    push @r,qr{ (?<t1> \b one ['‘’] s \b )
                (?{ $branch = "xx"; })
              }xin;

    # I was one of twenty
    push @r,qr{ (?<pr> \s+ )
                (?<t1> one \s+ of \s+ $min_re )
                \b
                (?{ $branch = "xx"; })
              }xin;

    # Bible quotes
    push @r,qr{ (?<pr> $bible_book_re \s+ )
                (?<t1>
                     \d+ : \d+ ( - \d+ | - \d+ : \d+ )?
                | \( \d+ : \d+ ( - \d+ | - \d+ : \d+ )? \)
                | \[ \d+ : \d+ ( - \d+ | - \d+ : \d+ )? \]
                )
                (?{ $branch = "xx"; })
              }xin;

    # age of twenty-four, aged twenty-four
    push @r,qr{ (?<pr> \s+ ( age \s+ of | aged )\s+ )
                (?<t1>
                  $min_word_re ( [-\s]+ $low_num_re )?
                  ( \s+ ( or | to ) \s
                   $min_word_re ( [-\s]+ $low_num_re )?
                  )?
                )
                \b
                (?{ $branch = "xx"; })
              }xin;

    # months or special days followed by years
    push @r,qr{ (?<pr> ( $month_re | $special_day_re )[,]? \s+ )
                (?<t1> \d{4} )
                (?! ,? \s* $ampm_re)
                \b
                (?{ $branch = "xx"; })
              }xin;

    # AD or BC or BCE
    my $bcad_re = qr{ BC | BCE | B\.C\. | AD | A\.D\. }xin;
    push @r,qr{ (?<t1>
                  ( \b $bcad_re \s* \d+
                  | \b \d+ \s* $bcad_re
                  )
                )
                $ba_re
                (?{ $branch = "xx"; })
              }xin;

    # Addresses
    push @r,qr{ (?<t1>
                  \b \d+ \s* ( \w | \# \d+ )? \s+
                  ( \w+ \s+ )?
                  ( road | rd
                  | street | st
                  | avenue | ave
                  | crescent
                  | boulevard | blvd | bvd
                  )
                )
                $ba_re
                (?{ $branch = "xx"; })
              }xin;

    return(\@r);
}

sub get_matches {
    state @r;
    return(\@r)
        if @r;

    # Capture names:
    # li - Lead-in: Stuff before the match that we don't mask out
    # pr - Preamble: Stuff that is part of the match phrase but not the time
    # t1 - Time 1: The time phrase
    # t2 - Time 2: More of the time phrase (if needed)
    # po - Postamble: Part of the match phrase but not the time
    # lo - Lead-out: Stuff after the match that we don't mask out


    # Ones with a phrase after to fix it better as a time
    push @r,qr{ \b (?<pr> ( at | it \s+ was | twas | till ) \s+ )
                   (?<t1> ( ( $rel_words | ( close \s+ )? upon ) \s+ )?
                     $hour_word_re
                   )
                   (?<po> ( \s+ ( at | in ) \s+ the
                      |  \s+ the  \s+ ( next | following ) \s+ $timeday_re
                      |  \s+ for  \s+ ( breakfast | lunch | dinner | luncheon | tea )
                      |  \s+ on   \s+ ( the \s+ )? $weekday_re
                      |  \s+ that \s+ $timeday_re
                      |  \s+ ( tonight | today | tomorrow )
                     )
                   ) $ba_re
                   (?{ $branch = "9a"; })
              }xin;

    # Times to/from hour
    # ten minutes past noon
    # three minutes till eight
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                    ( ( $rel_words \s+
                      | between \s+ $min_word_re \s+ and \s+
                      | $min_word_re \s+ or \s+
                      )?
                      ( $min_word_re | \d{1,2} | a | a \s+ few ) ( \s+ | [-] )
                      ( minute s? \s+ )?
                      ( and ( \s+ | [-] )
                              ( a \s+ half | 1/2 | a \s+ quarter | 1/4 | twenty
                                | $sec_re \s+ second s? )? \s+
                       | ( after | before ) \s+ ( the \s+ )? $fraction_re ( \s+ | [-] )
                      )?
                      ( minute s? \s+ )?
                    | ( $rel_words \s+ ( a \s+ )? )? $fraction_re ( \s+ | [-] )
                    | ( just | nearly ) \s+
                  )
                  $till_re [-—\s]+
                  $hour24_re ( \s+ $oclock_re )? ( ,? \s* $ampm_re )?
                  (?! \s+ ( possibilities | $time_periods_re )
                   | :\d | [-] )
                )
                $ba_re
                (?{ $branch = "10"})
              }xin;
    # Do we need to skip nine-to-five?

    # Ones with a phrase before to fix it better as a time
    push @r,qr{ \b (?<pr> ( meet  | meeting  | meets
                      |  start | starting | starts
                     ) \s+
                     ( ( tonight | today | tomorrow | $weekday_re | this ) \s+
                      ( ( morning | afternoon | evening ) \s+ )?
                     )?
                     at \s+
                   )
                   (?<t1> ( $rel_words \s+ )?
                     $hour24_re ( [-.:\s]* $min0_re )?
                     (?! \s+ $never_follow_times_re \b )
                     ( ,? \s* $ampm_re )?
                   )
                   $ba_re
                (?{ $branch = "9g"})
              }xin;

    # after eleven the next day
    push @r,qr{ \b (?<t1> ( $rel_words | ( close \s+ )? upon ) \s+
                     ( \w+ \s+ )?
                     $hour_word_re
                   )
                   (?<po>
                         ( \s+ ( at | in ) \s+ the
                      |  ,? \s* $ampm_re
                      |  \s+ the  \s+ ( next | following ) \s+ $timeday_re
                      |  \s+ for  \s+ ( breakfast | lunch | dinner | luncheon | tea )
                      |  \s+ on   \s+ ( the \s+ )? $weekday_re
                      |  \s+ that \s+ $timeday_re
                      |  \s+ ( tonight | today | tomorrow )
                     )
                   )
                   $ba_re
                 (?{ $branch = "9h"})
              }xin;

    # ... meet me ... at ten forty-five.
    push @r,qr{ $bb_re
                (?<pr> meet \s+ me \b [^.!?]* \s+ at \s+ )
                (?<t1> $hour24_re [-\s.]+ $min_word_re ( ,? \s* $ampm_re )? )
                $ba_re
                (?{ $branch = "5c"})
              }xin;
    # here at seven thirty, be at six forty-five
    push @r,qr{ $bb_re
                (?<pr> ( here | be ) \s+ at \s+ )
                (?<t1> $hour24_re [-\s.]+ $min_word_re ( ,? \s* $ampm_re )?)
                $ba_re
                (?{ $branch = "5e"})
              }xin;

    # Due ... at eleven-fifty-one
    # Knocks ... at 2336
    push @r,qr{ $bb_re
                (?<pr> ( due | knocks ) \s+ [\w\s]* at \s+ )
                (?<t1> $hour24_re [-\s.:]* $min_re ( ,? \s* $ampm_re )?)
                $ba_re
                (?{ $branch = "5d"})
              }xin;

    # on the 1237
    push @r,qr{ (?<li> $not_in_match )
                (?<pr> ( on \s+ the
                       |  here \s+ at
                       ) \s+
                )
                (?<t1> ( $hour12_dig_re [.]? | $hour24_dig_re [.] )
                       $minsec0_dig_re
                )
                $ba_re
                (?{ $branch = "3c"})
              }xin;

    # 13 hours and 6 minutes
    # 13 hours, 6 minutes, and 10 seconds
    push @r,qr{ $bb_re
                (?<t1>
                        $hour24_re \s+ ( hour | $oclock_re | h | hr ) s? ,? ( \s+ and )?
                    \s+ $min_re    \s+ ( minute | min | m )           s?
                    ( ,? \s* $ampm_re )?
                )
                (?<po>
                  ,? ( \s+ and )?
                  ( \s+ $sec_re    \s+ ( seconds | sec | s)           s?
                   | ( \s+ a )? \s+ $fraction_re
                  )?
                  (?! [-\s]+ $never_follow_times_re \b )
                )
                $ba_re
                (?{ $branch = "14"})
               }xin;

    # O'Clocks
    # 1 o'clock, 1 oclock, 1 of the clock
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                 ( $rel_words \s+ )?
                  $hour24_re [?]? ( [-.:] $min_re )?
                  [-\s]+ $oclock_re
                  ( ,? \s* $ampm_re )?
                )
                $ba_re
                (?{ $branch = "6"})
              }xin;

    # Times at the end of a phrase
    # These are guaranteed times:
    #   waited until eight, ...
    push @r,qr{ $bb_re
                (?<pr>
                  ( waited | arrive s? | called | expired
                  | it \s+ ( is | was ) | twas | it['‘’]s | begin | end ) \s+
                    ( ( exactly | precisely ) \s+ )?
                  ( ( at | upon | till | until ) \s+ )?
                )
                (?<t1> ( $rel_words \s+ )?
                  $hour12_re ( ( [-:.] | \s+ )? $min0_re )?
                )
                (?<po>
                  [.…;:?!""''‘’,“”] ( \s | \z )
                | \s+ ( and | [-—] ) \s+
                )
                (?{ $branch = "9f"})
              }xin;

    # Simple times
    # 2300h, 23.00h, 2300 hrs
    push @r,qr{ $bb_re
                (?<t1> ( $rel_words \s+ )?
                  $hour_dig_re [.:]? $minsec_dig_re
                  ( h | \s* ( hrs | hours ) )
                )
                $ba_re
                (?{ $branch = "1"})
              }xin;
    # 2300 GMT, 2300z
    push @r,qr{ $bb_re
                (?<t1> ( $rel_words \s+ )?
                  $hour_dig_re [.:]? $minsec0_dig_re
                )
                (?<po> ( [.:]? $minsec_dig_re ( - $minsec_dig_re )? )?
                  ( ( h | \s* ( hrs | hours ) )
                   | z
                   | \s* ( gmt | zulu )
                  )
                )
                $ba_re
                (?{ $branch = "1a"})
              }xin;
    # 11h20
    push @r,qr{ $bb_re
                (?<t1>
                 ( $rel_words \s+ )?
                  $hour_dig_re h $minsec0_dig_re m?
                )
                $ba_re
                (?{ $branch = "1b"})
              }xin;

    # Separators are mandatory, and it needs am/pm
    # 5.06 a.m.
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                  ( $rel_words \s+ )?
                  $hour12_dig_re [.:] $minsec_dig_re
                )
                ( (?<t2> ,? \s* $ampm_re )
                | (?<po> ( [.:] $minsec_dig_re )? ,? \s* $ampm_re )
                )
                (?{ $branch = "2a"})
              }xin;

    # : Means it's a time
    # 12:37
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                 ( $rel_words \s+ )?
                 $hour_dig_re : $minsec_dig_re
                )
                ( (?<t2> ,? \s* $ampm_re )
                | (?<po> ( : $minsec_dig_re )? ,? \s* $ampm_re )
                )?
                $ba_re
                (?{ $branch = "2"})
              }xin;

    # one hour and a quarter
    push @r,qr{ $bb_re
                (?<t1> $hour24_re \s+ hour s? ,? \s+ and \s+
                  a \s+ $fraction_re
                )
                $ba_re
                (?{ $branch = "14a:TIMEY"})
               }xin;

    # Word times (other word times come later)
    # eleven fifty-six am
    push @r,qr{ (?<li> $not_in_match )
                (?<t1> ( $rel_words \s+ )?
                  $hour_re
                  ( [-\s.]+ $min_word_re )?
                  ( [-\s.]+ $sec_word_re )?
                  ,? \s* $ampm_re
                )
                $ba_re
                (?{ $branch = "5"})
              }xin;

    # PMs
    # 1 pm, one p.m.
    push @r,qr{ (?<li> $not_in_match )
                (?<t1> $hour_re [?]? ,? \s* $ampm_re )
                $ba_re
                (?{ $branch = "7"})
              }xin;

    # three in the morning
    push @r,qr{ $bb_re
                (?<t1> ( $rel_words \s+ )?
                  $hour_re [?]? ( [-\s.]+ $min_re)? )
                (?<po> \s+ in \s+ the \s+
                  ( morn | morning | afternoon | evening )
                )
                $ba_re
                (?{ $branch = "8"})
              }xin;

    # at 1237 when
    # by 8.45 on saturday
    push @r,qr{ (?<li> $not_in_match )
                (?<pr> ( at | it \s+ is | it \s+ was | twas | by | by \s+ the ) \s+ )
                (?<t1> $hour_re [?]? [-.\s]? $min_re )
                (?<po>
                 \s+ ( ( ( on | in ) \s+ )? $weekday_re
                       | when
                       | today | tonight
                       | ( this | that | one | on \s+ the ) \s+
                         ( morning | morn | afternoon | evening | night )
                       )
                )
                $ba_re
                (?{ $branch = "3b"})
              }xin;
    # Three in the morning
    push @r,qr{ (?<li> $not_in_match )
                (?<pr> ( at | it \s+ is | it \s+ was | twas | by | by \s+ the ) \s+ )
                (?<t1> $hour_re [?]? [-.\s]? $min_re
                  \s+ in
                  \s+ ( the \s+ ( morn | morning | afternoon | evening ) )
                )
                $ba_re
                (?{ $branch = "3d"})
              }xin;

    # Four, ...
    push @r,qr{ (?<pr> \A | ['"‘’“”] | [.…;:?!] \s+ )
                (?<t1> $hour_word_re )
                (?<po> [,] \s+ )
                (?{ $branch = "9i:TIMEY" })
              }xin;

    # The only time in a sentence
    push @r,qr{ (?<pr>
                  ( \A | ['"‘’“”] | [.…;:?!] \s+ | \s+ [-—]+ \s+ )
                  ( ( only | just | it['‘’]s | it \s+ is | the ) \s+ )?
                )
                (?<t1>
                  ( $rel_words \s+ )?
                  ( $hour_dig_re [.:] $minsec_dig_re ( [.:] $minsec_dig_re )?
                   | $hour24_word_re ( \s+ | [-] ) $min_word_re ( ,? \s* $ampm_re )?
                  )
                )
                (?<po>
                  ( [-] $minsec_dig_re )?
                  ( \s+ ( now | precisely | exactly ) )?
                  ( \z | [.…;:?!,]? ['"‘’“”] | [.…;:?!] \s+ | \s+ [-—]+ \s+) )
                (?{ $branch = "9j"})
              }xin;
    # The only time, but as digits with no separators... but often comes up as years
    push @r,qr{ (?<pr>
                  ( \A | ['"‘’“”] | [.…;:?!] \s+ | \s+ [-—]+ \s+ )
                  ( ( only | just | it['‘’]s | it \s+ is | the ) \s+ )?
                )
                (?<t1>
                  ( $rel_words \s+ )?
                  ( $hour_dig_re $minsec0_dig_re ( $minsec0_dig_re )? )
                )
                (?<po>
                  ( [-] $minsec_dig_re )?
                  ( \s+ ( now | precisely | exactly ) )?
                  ( \z | [.…;:?!,]? ['"‘’“”] | [.…;:?!] ( \s+ | \z ) | \s+ [-—]+ \s+) )
                (?{ $branch = "9l:TIMEY"})
              }xin;

    # Times at the start of a sentence
    # At ten, ...
    push @r,qr{ (?<pr>
                  ( \A | ['"‘’“”] | [.…;:?!,] \s+ )
                  ( ( it \s+ was | twas | which \s+ was | and ) \s+ )?
                )
                (?<t1>
                  ( $rel_at_words | ( close \s+ )? upon | till | by ) \s+
                  $hour24_re ( [.\s]+ $min0_re )?
                  (?= \s+ ( last | yesterday | $weekday_re ) | \s* [-—,] \s+ )
                )
                $ba_re
                (?{ $branch = "9e"})
              }xin;
    push @r,qr{ (?<pr>
                  ( \A | ['"‘’“”] | [.…;:?!] \s+ )
                  ( it \s+ was | twas | it \s+ is ) \s+
                )
                (?<t1>
                  $hour_re ( [-:.] | \s+ )? $min0_re
                | $low_num_re \s* (*SKIP)(*FAIL)
                | $hour_re
                )
                ( [-\s]+ $never_follow_times_re \b (*SKIP)(*FAIL) )?
                $ba_re
                (?{ $branch = "9d"})
              }xin;
    push @r,qr{ (?<pr>
                  ( \A | ['"‘’“”] | [.…;:?!] \s+ )
                  ( at ) \s+
                )
                (?<t1> $hour_re ( ( [-:.] | \s+ )? $min0_re )? )
                ( [-\s]+ $never_follow_times_re \b (*SKIP)(*FAIL) )?
                $ba_re
                (?{ $branch = "9m"})
              }xin;

    # Strong word times
    # at eleven fifty-seven
    push @r,qr{ (?<li> $not_in_match )
                (?<pr>
                  ( at | ( it | time ) \s+ ( is | was | will \s+ be ) | by
                  | ['‘’] ( twill \s+ be | twas )
                  ) \s+
                )
                (?<t1>
                  $hour24_word_re ( [\s\.]+ | [-] ) $min_word_re
                  ( \s* ... \s* $low_num_re )? ( ,? \s* $ampm_re )?
                )
                ( [-\s]* $never_follow_times_re \b (*SKIP)(*FAIL) )?
                $ba_re
                (?{ $branch = "5b"})
              }xin;

    # Other weird cases
    # here at nine ...
    push @r,qr{ (?<pr> \b
                  ( here | there
                   | today | tonight | night
                   | gets \s+ up | woke | rose | waking
                   | happened \s+ at
                   | news ) \s+
                )
                (?<t1> $rel_at_words \s+
                  $hour_word_re
                )
                (?! \s+ $time_periods_re )
                $ba_re
                (?{ $branch = "9b"})
               }xin;

    # at a four-thirty screening
    push @r,qr{ (?<li> $not_in_match )
                (?<pr> ( at \s+ a ) \s+ )
                (?<t1> $hour24_word_re ( \s+ | [-.] ) $min_word_re ( ,? \s* $ampm_re )? )
                (?<po> \s+ ( screening | viewing | performance | departure | arrival
                       | game | play | movie | flight | train | ship )
                )
                $ba_re
                (?{ $branch = "5f"})
              }xin;

    # Struck / strikes
    push @r,qr{ \b
                (?<t1>
                  $min_re \s+ minutes \s+ ( before | after ) \s+ the \s+
                  ( clock | bell | watch | it | now | hands ) s? \s+
                  ( struck | strikes | striking | strike | striketh
                  | beat    | beats   | beating
                  | said    | says    | showed | shows
                  | read    | reads   | reading
                  | ( point | pointed | pointing ) \s+ to
                  ) \s+
                  $hour24_re ( [-.\s]+ $min0_re )?
                )
                $ba_re
                (?{ $branch = "11a"})
              }xin;
    push @r,qr{ \b
                (?<pr>
                  ( clock | bell | watch | it | now | hands ) s? \s+ [\w\s]*?
                  ( struck | strikes | striking | strike | striketh
                  | beat    | beats   | beating
                  | said    | says    | showed | shows
                  | read    | reads   | reading
                  | drew
                  | ( point | pointed | pointing ) \s+ to
                  ) \s+
                )
                (?<t1>
                  ( ( a | $min_re ) \s+ minute s? \s+
                    ( before | after | short \s+ of | near \s+ to ) \s+
                  | near \s+ to \s+
                  )?
                  $hour24_re ( [-.\s]+ $min0_re )?
                )
                (?! \s+ ( faces | another ) )
                $ba_re
                (?{ $branch = "11"})
              }xin;
    push @r,qr{ \b
                (?<pr> stroke \s+ of \s+ )
                (?<t1> $hour24_re ( [-.\s]+ $min0_re )? )
                $ba_re
                (?{ $branch = "12"})
              }xin;

    # Noon / midnight
    push @r,qr{ (?<li> $not_in_match )
                (?<t1> ( $rel_words \s+ )?
                  $midnight_noon_re
                )
                $ba_re
                (?{ $branch = "13"})
              }xin;

    push @r,qr{ (?<pr>
                  ( \A | ['"‘’“”] | [.…;:?!,] \s+ )
                  ( ( it \s+ was | twas | because ) \s+)?
                )
                (?<t1>
                  ( $rel_at_words | ( close \s+ )? upon | till | by ) \s+
                  ( $hour24_re ( [-:.] | \s+ )? $min0_re
                  | One \s* (*SKIP)(*FAIL)
                  | $hour24_re
                  )
                )
                ( [-\s]* $never_follow_times_re \b (*SKIP)(*FAIL) )?
                $ba_re
                (?{ $branch = "9:TIMEY"})
              }xin;

    # More at the end of a phrase
    # These are not always, so look for timey:
    #   ... through Acton at one.
    #   ... starts opening at eight and ...
    push @r,qr{ $bb_re
                (?<pr>
                  ( $at_words | upon | till | from
                   | ( it | time ) \s+ ( is | was | will \s+ be )
                   | ['‘’] ( twill \s+ be | twas )
                  ) \s+
                  ( only \s+ )?
                )
                (?<t1>
                  ( $rel_words \s+ )?
                  ( near \s+ ( on \s+ )? )?
                  $hour_re ( ( [-:.] | \s+ )? $min0_re )?
                )
                (?! [''‘’]s )
                (?<po>
                  ( \s+ or \s+ so )?
                  ( [""''‘’“”]
                   | [.…;:?!,] ( [""''‘’“”\s] | \z )
                   | \s+ ( and | till | before | [-—] ) \s+
                  )
                )
                (?{ $branch = "9c:TIMEY"})
              }xin;

    push @r,qr{ \b
                (?<pr> \b $hour24_re )
                (?<t1> \s+ strokes )
                $ba_re
                (?{ $branch = "15:TIMEY"})
              }xin;

    # The only time, but as a single hour (these are less reliable)
    push @r,qr{ (?<pr>
                  ( \A | ['"‘’“”] | [.…;:?!] \s+ | \s+ [-—]+ \s+ )
                  ( ( only | just | it['‘’]s | it \s+ is | the ) \s+ )?
                )
                (?<t1>
                  ( $rel_words \s+ )?
                  $hour24_word_re ( ( \s+ | [-] ) $min_word_re ( ,? \s* $ampm_re )? )?
                )
                (?<po>
                  ( [-] $minsec_dig_re )?
                  ( \s+ ( now | precisely | exactly ) )?
                  ( \z | [.…;:?!,]? ['"‘’“”] | [.…;:?!] \s+ | \s+ [-—]+ \s+) )
                (?{ $branch = "9k:TIMEY"})
              }xin;

    # Untrustworthy times... need an indication that it is a time, not just some number
    # at 1237, is 1237, was 1237, by 1237
    push @r,qr{ (?<li> $not_in_match )
                (?<pr>
                  ( at ( \s+ last )?
                  | it \s+ is | it \s+ was | twas | by
                  ) \s+
                )
                (?<t1>
                  ( $rel_words \s+ )?
                  ( $hour12_dig_re [.]? | $hour24_dig_re [.] )
                    $minsec0_dig_re
                  )
                (?! \s+ $never_follow_times_re \b )
                $ba_re
                (?{ $branch = "3:TIMEY"})
              }xin;

    # eleven fifty-six
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                  ( $rel_words \s+ )?
                  ( $hour24_word_re ( [-\s]+ | \s* ( \Q...\E | … ) \s* ) $min_word_re
                  | $hour_dig_re [-.] $minsec0_dig_re
                  )
                  ( ,? \s* $ampm_re )? )
                (?! \s+ $never_follow_times_re \b
                |  [-—]
                )
                $ba_re
                (?{ $branch = "5a:TIMEY"})
              }xin;

    # Hours by, at start of phrase
    # ; eleven by big ben ...
    push @r,qr{ (?<pr> ( \A | ['"‘’“”] | [.…;:?!,] \s+ ) )
                (?<t1> $hour24_re ( [.\s]+ $min0_re )? )
                (?<po>
                  \s+ ( by ) \s+
                  (?! one \b )
                )
                $ba_re
                (?{ $branch = "5g:TIMEY"})
              }xin;

    # Military times?
    #   Thirteen hundred hours; Zero five twenty-three; sixteen thirteen

    return(\@r);
}

sub extract_times {
    my ($string) = @_;

    my @times;
    while ($string =~ m{<< ([^|>]+) [|] \d+ \w? (:\d)? >>}gx) {
        my $str = $1;

        my $time;
        if ($str =~
            m{\A
              ( # Exact time
                ( (?<rl> $rel_words ) \s+ )?
                  (?<hr> $hour24_re ) [-\s.:]*
                ( (?<mn> $min_re    ) \s* )?
                ( (?<am> $ampm_re   ) )?
              | # Bare hour
                ( (?<rl> $rel_words ) \s+
                  ( ( at | to ) \s+ )?
                | close \s+ upon \s+
                )?
                  (?<hr> $hour_re )
              | # 0000h
                ( (?<rl> $rel_words ) \s+ )?
                  (?<hr> $hour_dig_re    ) [-\s.:]*
                ( (?<mn> $minsec0_dig_re ) \s* )?
                ( h | hrs | hours )
              | # 11h20m, 11h20, 3 hr 8 m p.m.
                ( (?<rl> $rel_words ) \s+ )?
                  (?<hr> $hour_dig_re   ) \s* ( h | hr    | hours? )  \s*
                ( \s+ and \s+ | , \s+ )?
                  (?<mn> $minsec_dig_re ) \s* ( m | mins? | minutes?  )?
                ( ,? \s+ (?<am> $ampm_re ) )?
              | # twenty minutes past eight
                ( (?<rl> $rel_words ) \s+
                | (?<rl> ( $rel_words \s+ )? $min_re \s+ or ) \s+
                )?
                  (?<mn> $min_re | a | a \s+ few | just ) [-\s]+
                ( and ( \s+ | [-] )
                  ( a \s+ half | 1/2 | a \s+ quarter | 1/4 | twenty ) \s+
                )?
                  ( minutes? \s+ )?
                ( and ( \s+ | [-] ) $sec_re \s+ seconds? \s+ )?
                  (?<dir> $till_re ) \s+
                  (?<hr> $hour_re )
                ( [-\s]+ (?<m2> $min_re ) )?
                ( \s+ $oclock_re )?
                ( ,? \s* (?<am> $ampm_re ) )?
              | # seven-and-twenty minutes past eight
                ( (?<rl> $rel_words | between ) \s+ )?
                  (?<mn> $min_re [-\s+] and [-\s+] $min_re ) \s+
                  ( and ( \s+ | [-] )
                    ( a \s+ half | 1/2 | a \s+ quarter | 1/4 | twenty
                    | $sec_re \s+ second s?
                    ) \s+
                  )?
                  ( minutes? \s+ )?
                  (?<dir> $till_re ) \s+
                  (?<hr> $hour_re )
                ( \s+ $oclock_re )?
                ( ,? \s* (?<am> $ampm_re ) )?
              | # three quarters past eleven
                ( ( (?<m2> $min_re ) \s+ minutes? \s+ )?
                  (?<rl> $rel_words ) \s+ ( a \s+ )?
                  ( the \s+ )?
                )?
                  (?<mn> $fraction_re ) [-\s]+
                  (?<dir> $till_re ) \s+
                  (?<hr> $hour_re )
                ( \s+ $oclock_re )?
                ( ,? \s+ (?<am> $ampm_re ) )?
              | # three o'clock
                ( (?<rl> $rel_words ) \s+ )?
                  (?<hr> $hour_re ) \??
                  [-\s]+ $oclock_re
                ( ,? \s+ (?<am> $ampm_re ) )?
                ( \s+ ( and \s+ )?
                  (?<mn> $min_re | $fraction_re ) \s*
                  minutes?
                )?
              | # One hour and a quarter
                ( (?<rl> $rel_words ) \s+ )?
                  (?<hr> $hour_re ) \s+ hours? \s+ and \s+ a \s+
                  (?<mn> $fraction_re )
                ( ,? \s+ (?<am> $ampm_re ) )?
              | # one ... thirty ... four
                ( (?<rl> $rel_words ) \s+ )?
                  (?<hr> $hour24_word_re ) ( [\s\.]+ | [-] )
                  (?<mn> $min_word_re )
                ( \s* ... \s* (?<m2> $low_num_re ) )?
                ( \s+ $oclock_re )?
                ( ,? \s+ (?<am> $ampm_re ) )?
              | # Two minutes before the clock struck noon
                  (?<mn> $min_word_re ) \s+ minutes? \s+
                  (?<dir> $till_re ) \s+
                ( the \s+ clock \s+ struck \s+ )?
                  (?<hr> $hour24_re )
                ( \s+ $oclock_re )?
                ( ,? \s+ (?<am> $ampm_re ) )?
              )
              \z}xin)
        {
            $time =
                join(" ",
                     map { defined ? $_ : () }
                     $+{rl}, $+{hr}, $+{mn}, $+{m2}, $+{am}, $+{dir});
        }

        push @times, $time
            if defined $time;
    }

    return @times;
}
