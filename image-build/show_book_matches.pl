#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use File::Basename;
use File::Slurper qw( read_binary );
use List::Util qw( min max );
use String::Elide::Parts qw(elide);
use Term::ANSIColor qw( color colorstrip );
use Term::Size;

use lib '.';

use TimeMatch;
use Process;


exit main(@ARGV);


sub main {
    my (@book_files) = @_;
    die "Usage: $0 book_files..."
        unless @book_files;

    my %time_matches;

    # Loop over the book files
    foreach my $book_file (@book_files) {
        my $f = basename($book_file);
        die "Unable to get the author and book name from '$f'"
            unless $f =~ m{\A (?<author> .+?) \Q - \E (?<book> .+?) \.dmp \z}xn;
        my ($author, $book) = @+{qw{ author book }};

        my $c = read_binary($book_file);
        my $VAR1;
        my $matches = eval($c);

        # Now loop over the time strings
        foreach my $ts (map {$_->[2]} @$matches) {
            my $clean_string = $ts;
            $clean_string =~ s{<< (?<tb>[^|>]+) [|] (?<type> \d+ \w? (: \d)? ) >>}{$+{tb}}gx;

            # Loop over the matches
            while ($ts =~ m{<< (?<tb>[^|>]+) [|] (?<type> \d+ \w? (: \d)? ) >>}gx) {
                my $time_bit = $+{tb};
                my $type     = $+{type};

                my @times = extract_times("<<$time_bit|$type>>")
                    or die "Unable to extract time from '$book_file' '$time_bit'";

                my ($t) = split /: /, $times[0];
                push @{ $time_matches{$t} },
                     [$t, $time_bit, $clean_string, $ts, $type, $book, $author];
            }
        }
    }

    my ($columns) = Term::Size::chars();

    # Loop over the times and summarize them
    foreach my $time (sort time_sort keys %time_matches) {
        foreach my $r (@{ $time_matches{$time} }) {
            my ($t, $time_bit, $clean_string, $ts, $type, $book, $author) = @$r;

            my $cat = $type;
            my $strong = 1;
            if ($cat =~ s/:(\d+)//) {
                $strong = $1;
            }

            my $type_color = $strong ? "green" : "red";
            $type_color = "bold " . $type_color;

            $ts =~ m{<<\Q$time_bit\E\|$type>>}p
                or die "Can't find match for '$time_bit|$type' in '$ts'";

            my ($pre, $post) = (${^PREMATCH}, ${^POSTMATCH});

            foreach my $s (\$pre, \$post) {
                $$s =~ s{<< (?<tb>[^|>]+) [|] (?<type> \d+ \w? (: \d)? ) >>}{$+{tb}}gx;
                $$s =~ s{[\n\t]}{ }g;
            }

            my ($s_auth, $s_book) = make_shorts($author, $book);

            # Work out the spacing
            my $fixed_size = 10 + 1 + 3 + 1 + 0 + 1 + 6 + 1 + 6;
            my $rem = $columns - $fixed_size - length($time_bit);
            my $pre_len  = min(length($pre), int($rem / 2 + 0.5));
            my $post_len = $rem - $pre_len;
            $post .= ' 'x( max($post_len - length($post), 0) );

            # Pad the ampm if there is nothing between it and the time
            (my $tc = $time) =~ s{^(ap) (\d)}{$1   $2};

            printf("%s%10s%s %s%3s%s %s%s%s%s%s %s%6s%s %s%-6s%s\n",
                   color('bold blue'), $tc,      color('reset'),
                   color($type_color), $cat,     color('reset'),
                   elide($pre, $pre_len, {truncate => 'left'}),
                   color($type_color), $time_bit, color('reset'),
                   elide($post, $post_len),
                   color('bold blue'), elide($s_auth, 6), color('reset'),
                   color('blue'),      elide($s_book, 6), color('reset'),
                   );
        }
    }

    return 0;
}

sub time_sort {
    my $at = $a;
    my $bt = $b;

    $at =~ s/^(\S+ )+//;
    $bt =~ s/^(\S+ )+//;

    return $at cmp $bt || $a cmp $b;
}
