#!/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

# Force the XS parser
BEGIN { $ENV{PERL_TEXT_CSV}='Text::CSV_XS'; }

use File::Slurper qw( read_binary );
use Text::CSV;

use lib '.';

use TimeMatch;

my $DEBUG = 0;

exit main(@ARGV);


sub main {
    my (@files) = @_;
    die "Usage: $0 files"
        unless @files;

    foreach my $file (@files) {
        my $times = load_times($file);
        printf "%5d %-s\n", int(@$times), $file;
    }

    return 0;
}

sub load_times {
    my ($f) = @_;

    ## For each file in the input directory write out a csv with the parsed times
    my $csv = Text::CSV->new ( { binary => 1, sep_char => '|', strict => 1, eol => $/ } )
        or die "Cannot use CSV: ".Text::CSV->error_diag ();

    my ($time, $timestr, $quote, $title, $author);
    $csv->bind_columns(\ ( $time, $timestr, $quote, $title, $author ));

    my @times;

    die unless $f =~ m{\A (?<author> .+?) \Q - \E (?<book> .+?) \.csv \z}xn;
    my ($fauthor, $fbook) = @+{qw{ author book }};

    my $fh = IO::File->new($f, '<:encoding(utf8)')
        or die "Can't read '$f': $!";

    while ($csv->getline($fh)) {
        $time =~ m{\A ( (?<a> ap ) \s )?
                      ( (?<r> << | < | ~ | - | \+ | > | >> ) \s )?
                        (?<t>\d\d:\d\d)
                   \z}x
            or die "Can't parse '$time' in '$f'";
        my ($a, $r, $t) = @+{qw( a r t )};

        push @times, [$t, $a, $r, $timestr, $quote, $title, $author];
    }

    $fh->close()
        or die "Error closing '$f': $!";

    return \@times;
}
