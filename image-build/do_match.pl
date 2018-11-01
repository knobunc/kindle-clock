#!/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use Data::Dumper;
use lib '.';

use TimeMatch;


exit main(@ARGV);


sub main {
    my ($string) = @_;
    utf8::decode($string);

    while ($string =~ s{<< ([^|>]+) [|] \d+ \w? (:\d)? >>}{$1}gx) { }

    say do_match($string);

    return 0;
}
