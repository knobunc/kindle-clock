#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use Text::CSV;

# Run it
exit main(@ARGV);

#####

sub main {
    my ($csv_file) = @_;
    die "Usage: $0 <csv_file>\n"
        unless $csv_file;

    my $csv = Text::CSV->new(
        { binary => 1, sep_char => '|', strict => 1, quote_space => 0, eol => $/ }
        )
        or die "Cannot use CSV: ".Text::CSV->error_diag ();

    my $fh = IO::File->new($csv_file, '<:encoding(utf8)')
        or die "Can't read '$csv_file': $!";

    while (my $row = $csv->getline($fh)) {
        my ($time, $timestr, $quote, $title, $author) = @$row;

        printf "%40.40s   %-s\n", $author, substr($title, 0, 60);
        next;

        $quote  = clean_string($quote);
        $title  = clean_string($title);
        $author = clean_string($author);

        $csv->print(*STDOUT, [$time, $timestr, $quote, $title, $author]);
    }

    return 0;
}

sub clean_string {
    my ($quote) = @_;

    # Lop leading and trailing space
    $quote =~ s{^\s+}{};
    $quote =~ s{\s+$}{};

    # Fix single quotes in words
    $quote =~ s{(\w)'(\w)}{$1’$2};

    # Fix double quotes
    $quote =~ s{(\s|\A)"(.*?)"(\s|\z|[.,;:])}{$1“$2”$3}g;

    # Smarten single quotes
    $quote =~ s{(\s|\A)'(.*?)'(\s|\z|[.,;:])}{$1‘$2’$3}g;

    # Ellipses
    $quote =~ s{\Q...}{…}g;

    return $quote;
}
