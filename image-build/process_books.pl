#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';


use File::Slurper qw( read_binary );
use XML::Entities;

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
    my ($idir, $only_type, $limit) = @_;
    die "Usage: $0 idir"
        unless defined $idir and -d $idir;

    my $times = load_times($idir, $only_type);

    print_matches($times, $limit);

    return 0;
}

sub load_times {
    my ($idir, $only_type) = @_;

    my %times;

    # Loop over the files in the input dir
    opendir my $idh, $idir
        or die "Unable to read '$idir'";
    foreach my $f (sort readdir $idh) {
        next unless $f =~ m{\A (?<author> .+?) \Q - \E (?<book> .+?) \.dmp \z}xn;
        my ($fauthor, $fbook) = @+{qw{ author book }};
        next if $IGNORE_AUTHORS{$fauthor};

        my $ff = "$idir/$f";
        $ff =~ s{//+}{/}g;

        my $c = read_binary($ff);
        my $VAR1;
        my $matches = eval($c);
        die "Unable to load '$ff': $@"
            if $@;

        my $cnt = 0;
        foreach my $ts (map {$_->[2]} @$matches) {
            # Loop over the matches
            while ($ts =~ m{<< (?<tb>[^|>]+) [|] (?<type> \d+ \w? (: \d)? ) >>}gx) {
                my $time_bit = $+{tb};
                my $type     = $+{type};

                if ($only_type) {
                    next unless $type =~ /^($only_type)$/;
                }

                my @times = extract_times("<<$time_bit|$type>>")
                    or die "Unable to extract time from '$ff' '$time_bit'";
                my ($time) = split /: /, $times[0];

                $time =~ m{\A ( (?<a> ap ) \s )?
                              ( (?<r> << | < | ~ | - | \+ | > | >> ) \s )?
                              (?<t>\d\d:\d\d)
                           \z}x
                    or die "Can't parse '$time' in '$ff'";
                my ($a, $r, $t) = @+{qw( a r t )};

                push @{ $times{$t} }, [$a, $r, $time_bit, $ts, $fbook, $fauthor, $type];
                if ($a and not $only_type) {
                    # Add in a pm record if needed
                    my ($h, $m) = split /:/, $t;
                    $t = $h+12 . ":$m";
                    push @{ $times{$t} }, [$a, $r, $time_bit, $ts, $fbook, $fauthor, $type];
                }
                $cnt++;
            }
        }

        printf "Read %4d rows from '%s'\n", $cnt, $f
            if $DEBUG;
    }
    closedir $idh;

    return \%times;
}
