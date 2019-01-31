#!/usr/bin/env perl

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

    my $output_dump = 1;
    my @res;

    my $csv = Text::CSV->new ( { binary => 1, sep_char => '|', strict => 1 } )
        or die "Cannot use CSV: ".Text::CSV->error_diag ();

    my $fh = IO::File->new($file, '<:encoding(utf8)')
        or die "Can't read '$file': $!";
    while ( my $row = $csv->getline( $fh ) ) {
        my ($time, $timestr, $line, $book, $author) = @$row;

        $line = do_match($line, undef, $author, $book);

        # Clean up the time string
        $timestr =~ s{\s+$}{};
        $timestr =~ s{\.$}{}
            if $timestr !~ m{[ap]\.\s*m\.$}i;

        my $m = 1;
        $m = -1 if $line =~ s{\G ( [^<]+ (?: << [^>] >> )? )+
                                 \b ((?: 0)?) (\Q$timestr\E)
                             }{$1$2<<$3|99>>}xi;
        $m = -2 if $line !~ m{<< ([^|>]+) [|] \d+ \w? (:\d)? >>}x;

        if ($m == -1 and $line =~ s{\b0<<}{<<0}) {
            $timestr = 0 . $timestr;
        }

        push @res, [$m, "Timestr [$time]: $timestr", $line];

        print "$timestr [$time] -- $line\n\n"
            if $line !~ /<</ and not $output_dump;
    }

    print Dumper \@res
        if $output_dump;

    return;
}
