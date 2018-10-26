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

    say do_match($string);

    return 0;
}
