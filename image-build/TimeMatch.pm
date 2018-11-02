package TimeMatch;

use Modern::Perl '2017';

use utf8;

use Exporter::Easy (
  EXPORT => [ 'do_match' ],
);


# Numbers 1-9 as words
my $low_num_re = qr{ one | two | three | four | five | six | seven | eight | nine }xi;

# The hours 1-12 as words
my $hour12_word_re = qr{ $low_num_re | ten | eleven | twelve | noon | midnight }xi;
my $hour_word_re   = $hour12_word_re;

# The hours 13-24 as words
my $hour24_word_re = qr{ $hour_word_re | thirteen | fourteen | fifteen
                       | sixteen | seventeen | eighteen | nineteen
                       | twenty (?: - (?: one | two | three | four ) )?
                       }xi;

# The minutes
my $min_word_re =
    qr{ # 1-9
        (?: oh [\s-] | \b )? $low_num_re
        | # 10-19
        (?: ten | eleven | twelve | thirteen | fourteen | fifteen |
            sixteen | seventeen | eighteen | nineteen )
        | # 20-59
        (?: twenty | thirty | forty | fifty ) (?: (?: -| \s+ ) $low_num_re )?
      }xi;
my $sec_word_re = $min_word_re;

# Hour digits
my $hour_dig_re     = qr{ [01]?\d | 2[0-4] }xi;       # 00-24
my $hour12_dig_re   = qr{ [1-9] | 1[0-2] }xi;         # 1-12
my $hour24nz_dig_re = qr{ 0?[1-9] | 1\d | 2[0-4] }xi; # 01-24
my $hour24_dig_re   = $hour_dig_re;

# Min / sec digits
my $minsec_dig_re  = qr{ [0-5]?\d | 60 }xi;
my $minsec0_dig_re = qr{ [0-5]\d | 60 }xi;

# The minutes / seconds as words or numbers
my $min_re = qr{ $minsec_dig_re | $min_word_re }xi;
my $min0_re = qr{ $minsec0_dig_re | $min_word_re }xi;
my $sec_re = $min_re;

# The hours as words or numbers
my $hour_re   = qr{ $hour24_dig_re | $hour12_word_re }xi;
my $hour12_re = qr{ $hour12_dig_re | $hour12_word_re }xi;
my $hour24_re = qr{ $hour24_dig_re | $hour24_word_re }xi;

# The am / pm permutations
my $ampm_re = qr{ [ap]m \b | [ap][.] \s* m[.]? | pee \s+ em }xi;

# Oclocks
my $oclock_re = qr{ o(?: ['‘’´] \s* | f \s+ the \s+ )?clock s? }xi;

# Boundary before and after
my $bb_re = qr{ (?<= [\[\s"'(‘’“”] ) | \A }xi;
my $ba_re = qr{ \b | (?= [.,:;?/"'‘’“”\s] ) | \z }xi;

# Match stuff from the start of the string to here.
# This must have an anchor for the start before it, specifically \G
# and it must be matched and included in the results
# i.e.:  \G ( $not_in_match )
#my $not_in_match    = qr{ (?: [^<]*? (?: [-.,:;?/""''‘’“”\s([] ) | <[^<] | [^<]* << [^>]++ >> (*PRUNE) )*? }xi;
#my $not_in_match_sp = qr{ (?: [^<]*? (?: [""''‘’“”\s([]        ) | <[^<] | [^<]* << [^>]++ >> (*PRUNE) )*? }xi;
my $not_in_match    = qr{ (?: [-.,:;?/""''‘’“”\s([] | \G ) }xi;
my $not_in_match_sp = qr{ (?: [""''‘’“”\s([]        | \G ) }xi;

# Relative words
my $at_words     = qr{ until | at | before }xi;
my $rel_words    = qr{ after | almost | (?: just \s+ )? about
                     | around | nearly | approximately }xi;
my $rel_at_words = qr{ $at_words | $rel_words }xi;

# Weekdays
my $weekday_re = qr{ monday | tuesday | wendesday | thursday | friday | saturday | sunday }xi;

# Times of day
my $timeday_re = qr{(?: day | morning | night )}xi;

sub do_match {
    my ($line) = @_;

    #$line =~ s{ ( $not_in_match*? ) ((?:just)?) }{[$1]>$2<}gxi;
    #return $line;

    ## Does this look like a "timey" paragraph
    my $is_timey = 0;
    $is_timey = 1
        if $line =~
            m{ \b (?:
                   struck   |
                   hour     |
                   minute   |
                   clock    |
                   watch    |
                   noon     |
                   midnight |
                   train \s+ time s? |
                   time \s+ are \s+ you \s+ meeting |
                   (?: return | returned | back ) \s* $rel_at_words |
                   reported
                   ) \b
             }xi;

    ## Mask out some patterns
    $line =~ s{ ( \s+ odds \s+ of \s+ ) ( $min_word_re \s+ to \s+ $low_num_re ) \b }{$1<<$2|xx>>}xgi;


    ## Now do the matches, next number 16

    # Ones with a phrase after to fix it better as a time
    my $branch = "x";
    my @r = ();
    push @r,qr{ \b ( (?: at | it \s+ was | twas | till ) \s+ )
                   ( (?: (?: $rel_words | (?: close \s+ )? upon ) \s+ )?
                     (?: \w+ \s+ )?
                     $hour_word_re
                   )
                   ( (?: \s+ (?: at | in ) \s+ the
                      |  \s+ the  \s+ (?: next | following ) \s+ $timeday_re
                      |  \s+ for  \s+ (?: breakfast | lunch | dinner | luncheon | tea )
                      |  \s+ on   \s+ (?: the \s+ )? $weekday_re
                      |  \s+ that \s+ $timeday_re
                      |  \s+ (?: tonight | today | tomorrow )
                     )
                   ) $ba_re
                   (?{ $branch = "9a"; })
              }xi;
    push @r,qr{ \b ( )
                   ( (?: $rel_words | (?: close \s+ )? upon ) \s+
                     (?: \w+ \s+ )?
                     $hour_word_re
                   )
                   ( (?: \s+ (?: at | in ) \s+ the
                      |  \s* $ampm_re
                      |  \s+ the  \s+ (?: next | following ) \s+ $timeday_re
                      |  \s+ for  \s+ (?: breakfast | lunch | dinner | luncheon | tea )
                      |  \s+ on   \s+ (?: the \s+ )? $weekday_re
                      |  \s+ that \s+ $timeday_re
                      |  \s+ (?: tonight | today | tomorrow )
                     )
                   ) $ba_re
                 (?{ $branch = "9h"})
              }xi;

    # Times to/from hour
    # ten minutes past noon
    # three minutes till eight
    push @r,qr{  ( $not_in_match )
                   ( (?: (?: $rel_words \s+ )?
                         (?: $min_word_re | \d{1,2} | a | a \s+ few ) (?: \s+ | - )
                         (?: minute s? \s+ )?
                         (?: and (?: \s+ | - )
                                 (?: a \s+ half | 1/2 | a \s+ quarter | 1/4 | twenty
                                   | $sec_re \s+ second s? )? \s+ )?
                         (?: minute s? \s+ )?
                       | (?: $rel_words \s+ )?
                         (?: (?: quarter | 1/4
                              | half | 1/2
                              | third \s+ quarter | three \s+ quarters | 3/4
                             ) (?: \s+ | - ) )
                       | (?: just | nearly ) \s+
                     )
                     (?: before | to | of | after | past | till | ['‘’]til) [\s-]+
                     $hour24_re (?: \s+ $oclock_re )? (?: \s* $ampm_re )?
                     (?! \s+ (?: possibilities ) | :\d | [-] )
                    )
                    () $ba_re
                (?{ $branch = "10"})
              }xi;
    # Do we need to skip nine-to-five?

    # Ones with a phrase before to fix it better as a time
    push @r,qr{ \b ( (?: meet  | meeting  | meets
                      |  start | starting | starts
                     ) \s+
                     (?: (?: tonight | today | tomorrow | $weekday_re | this ) \s+
                      (?: (?: morning | afternoon | evening ) \s+ )?
                     )?
                     at \s+
                   )
                   ( (?: $rel_words \s+ )?
                     $hour24_re (?: [-.:\s]* $min0_re )?
                     (?: \s* $ampm_re )?
                   ) $ba_re
                   ()
                (?{ $branch = "9g"})
              }xi;

    # ... meet me ... at ten forty-five.
    push @r,qr{ $bb_re
                ( meet \s+ me \b [^.!?]* \s+ at \s+ )
                ( $hour24_re [\s.-]+ $min_word_re (?: \s* $ampm_re )? )
                () $ba_re
                (?{ $branch = "5c"})
              }xi;
    # here at seven thirty, be at six forty-five
    push @r,qr{ $bb_re
                ( (?: here | be ) \s+ at \s+ )
                ( $hour24_re [\s.-]+ $min_word_re (?: \s* $ampm_re )?)
                () $ba_re
                (?{ $branch = "5e"})
              }xi;

    # Due ... at eleven-fifty-one
    # Knocks ... at 2336
    push @r,qr{ $bb_re
                ( (?: due | knocks ) \s+ [\w\s]* at \s+ )
                ( $hour24_re [-\s.:]* $min_re (?: \s* $ampm_re )?)
                () $ba_re
                (?{ $branch = "5d"})
              }xi;

    # on the 1237
    push @r,qr{  ( $not_in_match
                     (?: on \s+ the
                      |  here \s+ at
                     ) \s+ )
                   ( (?: $hour12_dig_re [.]? | $hour24_dig_re [.] )
                     $minsec0_dig_re
                   )
                   () $ba_re
                (?{ $branch = "3c"})
              }xi;

    # O'Clocks
    # 1 o'clock, 1 oclock, 1 of the clock
    push @r,qr{ (  $not_in_match_sp )
                ( (?: $rel_words \s+ )?
                  $hour24_re [?]? \s+ $oclock_re
                )
                () $ba_re
                (?{ $branch = "6"})
              }xi;

    # Times at the end of a phrase
    # These are guaranteed times:
    #   waited until eight, ...
    push @r,qr{ $bb_re
                ( (?: waited | arrive s? | called
                   | it \s+ (?: is | was ) | twas | it['‘’]s | begin | end ) \s+
                  (?: (?: at | upon | till | until ) \s+ )?
                )
                ( (?: $rel_words \s+ )?
                  $hour12_re (?: (?: [:.-] | \s+ )? $min0_re )?
                )
                ( [.;:?!""''‘’,“”] (?: \s | \z )
                | \s+ (?: and | - ) \s+
                )
                (?{ $branch = "9f"})
              }xi;

    # Simple times
    # 2300h, 23.00h, 2300 hrs
    push @r,qr{ \b
                ()
                ( (?: $rel_words \s+ )?
                  $hour_dig_re [.:]? $minsec0_dig_re (?: [.:]? $minsec_dig_re )?
                  (?: h | \s* (?: hrs | hours ) )
                )
                () $ba_re
                (?{ $branch = "1"})
              }xi;
    # 2300 GMT, 2300z
    push @r,qr{ \b
                ()
                ( (?: $rel_words \s+ )?
                  $hour_dig_re [.:]? $minsec0_dig_re (?: [.:]? $minsec0_dig_re )?
                )
                ( z | \s* (?: gmt | zulu ) )
                $ba_re
                (?{ $branch = "1a"})
              }xi;

    # Separators are mandatory
    # 5.06 a.m.
    push @r,qr{ ( $not_in_match )
                ( (?: $rel_words \s+ )?
                  $hour12_dig_re [.:] $minsec_dig_re (?: [.:] $minsec_dig_re )?
                  (?: \s* $ampm_re )
                )
                () $ba_re
                (?{ $branch = "2a"})
              }xi;

    # : Means it's a time
    # 12:37
    push @r,qr{ ( $not_in_match )
                ( (?: $rel_words \s+ )?
                  $hour_dig_re : $minsec_dig_re (?: : $minsec_dig_re )?
                  (?: \s* $ampm_re )?
                )
                () $ba_re
                (?{ $branch = "2"})
              }xi;

    # 13 hours and 6 minutes
    # 13 hours, 6 minutes, and 10 seconds
    push @r,qr{ $bb_re
                ()
                (         $hour24_re \s+ hour    s? ,? (?: \s+ and )?
                      \s+ $min_re    \s+ minute  s? ,? (?: \s+ and )?
                  (?: \s+ $sec_re    \s+ seconds s? )?
                )
                () $ba_re
                (?{ $branch = "14"})
               }xi;

    # one hour and a quarter
    push @r,qr{ $bb_re
                ()
                ( $hour24_re \s+ hour s? ,? \s+ and \s+
                  a \s+ (?: half | quarter )
                )
                () $ba_re
                (?{ $branch = "14a:$is_timey"})
               }xi;

    # Word times (other word times come later)
    # eleven fifty-six am
    push @r,qr{ ( $not_in_match )
                ( (?: $rel_words \s+ )?
                  $hour_re
                  (?: [\s.-]+ $min_word_re )?
                  (?: [\s.-]+ $sec_word_re )?
                  \s* $ampm_re
                ) $ba_re
                ()
                (?{ $branch = "5"})
              }xi;

    # PMs
    # 1 pm, one p.m.
    push @r,qr{ ( $not_in_match )
                ( $hour_re [?]? \s* $ampm_re )
                () $ba_re
                (?{ $branch = "7"})
              }xi;

    # three in the morning
    push @r,qr{ $bb_re
                ()
                ( (?: $rel_words \s+ )?
                  $hour_re [?]? (?: [\s.-]+ $min_re)? )
                ( \s+ in \s+ the \s+
                  (?: morning | afternoon | evening )
                )
                $ba_re
                (?{ $branch = "8"})
              }xi;

    # at 1237 when
    # by 8.45 on saturday
    push @r,qr{    ( $not_in_match
                     (?: at | it \s+ is | it \s+ was | twas | by | by \s+ the ) \s+ )
                   ( $hour_re [?]? [-.\s]? $min_re )
                   ( \s+ (?: (?: on | in)
                     \s+ (?: $weekday_re
                          | the \s+ (?: morning | afternoon | evening ) )
                          | when
                          | today | tonight
                          | (?: (?: this | that | one ) \s+
                                (?: morning | afternoon | evening | night ) )
                         )
                   )
                   $ba_re
                (?{ $branch = "3b"})
              }xi;

    # Four, ...
    push @r,qr{ ( \A | ['"‘’“”] | [.;:?!] \s+ )
                ( $hour_word_re )
                ( [,] \s+ )
                (?{ $branch = "9i:$is_timey" })
              }xi;

    # Bad matches -- "4:50 from paddington" -- "Go to 126 Elvers Crescent"

    # The only time in a sentence
    push @r,qr{ ( (?: \A | ['"‘’“”] | [.;:?!] \s+ | \s+ -+ \s+ )
                  (?: (?: only | just | it['‘’]s | it \s+ is | the ) \s+ )?
                )
                ( (?: $rel_words \s+ )?
                  (?: $hour_dig_re [.:] $minsec_dig_re (?: [.:] $minsec_dig_re )?
                   | $hour_dig_re $minsec0_dig_re (?: $minsec0_dig_re )?
                   | $hour24_word_re (?: (?: \s+ | - ) $min_word_re (?: \s* $ampm_re )? )?
                  )
                )
                ( (?: - $minsec_dig_re )?
                  (?: \s+ (?: now | precisely | exactly ) )?
                  (?: \z | [.;:?!,]? ['"‘’“”] | [.;:?!] \s+ | \s+ -+ \s+) )
                (?{ $branch = "9j"})
              }xi;

    # Times at the start of a sentence
    # At ten, ...
    push @r,qr{ ( (?: \A | ['"‘’“”] | [.;:?!,] \s+ )
                  (?: (?: it \s+ was | twas | which \s+ was | and ) \s+ )?
                )
                ( (?: $rel_at_words | (?: close \s+ )? upon | till | by ) \s+
                  $hour24_re (?: [.\s]+ $min0_re )?
                  (?= \s+ (?: last | yesterday | $weekday_re ) | \s* [,-] \s+ )
                )
                ()
                $ba_re
                (?{ $branch = "9e"})
              }xi;
    push @r,qr{ ( (?: \A | ['"‘’“”] | [.;:?!] \s+ )
                  (?: it \s+ was | twas | it \s+ is | at ) \s+
                )
                ( $hour_re (?: (?: [:.-] | \s+ )? $min0_re )? )
                (?! \s+ (?: that | which | point | time | stage
                         | (?: \w+ \s+)? (?: years | weeks | days | hours | minutes | seconds )
                         )
                 )
                ()
                $ba_re
                (?{ $branch = "9d"})
              }xi;
    push @r,qr{ ( (?: \A | ['"‘’“”] | [.;:?!,] \s+ )
                  (?: (?: it \s+ was | twas | because ) \s+)?
                )
                ( (?: $rel_at_words | (?: close \s+ )? upon | till | by ) \s+
                  $hour24_re (?: (?: [:.-] | \s+ )? $min0_re )?
                )
                (?! \s* (?: that | which | point | time | stage | hours | half ) )
                ()
                $ba_re
                (?{ $branch = "9:$is_timey"})
              }xi;

    # Strong word times
    # at eleven fifty-seven
    push @r,qr{    ( $not_in_match
                     (?: at | (?: it | time ) \s+ (?: is | was | will \s+ be ) | by
                      | ['‘’] (?: twill \s+ be | twas )
                      ) \s+
                    )
                ( $hour24_word_re (?: [\s\.]+ | - ) $min_word_re (?: \s* $ampm_re )? )
                () $ba_re
                (?{ $branch = "5b"})
              }xi;

    # Other weird cases
    # here at nine ...
    push @r,qr{ ( \b
                  (?: here | there
                   | today | tonight | night
                   | gets \s+ up | woke | rose | waking
                   | happened \s+ at
                   | news ) \s+
                )
                ( $rel_at_words \s+
                  $hour_word_re
                )
                (?! \s+ (?: years | weeks | days | hours | minutes | seconds ) )
                ()
                $ba_re
                (?{ $branch = "9b"})
               }xi;

    # at a four-thirty screening
    push @r,qr{    ( $not_in_match
                     (?: at \s+ a ) \s+
                    )
                ( $hour24_word_re (?: \s+ | [-.] ) $min_word_re (?: \s* $ampm_re )? )
                ( \s+ (?: screening | viewing | performance | departure | arrival
                       | game | play | movie | flight | train | ship )
                )
                $ba_re
                (?{ $branch = "5f"})
              }xi;

    # More at the end of a phrase
    # These are not always, so look for timey:
    #   ... through Acton at one.
    #   ... starts opening at eight and ...
    push @r,qr{ $bb_re
                ( (?: $at_words | upon | till | from
                   | (?: it | time ) \s+ (?: is | was | will \s+ be )
                   | ['‘’] (?: twill \s+ be | twas )
                  ) \s+
                  (?: only \s+ )?
                )
                ( (?: $rel_words \s+ )?
                  (?: near \s+ )?
                  $hour_re (?: (?: [:.-] | \s+ )? $min0_re )?
                )
                ( (?: \s+ or \s+ so )?
                  (?: [""''‘’“”]
                   | [.;:?!,] (?: [""''‘’“”\s] | \z )
                   | \s+ (?: and | till | before | - ) \s+
                  )
                )
                (?{ $branch = "9c:$is_timey"})
              }xi;

    # Struck / strikes
    push @r,qr{ \b ( (?: clock | bell | watch | it | now | hands ) s? \s+ [\w\s]*?
                     (?: struck | strikes | striking | strike | striketh
                      | beat    | beats   | beating
                      | said    | says    | showed | shows
                      | read    | reads   | reading
                      | (?: point | pointed | pointing ) \s+ to
                     ) \s+
                     (?: $min_re \s+ minutes \s+ (?: before | after ) \s+ )?
                   )
                   ( $hour24_re (?: [-.\s]+ $min0_re )? )
                   () $ba_re
                (?{ $branch = "11"})
              }xi;
    push @r,qr{ \b ( stroke \s+ of \s+ ) ( $hour24_re ) () $ba_re
                (?{ $branch = "12"})
              }xi;
    push @r,qr{ \b ( \b $hour24_re ) ( \s+ strokes ) () $ba_re
                (?{ $branch = "15:$is_timey"})
              }xi;

    # Untrustworthy times... need an indication that it is a time, not just some number
    # at 1237, is 1237, was 1237, by 1237
    push @r,qr{    ( $not_in_match
                     (?: at (?: \s+ last )?
                      | it \s+ is | it \s+ was | twas | by ) \s+ )
                   ( (?: $rel_words \s+ )?
                     (?: $hour12_dig_re [.]? | $hour24_dig_re [.] )
                       $minsec0_dig_re
                     )
                   (?! \s+ (?: miles ) )
                   ()
                   $ba_re
                (?{ $branch = "3:$is_timey"})
              }xi;

    # eleven fifty-six
    push @r,qr{ ( $not_in_match_sp )
                ( (?: $rel_words \s+ )?
                  (?: $hour24_word_re (?: [-\s]+ | \s* (?: \Q...\E | … ) \s* ) $min_word_re
                   | $hour_dig_re [-.] $minsec0_dig_re
                  )
                  (?: \s* $ampm_re )? )
                (?! \s+ (?: years | weeks | days | hours | minutes | seconds )
                 |  -
                )
                ()
                $ba_re
                (?{ $branch = "5a:$is_timey"})
              }xi;

    # Noon / midnight, but not in a << string
    push @r,qr{ ( $not_in_match )
                ( noon | noonday | midnight )
                () $ba_re
                (?{ $branch = "13"})
              }xi;

    # Military times?
    #   Thirteen hundred hours; Zero five twenty-three; sixteen thirteen

    my @parts = $line;
    foreach my $r (@r) {
        my @new;
        foreach my $part (@parts) {
            if ($part !~ m{^<<}) {
                $part =~ s{$r}{$1<<$2|$branch>>$3}g;
                push @new, split(qr{(<<[^>]+>>)}, $part);
            }
            else {
                push @new, $part;
            }
        }
        @parts = @new;
    }
    $line = join '', @parts;

    ## Fixups
    # Get absolute words out
    $line =~ s{<< ( (?: at | by ) \s )}{$1<<}xgi;

    # Undo the masks
    $line =~ s{<< ( [^>]+ ) \|xx >>}{$1}xgi;

    return $line;
}
