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
    my ($idir, $only_type, $limit, $string_match, $time_it) = @_;
    die "Usage: $0 idir"
        unless defined $idir and -d $idir;

    my $times = load_times($idir, $only_type);

    my $timing = $time_it ? {} : undef;

    check_matches($times, $limit, $string_match, $timing);

    # Print the timing info
    if ($timing) {
        my $total_time;
        foreach my $name (sort  {$timing->{$a}{time} <=> $timing->{$b}{time} } keys %$timing) {
            my $ti = $timing->{$name};
            printf "%10s:  %8.3fms  %3d/%d\n",
                $name, $ti->{time} * 1000, $ti->{hits}//0, $ti->{count};
            $total_time += $ti->{time};
        }

        printf "\nTotal time: %7.3fs\n", $total_time;
    }

    return 0;
}

sub check_matches {
    my ($times, $limit, $string_match, $timing) = @_;

    my $limited = defined $limit ? 1 : 0;
    $limit //= 1000;

    my ($columns) = Term::Size::chars();

    my $printed = 0;
    foreach my $hr (0 .. 23) {
        foreach my $mn (0 .. 59) {
            my $t = sprintf("%02d:%02d", $hr, $mn);
            my $ta = $times->{$t} // [];

            my $sorted = sort_matches_by_auth($ta);
            foreach my $i (0..($limit-1)) {
                last if $i >= @$sorted;
                my ($a, $r, $timestr, $quote, $title, $author, $type) = @{ $sorted->[$i] };

                # Strip any match out of the quote
                my $stripped_quote =  strip_match($quote);

                # Skip the strings that don't match
                next
                    if defined $string_match and $stripped_quote !~ m{$string_match}i;

                # Run the string again with the current rules and see how it fares
                my $new_match = do_match($stripped_quote, undef, $author, $title, $timing);

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

                # Pull the equivalent pieces from the new match
                my $n_timestr = extract_match($new_match, $pre);

                my $type_color = 'bold green';
                my $n_type = '-';
                if ($n_timestr =~ s{\A << [^|]+ \| (?<type> \d+ \w? (: \d)? ) >> }{}xin) {
                    $n_type = $+{type};
                    $type_color = 'bold blue' if $n_type ne $type and $n_type ne "$type:1";

                    # TODO if the string matched is a different length then we should flag it
                } else {
                    $type_color = 'bold red';
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
                if ($post_len > length($post)) {
                    # There's space after, give it to the prefix
                    my $adj = $post_len - length($post);
                    $adj = min( $adj, length($pre) - $pre_len );

                    $pre_len  += $adj;
                    $post_len -= $adj;
                }
                $post .= ' 'x$columns;

                printf("%s%5s⇨%5s%s: %s%s%s%s%s %s%8s%s %s%-8s%s\n",
                       color($type_color), $type // '', $n_type, color('reset'),
                       elide($pre, $pre_len, {truncate => 'left', marker => '…'}),
                       color($type_color), $timestr, color('reset'),
                       elide($post, $post_len, {marker => '…'}),
                       color('bold blue'), elide($s_auth,  8, {marker => '…'}), color('reset'),
                       color('blue'),      elide($s_title, 8, {marker => '…'}), color('reset'),
                      );

                if (++$printed > $limit) {
                    print "Hit Limit\n";
                    exit;
                }
            }
        }
    }

    return;
}

sub extract_match {
    my ($new_match, $pre) = @_;

    my $n_timestr = $new_match;
    my $x_pre = $pre;

    my $len = length($x_pre);
    while ($len) {
        $x_pre =~
            m{ \A (?<p> .*?) << [^|]+ \| (?<type> \d+ \w? (: \d)? ) >>
             | \A (?<p> .+ )
             }xins
                or die "Weird string '$x_pre'";
        my $p  = $+{p};
        my $pl = min( $len, length($p) );

        # There's no match in the prefix length portion, strip that
        substr($n_timestr, 0, $pl, '');
        substr($x_pre,     0, $pl, '');
        $len -= $pl;

        if ($len) {
            # Now we need to handle the match portion from both
            $x_pre =~
                s{\A (?<ml> << (?<tstr> [^|]+ ) \| (?<type> \d+ \w? (: \d)? ) >> ) }{$+{tstr}}xin
                or die "Can't find match in '$x_pre'";
            $len -= length($+{ml}) - length($+{tstr});
            $n_timestr =~
                s{\A        << (?<tstr> [^|]+ ) \| (?<type> \d+ \w? (: \d)? ) >> }{$+{tstr}}xin;

            # And then loop since the match is sanitized
        }
    }

    return $n_timestr;
}

sub sort_matches_by_auth {
    my ($matches) = @_;

    return [sort { my ($a_auth, $a_titl) = make_shorts($a->[5], $a->[4]);
                   my ($b_auth, $b_titl) = make_shorts($b->[5], $b->[4]);

                   $a_auth cmp $b_auth || # Author
                   $a_titl cmp $b_titl || # Title
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
