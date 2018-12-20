#!/bin/env perl
use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use Data::Dumper;
use Lingua::LinkParser;
use Lingua::LinkParser::Definitions qw(define);

## This script demonstrates the "big struct", which is the merge of all linkages
## into a Perl data struct you can iterate, as demonstrated below.

my $parser = new Lingua::LinkParser;

my $sentence = $parser->create_sentence(
        "Perl is a great language.");

my @bigstruct = $sentence->get_bigstruct;

for my $i (0 .. @bigstruct-1) {
    print "\nword $i: ", $bigstruct[$i]->{word}, "\n";

    while (my ($k,$v) = each %{$bigstruct[$i]->{links}} ) {
        print " $k => ", $bigstruct[$v]->{word}, " (", define($k), ")\n";
    }
}

