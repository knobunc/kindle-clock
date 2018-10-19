#!/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use XML::Entities;

exit main(@ARGV);


sub main {
    my ($file) = @_;

    search_csv($file);

    return 0;
}


sub search_csv {
    my ($file) = @_;

    open(my $fh, '<', $file)
        or die "Can't read '$file': $!";
    my @lines = <$fh>;

    # Numbers 1-9 as words
    my $low_num_re = qr{ \b (?: one | two | three | four | five | six | seven | eight | nine ) \b }xi;

    # The hours 1-12 as words
    my $hour_word_re = qr{ \b (?: $low_num_re | ten | eleven | twelve ) \b }xi;

    # The minutes
    my $min_word_re =
        qr{ \b (?:
                  # 1-9
                  (?: oh (?: \s | - ) )? $low_num_re
                | # 10-19
                  ( ten | eleven | twelve | thirteen | fourteen | fifteen |
                    sixteen | seventeen | eighteen | nineteen)
                | # 20-59
                  (?: twenty | thirty | fourty | fifty ) (?: - $low_num_re )?
                ) \b
          }xi;

    # The hours as words or numbers
    my $hour_re = qr{ \b (?: \d{1,2} | $hour_word_re | noon | midnight ) \b }xi;

    # The am / pm permutations
    my $ampm_re = qr{ [ap]m | [ap][.] \s* m[.] }xi;

    foreach my $raw_line (@lines) {
        my ($time, $timestr, $line, @junk) = split /\|/, $raw_line;

        # 2300h, 23.00h, 2300 hrs, 2300z
        $line =~ s{ \b ( \d\d[.:]?\d\d (?: h | z | \s* hrs ) ) \b }{<<$1>>}xgi;

        # Simple times
        # 12:37
        $line =~ s{ \b ( \d{1,2}:\d{1,2} (?: :\d{1,2} )? (?: \s* $ampm_re )? ) \b }{<<$1>>}xgi;

        # Untrustworthy times... need an indication that it is a time, not just some number
        # at 1237, to 1237, is 1237, was 1237, by 1237
        $line =~ s{ \b (?: at | to | is | was | by ) \s+ ( \d{1,2} [.]? \d\d ) \b }{<<$1>>}xgi;
        # 11.32 pm
        $line =~ s{ \b ( \d{1,2} [.]? \d\d \s* $ampm_re ) \b }{<<$1>>}xgi;

        # Word times
        # eleven fifty-six
        $line =~ s{ \b ( $hour_word_re [\s-]+ $min_word_re ) \b }{<<$1>>}xgi;

        # O'Clocks
        # 1 o'clock
        $line =~ s{ \b ( $hour_re \s+ o(?:'|’)?clock ) \b }{<<$1>>}xgi;

        # Relative times
        $line =~ s{ \b ( (?: at | after | before | about ) \s+ $hour_re ) \b }{<<$1>>}xgi;

        # Special times
        # noon, midnight
        $line =~ s{ \b ( (?: at | after | before ) \s+ \d{1,2}) \b }{<<$1>>}xgi;

        # Times to/from hour
        # 5 minutes to midnight, ten minutes past noon
        $line =~ s{ \b ( (?: (?: $min_word_re | \d{1,2} | A ) \s+ (?: minute s? \s+ )?
                           | (?: (?: half | quarter | three \s+ quarters ) (?: \s+ | - ) )
                         )
                         (?: to | past ) \s+
                         $hour_re ) \b }{<<$1>>}xgi;

        # Struck / strikes
        $line =~ s{ \b clock [\w\s]+ \s+ (?: struck | strikes | striking ) \s+ ( $hour_re ) \b }{<<$1>>}xgi;

        print "$timestr -- $line\n\n"
            if $line !~ /<</;
    }

    return;
}
