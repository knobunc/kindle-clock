package TimeMatch;

use strict;
use warnings;
use utf8;

use Exporter::Easy (
  EXPORT => [ 'do_match' ],
);


# Numbers 1-9 as words
my $low_num_re = qr{ one | two | three | four | five | six | seven | eight | nine }xi;

# The hours 1-12 as words
my $hour_word_re = qr{ $low_num_re | ten | eleven | twelve | noon | midnight }xi;

# The minutes
my $min_word_re =
    qr{ # 1-9
        (?: oh [\s-] | \b )? $low_num_re
        | # 10-19
        ( ten | eleven | twelve | thirteen | fourteen | fifteen |
        sixteen | seventeen | eighteen | nineteen)
        | # 20-59
        (?: twenty | thirty | forty | fifty ) (?: - $low_num_re )?
      }xi;

# Hour digits
my $hour_dig_re = qr{ [01]?\d | 2[0-4] }xi;

# Min / sec digits
my $minsec_dig_re = qr{ [0-5]?\d | 60 }xi;

# The minutes / seconds as words or numbers
my $min_re = qr{ $minsec_dig_re | $min_word_re }xi;
my $sec_re = qr{ $minsec_dig_re | $min_word_re }xi;

# The hours as words or numbers
my $hour_re = qr{ $hour_dig_re | $hour_word_re }xi;

# The am / pm permutations
my $ampm_re = qr{ [ap]m \b | [ap][.] \s* m[.] }xi;

# Boundary after
my $ba_re = qr{ \b | (?= \W ) | \z }xi;


sub do_match {
    my ($line) = @_;

    ## Now do the matches, next number 15

    # 2300h, 23.00h, 2300 hrs, 2300z
    $line =~ s{ \b ( $hour_dig_re [.:]? $minsec_dig_re (?: : $minsec_dig_re )? (?: h | z | \s* hrs ) ) $ba_re }{<<$1|1>>}xgi;

    # Simple times
    # 12:37
    $line =~ s{ \b ( $hour_dig_re : $minsec_dig_re (?: : $minsec_dig_re )? (?: \s* $ampm_re )? ) $ba_re }{<<$1|2>>}xgi;

    # Untrustworthy times... need an indication that it is a time, not just some number
    # at 1237, to 1237, is 1237, was 1237, by 1237
    $line =~ s{ \b ( (?: at | to | is | was | by ) \s+ \d{1,2} [.]? \d\d ) $ba_re }{<<$1|3>>}xgi;
    # 11.32 pm
    $line =~ s{ \b ( $hour_dig_re [.]? $minsec_dig_re [.]? $minsec_dig_re? \s* $ampm_re ) $ba_re }{<<$1|4>>}xgi;

    # Bad matches -- "4:50 from paddington" -- "Go to 126 Elvers Crescent"

    # 13 hours and 6 minutes
    # 13 hours, 6 minutes, and 10 seconds
    $line =~ s{ \b ( $hour_re \s+ hour    s? ,? \s+ (?: and \s+ )?
                     $min_re  \s+ minute  s? ,? \s+ (?: and \s+ )?
                     (?: $sec_re  \s+ seconds s? )?
                    )
               }{<<$1|14>>}xgi;

    # Word times
    # eleven fifty-six
    $line =~ s{ \b ( $hour_re [\s.-]+ $min_word_re (?: $ampm_re )?) $ba_re }{<<$1|5>>}xgi;

    # O'Clocks
    # 1 o'clock
    $line =~ s{ \b ( $hour_re [?]? \s+ o(?: ['’] \s* | f \s+ the \s+ )?clock ) $ba_re }
              {<<$1|6>>}xgi;

    # PMs
    # 1 pm, one p.m.
    $line =~ s{ \b ( $hour_re [?]? \s* $ampm_re ) $ba_re }{<<$1|7>>}xgi;
    # three in the morning
    $line =~ s{ \b ( $hour_re [?]? \s+ in \s+ the \s+ (?: morning | afternoon ) ) $ba_re }{<<$1|8>>}xgi;

    # Relative times
    $line =~ s{ \b ( (?: at | after | before | about | by | until
                      | upon | till | around | nearly ) \s+
                     (?: \w+ \s+ )?
                     $hour_word_re ) $ba_re }{<<$1|9>>}xgi;
    #$line =~s{ \b ( at \s+ $hour_word_re \s+ in \s+ the ) $ba_re }{<<$1|9a>>}xgi;

    # Times to/from hour
    # 5 minutes to midnight, ten minutes past noon
    $line =~ s{ \b ( (?: (?: \b $min_word_re | \d{1,2} | a | a \s+ few ) (?: \s+ | - )
                      (?: minute s? \s+ )?
                      (?: and \s+ (?: a \s+ half | a \s+ quarter
                                   | $min_word_re \s+ second s? )? \s+ )?
                      (?: minute s? \s+ )?
                      | (?: (?: half | quarter | three \s+ quarters ) (?: \s+ | - ) )
                      | (?: just | nearly ) \s+
                     )
                     (?: before | to | of | after | past ) [\s-]+
                     $hour_re $ampm_re? ) $ba_re }{<<$1|10>>}xgi;

    # Struck / strikes
    $line =~ s{ \b ( (?: clock | bell | it ) s? \s+ [\w\s]*?
                     (?: struck | strikes | striking | strike | striketh
                      | beat   | beats   | beating ) \s+
                     (?: $min_re \s+ minutes \s+ (?: before | after ) \s+ )?
                     (?: $hour_re | thirteen )
                    ) $ba_re }
              {<<$1|11>>}xgi;
    $line =~ s{ \b ( stroke \s+ of \s+ (?: $hour_re | thirteen ) ) $ba_re }
              {<<$1|12>>}xgi;

    # Noon / midnight
    $line =~ s{ \b ( noon | noonday | midnight ) $ba_re }{<<$1|13>>}xgi;

    # Military times?
    #   Thirteen hundred hours; Zero five twenty-three; sixteen thirteen

    return $line;
}


