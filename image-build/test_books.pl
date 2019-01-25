#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';


use File::Slurper qw( read_binary );
use List::Util qw( min max );
use String::Elide::Parts qw(elide);
use Term::ANSIColor qw( color colorstrip );
use Term::Size;
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

    check_matches($times, $limit);

    return 0;
}

sub check_matches {
    my ($times, $limit) = @_;

    my $limited = defined $limit ? 1 : 0;
    $limit //= 10;

    my ($columns) = Term::Size::chars();

    foreach my $hr (0 .. 23) {
        foreach my $mn (0 .. 59) {
            my $t = sprintf("%02d:%02d", $hr, $mn);
            my $ta = $times->{$t} // [];

            my $sorted = sort_matches_by_auth($ta);
            foreach my $i (0..($limit-1)) {
                last if $i >= @$sorted;
                my ($a, $r, $timestr, $quote, $title, $author, $type) = @{ $sorted->[$i] };

                # Run the string again with the current rules and see how it fares
                my $new_match = do_match( strip_match($quote) );
                my $different = $quote eq $new_match ? 0 : 1;

                # Pull the preamble and postamble
                my ($pre, $post);
                if ($type) {
                    $quote =~ m{<<\Q$timestr\E\|$type>>}p
                        or die "Can't find match for '$timestr|$type' in '$quote'";
                    ($pre, $post) = (${^PREMATCH}, ${^POSTMATCH});
                }
                else {
                    $quote =~ m{\Q$timestr\E}p
                        or die "Can't find match for '$timestr' in '$quote'";
                    ($pre, $post) = (${^PREMATCH}, ${^POSTMATCH});
                }

                # Pull the equivelent pieces from the new match
                my ($n_timestr) = substr($new_match, length($pre), - length($post));

                my $type_color = $different ? 'bold red' : 'bold green';

                my $n_type = '-';
                if ($n_timestr =~ m{\| (?<type> \d+ \w+ (: \d)? ) >>\z}xin) {
                    $n_type = $+{type};
                    $type_color = 'bold blue' if $n_type ne $type;
                }

                # Pull the matches from the previous and clean up the strings
                foreach my $s (\$pre, \$timestr, \$n_timestr, \$post) {
                    $$s =~ s{<< (?<tb>[^|>]+) [|] (?<type> \d+ \w? (: \d)? ) >>}{$+{tb}}gx;
                    $$s =~ s{[\n\t]}{ }g;
                    $$s =~ s{\s\s+}{ }g;
                }

                my ($s_auth, $s_title) = make_shorts($author, $title);

                # Work out the size remaining
                my $fixed_size = 5 + 1 + 5 + 1 + 1 + 0 + 1 + 8 + 1 + 8;
                my $rem = $columns - $fixed_size - length($timestr);
                my $pre_len  = min(length($pre), int($rem / 2 + 0.5));
                my $post_len = $rem - $pre_len;
                $post .= ' 'x$columns;

                printf("%s%5s⇨%5s%s: %s%s%s%s%s %s%8s%s %s%-8s%s\n",
                       color($type_color), $type // '', $n_type, color('reset'),
                       elide($pre, $pre_len, {truncate => 'left', marker => '…'}),
                       color($type_color), $timestr, color('reset'),
                       elide($post, $post_len, {marker => '…'}),
                       color('bold blue'), elide($s_auth,  8, {marker => '…'}), color('reset'),
                       color('blue'),      elide($s_title, 8, {marker => '…'}), color('reset'),
                      );
            }
            print "            ..."
                if @$sorted > $limit;
        }
    }

    return;
}

sub sort_matches_by_auth {
    my ($matches) = @_;

    return [sort { $a->[4] cmp $b->[4] || # Author
                   $a->[5] cmp $b->[5] || # Title
                   $a->[2] cmp $b->[2] || # Time
                   $a->[3] cmp $b->[3] || # Quote
                   $a cmp $b              # Tiebreaker
                 } @$matches
           ];
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
