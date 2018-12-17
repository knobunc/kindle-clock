#!/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use Lingua::LinkParser;

our $parser = new Lingua::LinkParser;

my $input = shift;

my $sentence = $parser->create_sentence($input);
my @linkages = $sentence->linkages();
foreach my $linkage (@linkages) {
    print ($parser->get_diagram($linkage));
}

exit;
