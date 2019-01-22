#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

# Force the XS parsers
BEGIN {
    $ENV{PERL_TEXT_CSV}     = 'Text::CSV_XS';
}

use Text::CSV;

use lib '.';

use Process;
use TimeMatch;

my $DEBUG = 0;

my %IGNORE_AUTHORS =
    map({ ($_ => 1) }
        ('Abby Hafer',          # No real times
         'Alan A. A. Donovan',  # Code
         'Charles Petzold',     # Code lead to too many false positives
         'Geoffrey Chaucer',    # Inscruitable variations on noon
         'William L. Shirer',   # Don't care about the Third Reich
         '',
         '',
         '',
        ));

exit main(@ARGV);


sub main {
    my ($idir) = @_;
    die "Usage: $0 idir"
        unless defined $idir and -d $idir;

    my $times  = load_times($idir);

    print_matches($times);

    return 0;
}

sub load_times {
    my ($idir) = @_;

    ## For each file in the input directory write out a csv with the parsed times
    my $csv = Text::CSV->new ( { binary => 1, sep_char => '|', strict => 1, eol => $/ } )
        or die "Cannot use CSV: ".Text::CSV->error_diag ();

    my ($time, $timestr, $quote, $title, $author);
    $csv->bind_columns(\( $time, $timestr, $quote, $title, $author ));

    my %times;

    # Loop over the files in the input dir
    opendir my $idh, $idir
        or die "Unable to read '$idir'";
    foreach my $f (sort readdir $idh) {
        next unless $f =~ m{\A (?<author> .+?) \Q - \E (?<book> .+?) \.csv \z}xn;
        my ($fauthor, $fbook) = @+{qw{ author book }};
        next if $IGNORE_AUTHORS{$fauthor};

        my $ff = "$idir/$f";
        $ff =~ s{//+}{/}g;

        my $fh = IO::File->new($ff, '<:encoding(utf8)')
            or die "Can't read '$ff': $!";

        my $cnt = 0;
        while ($csv->getline($fh)) {
            $time =~ m{\A ( (?<a> ap ) \s )?
                          ( (?<r> << | < | ~ | - | \+ | > | >> ) \s )?
                            (?<t>\d\d:\d\d)
                       \z}x
                or die "Can't parse '$time' in '$ff'";
            my ($a, $r, $t) = @+{qw( a r t )};

            push @{ $times{$t} }, [$a, $r, $timestr, $quote, $title, $author];
            if ($a) {
                my ($h, $m) = split /:/, $t;
                $t = $h+12 . ":$m";
                push @{ $times{$t} }, [$a, $r, $timestr, $quote, $title, $author];
            }
            $cnt++;
        }

        printf "Read %4d rows from '%s'\n", $cnt, $f
            if $DEBUG;

        $fh->close()
            or die "Error closing '$ff': $!";
    }
    closedir $idh;

    return \%times;
}
