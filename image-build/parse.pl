#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use Data::Dumper;
use Lingua::LinkParser;
use Lingua::LinkParser::Definitions qw(define);


our $parser = new Lingua::LinkParser(verbosity => 0);

my $input = shift;

while ($input =~ s{<< ([^|>]+) [|] \d+ \w? (:\d)? >>}{$1}gx) { }
$input =~ s{<<(.*?)>>}{$1}g;

my $sentence = $parser->create_sentence($input);

my @linkages = $sentence->linkages();
foreach my $linkage ($linkages[0]) {
    print $parser->get_diagram($linkage);
    print $parser->get_domains($linkage);
    print "-"x70, "\n";
}

exit;
