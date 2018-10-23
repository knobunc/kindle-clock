#!/bin/env perl

use strict;
use warnings;

use utf8;
use open ':std', ':encoding(UTF-8)';

use Data::Dumper;
use Text::CSV;

use lib '.';

use TimeMatch;


exit main(@ARGV);


sub main {
    my ($file) = @_;

    search_csv($file);

    return 0;
}


sub search_csv {
    my ($file) = @_;
    
    my $csv = Text::CSV->new ( { binary => 1, sep_char => '|', strict => 1 } )
	or die "Cannot use CSV: ".Text::CSV->error_diag ();
    
    open(my $fh, '<:encoding(utf8)', $file)
        or die "Can't read '$file': $!";
    while ( my $row = $csv->getline( $fh ) ) {
        my ($time, $timestr, $line, $book, $author) = @$row;

        $line = do_match($line);

        # TEMPORARILY remove the . times
        $line =~ s{ \b (\d?\d\.?\d\d) \b }{<<$1>>}xgi;

        print "$timestr -- $line\n\n"
            if $line !~ /<</;
    }

    return;
}
