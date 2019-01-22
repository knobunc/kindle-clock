#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use lib '.';

use File::Slurper qw( read_binary );
use Text::CSV;
use TimeMatch;

exit main(@ARGV);


my $DEBUG = 0;

sub main {
    my ($idir, $odir) = @_;
    die "Usage: $0 idir odir"
        unless defined $idir and defined $odir and -d $idir and -d $odir;

    ## For each file in the input directory write out a csv with the parsed times
    my $csv = Text::CSV->new ( { binary => 1, sep_char => '|', strict => 1, eol => $/ } )
        or die "Cannot use CSV: ".Text::CSV->error_diag ();

    # Loop over the files in the input dir
    opendir my $idh, $idir
        or die "Unable to read '$idir'";
  FILE_LOOP:
    foreach my $f (sort readdir $idh) {
        next unless $f =~ m{\A (?<author> .+?) \Q - \E (?<book> .+?) \.dmp \z}xn;
        my ($author, $book) = @+{qw{ author book }};

        my $ff = "$idir/$f";
        my $csv_file = "$odir/$author - $book.csv";

        # See if we need to update the times
        if (-f $csv_file and -M $csv_file < -M $ff) {
            print "Skipping '$ff'\n"
                if $DEBUG;
            next FILE_LOOP;
        }
        print "Processing '$ff'\n";

        my $c = read_binary($ff);
        my $VAR1;
        my $matches = eval($c);

        open my $fh, ">:encoding(utf8)", $csv_file
            or die "Can't write to '$csv_file': $!";

        # Now loop over the time strings
        foreach my $ts (map {$_->[2]} @$matches) {
            my $clean_string = $ts;
            $clean_string =~ s{<< (?<tb>[^|>]+) [|] \d+ \w? (:(?<match>\d))? >>}{$+{tb}}gx;

            # Loop over the matches
            my %seen_times;
            while ($ts =~ m{<< (?<tb>[^|>]+) [|] \d+ \w? (:(?<match>\d))? >>}gx) {
                my $time_bit = $+{tb};
                my $match    = $+{match} // 1;
                next if not $match or $seen_times{lc($time_bit)}++;

                my @times = extract_times("<<$time_bit|88>>")
                    or die "Unable to extract time from '$ff' '$time_bit'";

                foreach my $time (@times) {
                    my ($t) = split /: /, $time;

                    $csv->print ($fh, [$t, $time_bit, $clean_string, $book, $author]);
                }
            }
        }

        close $fh
            or die "Error closing '$csv_file': $!";
    }
    closedir $idh;

    return 0;
}

