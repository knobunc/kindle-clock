package TimeMatch;

use Modern::Perl '2017';

use utf8;

use Exporter::Easy (
  EXPORT => [ 'do_match' ],
);


# Numbers 1-9 as words
my $low_num_re = qr{ one | two | three | four | five | six | seven | eight | nine }xi;

# The hours 1-12 as words
my $hour_word_re = qr{ $low_num_re | ten | eleven | twelve | noon | midnight }xi;

# The hours 13-24 as words
my $hour24_word_re = qr{ $hour_word_re | thirteen | fourteen | fifteen |
                         sixteen | seventeen | eighteen | nineteen }xi;

# The minutes
my $min_word_re =
    qr{ # 1-9
        (?: oh [\s-] | \b )? $low_num_re
        | # 10-19
        (?: ten | eleven | twelve | thirteen | fourteen | fifteen |
            sixteen | seventeen | eighteen | nineteen )
        | # 20-59
        (?: twenty | thirty | forty | fifty ) (?: - $low_num_re )?
      }xi;
my $sec_word_re = $min_word_re;

# Hour digits
my $hour_dig_re = qr{ [01]?\d | 2[0-4] }xi;           # 00-24
my $hour12_dig_re = qr{ [1-9] | 1[0-2] }xi;           # 1-12
my $hour24nz_dig_re = qr{ 0?[1-9] | 1\d | 2[0-4] }xi; # 01-24

# Min / sec digits
my $minsec_dig_re  = qr{ [0-5]?\d | 60 }xi;
my $minsec0_dig_re = qr{ [0-5]\d | 60 }xi;

# The minutes / seconds as words or numbers
my $min_re = qr{ $minsec_dig_re | $min_word_re }xi;
my $min0_re = qr{ $minsec0_dig_re | $min_word_re }xi;
my $sec_re = $min_re;

# The hours as words or numbers
my $hour_re   = qr{ $hour_dig_re | $hour_word_re }xi;
my $hour24_re = qr{ $hour_dig_re | $hour24_word_re }xi;

# The am / pm permutations
my $ampm_re = qr{ [ap]m \b | [ap][.] \s* m[.]? | pee \s+ em }xi;

# Boundary before and after
my $bb_re = qr{ (?<= [\[\s"'(‘] ) | \A }xi;
my $ba_re = qr{ \b | (?= [.,:;?/"'\s] ) | \z }xi;

# Relative words
my $rel_words = qr{ at | after | before | about | until | around }xi;

# Weekdays
my $weekday_re = qr{ monday | tuesday | wendesday | thursday | friday | saturday | sunday }xi;

# Times of day
my $timeday_re = qr{(?: day | morning | night )}xi;

sub do_match {
    my ($line) = @_;

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
                   (?: return | returned | back ) \s* $rel_words
                   ) \b
             }xi;


    ## Now do the matches, next number 16

    # 2300h, 23.00h, 2300 hrs, 2300z
    $line =~ s{ $bb_re ( $hour_dig_re [.:]? $minsec_dig_re (?: [.:]? $minsec_dig_re )? (?: h | z | \s* hrs ) ) $ba_re }{<<$1|1>>}xgi;

    # Simple times
    # 12:37
    $line =~ s{ $bb_re ( $hour_dig_re : $minsec_dig_re (?: : $minsec_dig_re )? (?: \s* $ampm_re )? ) $ba_re }{<<$1|2>>}xgi;
    # 5.06 a.m.
    $line =~ s{ $bb_re ( $hour_dig_re [.] $minsec_dig_re (?: [.] $minsec_dig_re )? \s* $ampm_re ) $ba_re }{<<$1|2a>>}xgi;

    # 11.32 pm
    $line =~ s{ $bb_re ( $hour12_dig_re [.]? $minsec_dig_re [.]? $minsec0_dig_re? \s* $ampm_re ) $ba_re }
              {<<$1|4:$is_timey>>}xgi;

    # Bad matches -- "4:50 from paddington" -- "Go to 126 Elvers Crescent"

    # 13 hours and 6 minutes
    # 13 hours, 6 minutes, and 10 seconds
    $line =~ s{ $bb_re
                (         $hour24_re \s+ hour    s? ,? (?: \s+ and )?
                      \s+ $min_re    \s+ minute  s? ,? (?: \s+ and )?
                  (?: \s+ $sec_re    \s+ seconds s? )?
                 ) $ba_re
               }{<<$1|14>>}xgi;

    # one hour and a quarter
    $line =~ s{ $bb_re
                ( $hour24_re \s+ hour s? ,? \s+ and \s+
                  a \s+ (?: half | quarter )
                ) $ba_re
               }{<<$1|14a:$is_timey>>}xgi;

    # Word times (other word times come later)
    # eleven fifty-six am
    $line =~ s{ $bb_re ( $hour_re [\s.-]+ $min_word_re $ampm_re ) $ba_re }{<<$1|5>>}xgi;

    # O'Clocks
    # 1 o'clock, 1 oclock, 1 of the clock
    $line =~ s{ $bb_re ( $hour24_re [?]? \s+ o(?: ['’] \s* | f \s+ the \s+ )?clock ) $ba_re }
              {<<$1|6>>}xgi;

    # PMs
    # 1 pm, one p.m.
    $line =~ s{ $bb_re ( $hour_re [?]? \s* $ampm_re ) $ba_re }{<<$1|7>>}xgi;
    # three in the morning
    $line =~ s{ $bb_re ( $hour_re [?]? \s+ in \s+ the \s+ (?: morning | afternoon ) ) $ba_re }{<<$1|8>>}xgi;

    # Four, ...
    $line =~ s{ ( \A | ['"] | [.;:?!] \s+ ) ( $hour_word_re [,] \s+ ) }{$1<<$2|9e:$is_timey>>}xgi;

    # Other weird cases
    # here at nine ...
    $line =~ s{ ( (?: here | today | tonight | night
                   | gets \s+ up | woke | rose | waking
                   | back \s+ here | news ) \s+
                )
                ( $rel_words \s+
                  $hour_word_re
                ) }{$1<<$2|9b>>}xgi;

    # ... meet me ... at ten forty-five.
    $line =~ s{ $bb_re ( meet \s+ me \b [^.!?]* \s+ at \s+ ) ( $hour24_re [\s.-]+ $min_word_re (?: $ampm_re )? ) $ba_re }{$1<<$2|5c>>}xgi;
    $line =~ s{ $bb_re ( (?: here | be ) \s+ at \s+ ) ( $hour24_re [\s.-]+ $min_word_re (?: $ampm_re )?) $ba_re }{$1<<$2|5b>>}xgi;

    # Ones with a phrase after to fix it better as a time
    $line =~ s{ \b ( (?: $rel_words | upon | till | nearly | it \s* was ) \s+
                     (?: \w+ \s+ )?
                     $hour_word_re
                     (?: \s+ (?: at | in ) \s+ the
                      |  \s* $ampm_re
                      |  \s+ the  \s+ (?: next | following ) \s+ $timeday_re
                      |  \s+ for  \s+ (?: breakfast | lunch | dinner | luncheon | tea )
                      |  \s+ on   \s+ (?: the \s+ )? $weekday_re
                      |  \s+ that \s+ $timeday_re
                      |  \s+ (?: tonight | today | tomorrow )
                     )
                   ) $ba_re }{<<$1|9a>>}xgi;

    # Times to/from hour
    # ten minutes past noon
    $line =~ s{ \b ( (?: (?: \b $min_word_re | \d{1,2} | a | a \s+ few ) (?: \s+ | - )
                         (?: minute s? \s+ )?
                         (?: and \s+ (?: a \s+ half | a \s+ quarter
                                      | $sec_word_re \s+ second s? )? \s+ )?
                         (?: minute s? \s+ )?
                       | (?: (?: half | quarter | three \s+ quarters ) (?: \s+ | - ) )
                       | (?: just | nearly ) \s+
                     )
                     (?: before | to | of | after | past ) [\s-]+
                     $hour24_re (?: \s* $ampm_re )?
                     (?! \s+ (?: possibilities ) )
                    ) $ba_re }{<<$1|10>>}xgi;
    # Do we need to skip nine-to-five?

    # Due ... at eleven-fifty-one
    $line =~ s{ $bb_re ( due \s+ [\w\s]* at \s+ ) ( $hour24_re [\s.-]+ $min_word_re (?: $ampm_re )?) $ba_re }{$1<<$2|5d>>}xgi;

    # Times at the end of a phrase
    # ... through Acton at one.
    # ... starts opening at eight and ...
    $line =~ s{ $bb_re
                ( (?: $rel_words | upon | till | nearly | it \s+ was (?: \s+ $rel_words )? ) \s+ )
                ( $hour_re (?: [:.-]? $min0_re )? )
                ( [.;:?!""'',] (?: \s | \z ) | \s+ (?: and | - ) \s+ )
              }{$1<<$2|9c:$is_timey>>$3}xgi;

    # Times at the start of a sentence
    # At ten, ...
    $line =~ s{ ( (?: \A | ['"] | [.;:?!] \s+ )
                  (?: it \s+ was \s+)?
                )
                ( (?: $rel_words | (?: close \s+ )? upon | till | nearly | by ) \s+
                  $hour24_re (?: [.\s]+ $min0_re )?
                  (?= \s+ (?: last | yesterday | (?: , \s+ )? $weekday_re ) )
                ) $ba_re }{$1<<$2|9e>>}xgi;
    $line =~ s{ ( (?: \A | ['"] | [.;:?!] \s+ )
                  (?: it \s+ was \s+)?
                )
                ( (?: $rel_words | (?: close \s+ )? upon | till | nearly | by ) \s+
                  $hour24_re (?: [.]? $minsec0_dig_re )?
                  (?! \s+ (?: that | which | point | time | stage ) )
                ) $ba_re }{$1<<$2|9:$is_timey>>}xgi;
    $line =~ s{ ( (?: \A | ['"] | [.;:?!] \s+ )
                  it \s+ was \s+
                )
                ( $hour24_re (?: [.]? $minsec0_dig_re )?
                  (?! \s+ (?: that | which | point | time | stage ) )
                ) $ba_re }{$1<<$2|9d>>}xgi;

    # Struck / strikes
    $line =~ s{ \b ( (?: clock | bell | it | now ) s? \s+ [\w\s]*?
                     (?: struck | strikes | striking | strike | striketh
                      | beat   | beats   | beating ) \s+
                     (?: $min_re \s+ minutes \s+ (?: before | after ) \s+ )?
                     $hour24_re
                    ) $ba_re }
              {<<$1|11>>}xgi;
    $line =~ s{ \b ( stroke \s+ of \s+ $hour24_re ) $ba_re }
              {<<$1|12>>}xgi;
    $line =~ s{ \b ( \b $hour24_re \s+ strokes ) $ba_re }
              {<<$1|15:$is_timey>>}xgi;

    # Untrustworthy times... need an indication that it is a time, not just some number
    # at 1237 when
    $line =~ s{ \b ( (?: at | it \s+ is | it \s+ was | by ) \s+ )
                   ( $hour12_dig_re [.]? $minsec0_dig_re )
                   ( \s+ (?: when ) \s+ )
              }
              {$1<<$2|3a>>$3}xgi;
    # at 1237, is 1237, was 1237, by 1237
    $line =~ s{ \b ( (?: at | it \s+ is | it \s+ was | by ) \s+ )
                   ( $hour12_dig_re [.]? $minsec0_dig_re )
                   $ba_re }
              {$1<<$2|3:$is_timey>>}xgi;

    # eleven fifty-six
    $line =~ s{ \A ( (?: [^<]+ | <[^<] | << [^>]+ >> )* )
                ( $hour24_re [\s.-]+ $min_word_re (?: $ampm_re )?) $ba_re }{$1<<$2|5a:$is_timey>>}xgi;

    # Noon / midnight, but not in a << string
    $line =~ s{ \A ( (?: [^<]+ | <[^<] | << [^>]+ >> )* )
                ( noon | noonday | midnight ) $ba_re }{$1<<$2|13>>}xgi;

    # Military times?
    #   Thirteen hundred hours; Zero five twenty-three; sixteen thirteen

    return $line;
}


