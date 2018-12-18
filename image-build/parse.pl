#!/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use Lingua::LinkParser;

our $parser = new Lingua::LinkParser;

my $input = shift;

while ($input =~ s{<< ([^|>]+) [|] \d+ \w? (:\d)? >>}{$1}gx) { }
$input =~ s{<<(.*?)>>}{$1}g;

my $sentence = $parser->create_sentence($input);
my @linkages = $sentence->linkages();
foreach my $linkage (@linkages) {
    print ($parser->get_diagram($linkage));
}

exit;
