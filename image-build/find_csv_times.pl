#!/bin/env perl

use Modern::Perl '2017';

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

    my $output_dump = 0;
    my @res;

    my $csv = Text::CSV->new ( { binary => 1, sep_char => '|', strict => 1 } )
        or die "Cannot use CSV: ".Text::CSV->error_diag ();

    my $fh = IO::File->new($file, '<:encoding(utf8)')
        or die "Can't read '$file': $!";
    while ( my $row = $csv->getline( $fh ) ) {
        my ($time, $timestr, $line, $book, $author) = @$row;

        $line = do_match($line);

        my $m = 1;
        $m =~ -1 if $line =~ s{ \b (\d?\d\.?\d\d) \b }{<<$1>>}xgi;
        push @res, [$m, "Timestr: $timestr", $line];

        print "$timestr -- $line\n\n"
            if $line !~ /<</ and not $output_dump;
    }

    print Dumper \@res
        if $output_dump;

    return;
}
