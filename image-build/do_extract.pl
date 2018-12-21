#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use Data::Dumper;
use lib '.';

use TimeMatch;


exit main(@ARGV);


sub main {
    my ($string, $permute) = @_;
    utf8::decode($string);

    $string = "<<$string|99>>"
        if $string !~ /<</;

    my @times = extract_times($string, $permute);

    say Dumper(\@times);

    return 0;
}
