package TimeMatch;

use Modern::Perl '2017';

use utf8;

use Exporter::Easy (
  EXPORT => [ qw( do_match extract_times ) ],
);

use Carp;
use Data::Dumper;
use Lingua::EN::Words2Nums;


# Special named times
my $noon_re     = qr{ ( high \s+ )? noon | noonday | mid[-\s]*day | noontime | noontide }xin;
my $midnight_re = qr{ midnight (?! \s+ oil ) }xin;
my $ecclesiastical_re =
    qr{ # Ecclesiastical times -- https://en.wikipedia.org/wiki/Liturgy_of_the_Hours
        matins | lauds | terce | sext | vespers | compline | vigils | nocturns
      | night \s+ office
      | ( dawn | early \s+ morning | mid-morning | mid-?day | mid-afternoon | evening | night )
        \s+ prayer
      # Missing Prime and None
      }xin;
my $midnight_noon_re = qr{ $noon_re | $midnight_re | $ecclesiastical_re }xin;

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

my $before_re = qr{ before | to | of | till | ['‘’]til | short \s+ of }xin;
my $after_re  = qr{ after | past }xin;
my $till_re   = qr{ $before_re | $after_re }xin;

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
my $far_re          = qr{ well    | long                }xin;
my $short_re        = qr{ shortly | just | a \s+ little }xin;

my $far_before_re   = qr{   $far_re   \s+    before     }xin;
my $short_before_re = qr{   $short_re \s+    before
                        |   nearly
                        |   near ( \s+ on )?
                        |   towards
                        }xin;
my $around_re       = qr{ ( ( just )  \s+ )? about
                        | almost
                        | approximately
                        | around
                        }xin;
my $short_after_re  = qr{ ( $short_re \s+ )? after
                        | past
                        }xin;
my $far_after_re    = qr{   $far_re   \s+    after      }xin;

my $rel_words       = qr{ $far_before_re | $short_before_re
                        | $around_re
                        | $far_after_re  | $short_after_re
                        }xin;

my $at_words     = qr{ until | at | before }xin;
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

    # Ones with a phrase after to fix it better as a time
    push @r,qr{ \b (?<pr> ( at | it \s+ was | twas | till ) \s+ )
                   (?<t1> ( ( $rel_words ( \s+ at )? | ( close \s+ )? upon ) \s+ )?
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
    my ($string, $permute) = @_;

    my @times;
    while ($string =~ m{<< ([^|>]+) [|] \d+ \w? (:\d)? >>}gx) {
        my $str = $1;

        my $branch;
        if ($str =~
            m{\A
              ( # Exact time
                ( (?<rl> $rel_at_words ) \s+ )?
                  (?<hr> $hour24_re ) [-\s.:]*
                ( (?<mn> $min_re    ) \s* )?
                ( (?<am> $ampm_re   ) )?
                (?{ $branch = "1"})
              | # Bare hour
                ( (?<rl> $rel_at_words ) \s+
                  ( ( at | to ) \s+ )?
                | (?<rl> close \s+ upon ) \s+
                )?
                  (?<hr> $hour_re )
                (?{ $branch = "2"})
              | # 0000h
                ( (?<rl> $rel_at_words ) \s+ )?
                  (?<hr> $hour_dig_re    ) [-\s.:]*
                ( (?<mn> $minsec0_dig_re ) \s* )?
                ( h | hrs | hours )
                (?{ $branch = "3"})
              | # 11h20m, 11h20, 3 hr 8 m p.m.
                ( (?<rl> $rel_at_words ) \s+ )?
                  (?<hr> $hour_dig_re   ) \s* ( h | hr    | hours? )  \s*
                ( \s+ and \s+ | , \s+ )?
                  (?<mn> $minsec_dig_re ) \s* ( m | mins? | minutes?  )?
                ( ,? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "4"})
              | # twenty minutes past eight
                ( (?<rl> $rel_at_words | a \s+ few | just ) \s+
                | (?<rl> ( $rel_at_words \s+ )? $min_re \s+ or ) \s+
                )?
                ( (?<mn> $min_re | a ) [-\s]+ )?
                ( and ( \s+ | [-] )
                  ( a \s+ half | 1/2 | a \s+ quarter | 1/4 ) \s+
                )?
                  ( minutes? \s+ )?
                ( and ( \s+ | [-] ) (?<sec> $sec_re ) \s+ seconds? \s+ )?
                  (?<dir> $till_re ) \s+
                  (?<hr> $hour_re )
                ( [-\s]+ (?<m3> $min_re ) )?
                ( \s+ $oclock_re )?
                ( ,? \s* (?<am> $ampm_re ) )?
                (?{ $branch = "5"})
              | # seven-and-twenty minutes past eight
                ( (?<rl> $rel_at_words | between ) \s+ )?
                  (?<mn> $min_re [-\s+] and [-\s+] $min_re ) \s+
                  ( and ( \s+ | [-] )
                    (?<sec> a \s+ half | 1/2 | a \s+ quarter | 1/4 | twenty
                    | (?<sec> $sec_re ) \s+ second s?
                    ) \s+
                  )?
                  ( minutes? \s+ )?
                  (?<dir> $till_re ) \s+
                  (?<hr> $hour_re )
                ( \s+ $oclock_re )?
                ( ,? \s* (?<am> $ampm_re ) )?
                (?{ $branch = "6"})
              | # three quarters past eleven
                ( ( (?<m2> $min_re ) \s+ minutes? \s+ )?
                  (?<rl> $rel_at_words ) \s+ ( a \s+ )?
                  ( the \s+ )?
                )?
                  (?<mn> $fraction_re ) [-\s]+
                  (?<dir> $till_re ) \s+
                  (?<hr> $hour_re )
                ( \s+ $oclock_re )?
                ( ,? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "7"})
              | # three o'clock
                ( (?<rl> $rel_at_words ) \s+ )?
                  (?<hr> $hour_re ) \??
                  [-\s]+ $oclock_re
                ( ,? \s+ (?<am> $ampm_re ) )?
                ( \s+ ( and \s+ )?
                  (?<mn> $min_re | $fraction_re ) \s*
                  minutes?
                )?
                (?{ $branch = "8"})
              | # One hour and a quarter
                ( (?<rl> $rel_at_words ) \s+ )?
                  (?<hr> $hour_re ) \s+ hours? \s+ and \s+ a \s+
                  (?<mn> $fraction_re )
                ( ,? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "9"})
              | # one ... thirty ... four
                ( (?<rl> $rel_at_words ) \s+ )?
                  (?<hr> $hour24_word_re ) ( [\s\.]+ | [-] )
                  (?<mn> $min_word_re )
                ( \s* ... \s* (?<m3> $low_num_re ) )?
                ( \s+ $oclock_re )?
                ( ,? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "10"})
              | # Two minutes before the clock struck noon
                  (?<mn> $min_word_re ) \s+ minutes? \s+
                  (?<dir> $till_re ) \s+
                ( the \s+ clock \s+ struck \s+ )?
                  (?<hr> $hour24_re )
                ( \s+ $oclock_re )?
                ( ,? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "11"})
              )
              \z}xin)
        {
            # Save the captured values
            my @k = qw{ rl mn m2 m3 dir hr am sec branch };
            my %c; @c{@k} = @+{@k};
            $c{branch} = $branch;


            my $min  = $c{mn}  // 0;
            my $m2   = $c{m2}  // 0;
            my $m3   = $c{m3}  // 0;
            my $sec  = defined $c{sec} ? 1 : 0;
            my $hour = $c{hr}  // 0;
            my $rel  = $c{rl}  // '';
            my $ampm = $c{am};
            my $dir  = $c{dir} // '';

            # Turn the hours into numbers
            if ($hour !~ /^\d+$/) {
                $hour = 12 if $hour =~ $noon_re;
                $hour = 00 if $hour =~ $midnight_re;
                $hour = words2nums($hour) // $hour
                    // confess "Can't parse hour '$min'";
            }

            # Turn the minutes into numbers
            if ($min !~ /^\d+$/) {
                $min =~ s{ \A (.*) \s+ and \s+ .* \z }{$1}xi
                    if $rel eq 'between';
                $min = min2num($min);
            }
            if ($m2 !~ /^\d+$/) {
                $min += min2num($m2);
            }

            # If we got am or pm we can set the hour absolutely
            my $abs_hour = 0;
            if (defined $ampm and $ampm =~ /^p/i) {
                $abs_hour = 1;
                $hour += 12
                    if $hour != 12;

                # But 12:00 am/pm is ambiguous let it be both
                if ($hour == 12 and $min == 00) {
                    $hour = 0;
                    $abs_hour = 0;
                }
            }
            elsif ($hour > 12 or $hour == 0) {
                # Otherwise, depending on the hour, there can only be one choice
                $abs_hour = 1;
            }
            elsif ($hour == 12) {
                # 12:20 could be either am or pm, so set it low so we get both
                $hour = 0;
            }

            # Look at the direction and see if we need to subtract the minutes rather than add
            if ($dir =~ $before_re) {
                my $m = $min;
                $min = 60 - $m;
                $min -= 1 if $sec;
                $hour -= 1;
            }

            # Always add in the m3, it's never negative
            if ($m3 !~ /^\d+$/) {
                $min += min2num($m3);
            }

            # If the hour rolled, then we need to set it back
            $hour %= 24;

            my @hours = $hour;
            my @mins  = $min;
            if ($permute) {
                # Handle the 12 hour clock ambiguity
                push @hours, $hour+12
                    unless $abs_hour;

                # Handle relative times by spreading the range
                my ($low, $high) = get_spread($rel, $dir, $c{mn});
                @mins = ();
                for my $d ($low .. $high) {
                    push @mins, $min + $d;
                }
            }

            foreach my $h (@hours) {
                foreach my $m (@mins) {
                    my ($hour, $min) = fix_time($h, $m);
                    my $t = sprintf("%02d:%02d", $hour, $min);

                    my $time = "$t: " . join(" ",  map { defined $c{$_} ? "$_<$c{$_}>" : () } @k );

                    push @times, $time;
                }
            }
        }
    }

    return @times;
}

sub fix_time {
    my ($h, $m) = @_;

    if ($m < 0) {
        $h -= 1;
        $m += 60;
    }
    elsif ($m > 59) {
        $h += 1;
        $m -= 60;
    }

    $h %= 24;

    return ($h, $m);
}

sub min2num {
    my ($min) = @_;
    confess "Missing arg min"
        unless defined $min;

    # Fixed numbers
    return 1  if $min =~ m{\A ( a ) \z}xin;

    # Fractions
    return 15 if $min =~ m{\A ( quarter | 1/4 ) \z}xin;
    return 20 if $min =~ m{\A ( third   | 1/3 ) \z}xin;
    return 30 if $min =~ m{\A ( half    | 1/2 ) \z}xin;
    return 45 if $min =~ m{\A ( three [-\s]+ quarters
                              | third \s+ quarter
                              | 3/4
                              ) \z}xin;

    # Lose the leading oh-
    $min =~ s{\A ( oh [-\s]+ ) }{}xin;

    $min = words2nums($min)
        // confess "Can't parse minute '$min'";

    return $min;
}

sub get_spread {
    my ($rel, $dir, $min) = @_;

    if ($rel eq '' and defined $dir and $dir ne '' and not defined $min) {
        return (-9, -1)  if $dir =~ $before_re;
        return ( 1,  9)  if $dir =~ $after_re;
    }

    return (  0,  0)  if $rel eq '';
    return (-15, -5)  if $rel =~ m{\A $far_before_re   \s* \z}xin;
    return ( -9, -1)  if $rel =~ m{\A ( $short_before_re
                                      | close ( \s+ upon )?
                                      ) \s* \z}xin;
    return ( -6,  6)  if $rel =~ m{\A $around_re       \s* \z}xin;
    return (  1,  9)  if $rel =~ m{\A $short_after_re  \s* \z}xin;
    return (  5, 15)  if $rel =~ m{\A $far_after_re    \s* \z}xin;

    if (defined $dir and $dir ne '') {
        if ($rel =~ m{\A ( (?<m> $min_re ) \s+ or
                     | (?<r> a \s+ few | just )
                     )
                     \s* \z}xin)
        {
            my $rmin = defined $+{m} ? min2num($+{m}) : 5;
            if (defined $min and $min ne '') {
                # We already used the min to set the time, so take that away from the spread
                $rmin -= min2num($min);
            }

            if ($dir =~ $before_re) {
                return (-$rmin, 0);
            }
            return (0, $rmin);
        }
        elsif ($rel =~ m{\A between \s* \z}xin and
               $min =~ m{\A (?<a> $min_re) \s+ ( and | or ) \s+ (?<b> $min_re) \s* }xin)
        {
            my $a = min2num($+{a});
            my $b = min2num($+{b});

            # Since we've already consumed the first number as minutes, we need to adjust by that
            $b -= $a;
            $a  = 0;

            if ($dir =~ $before_re) {
                return (-$b, 0);
            }
            return (0, $b);
        }
    }
    else {
        return ( 0,  0)  if $rel =~ m{\A ( until | at ) \s* \z}xin;
        return (-5, -1)  if $rel =~ m{\A ( before ) \s* \z}xin;
    }

    confess "Can't parse rel '$rel'";
}

sub DEBUG_MSG {
    my @dump = @_;

    my ($package, $filename, $line) = caller;

    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Sortkeys = 1;
    print STDERR "Debug at $filename:$line:\n", Dumper(@dump);

    return;
}
