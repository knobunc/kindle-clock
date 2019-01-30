package Process;

use Modern::Perl '2017';

use utf8;

# Force the XS parsers
BEGIN {
    $ENV{PERL_JSON_BACKEND} = 'JSON::XS';
}

use Exporter::Easy (
  EXPORT => [ qw( print_matches make_shorts ) ],
);

use Carp;
use File::Slurper qw( read_binary );
use JSON;
use List::Util qw( min max );
use String::Elide::Parts qw(elide);
use Term::ANSIColor qw( color colorstrip );
use Term::Size;
use TimeMatch;
use XML::Entities;


sub print_matches {
    my ($times, $limit) = @_;

    my $limited = defined $limit ? 1 : 0;
    $limit //= 10;

    my $awards = load_awards();

    my @types = qw( <<  <  ~  -  +  >  >> );

    my ($columns) = Term::Size::chars();

    foreach my $hr (0 .. 23) {
        foreach my $mn (0 .. 59) {
            my $t = sprintf("%02d:%02d", $hr, $mn);
            my $ta = $times->{$t} // [];

            my $w  = 0;
            my $x  = 0;
            my $ap = 0;
            my %tc;
            foreach my $e (@$ta) {
                my ($a, $r, undef, undef, $title, $author, $type) = @$e;

                $w++ if $awards->{$author}{$title};

                if (not $a and not $r) {
                    $x++;
                    next;
                }
                $ap++ if $a;
                if ($r) {
                    $tc{$r}++;
                }
            }

            my $rs = join("  ", map({sprintf("%4d%s", $tc{$_}//0, $_)} @types));

            # Time: Total AMPM Exact Awards Relatives
            my $print = 0;
            if (not $limited or @$ta) {
                $print = 1;
            }

            printf("%s%5s:%s %4dT  %4dA  %4dE  %4d*  %s\n",
                   color('bold blue'), $t, color('reset'),
                   int(@$ta), $ap, $x, $w, $rs)
                if $print;

            my $sorted = sort_matches($ta, $awards);
            foreach my $i (0..($limit-1)) {
                last if $i >= @$sorted;
                my ($a, $r, $timestr, $quote, $title, $author, $type) = @{ $sorted->[$i] };

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

                # Pull the matches from the previous and clean up the strings
                foreach my $s (\$pre, \$timestr, \$post) {
                    $$s =~ s{<< (?<tb>[^|>]+) [|] (?<type> \d+ \w? (: \d)? ) >>}{$+{tb}}gx;
                    $$s =~ s{[\n\t]}{ }g;
                    $$s =~ s{\s\s+}{ }g;
                }

                my $award = $awards->{$author}{$title};
                die "No awards entry for '$author' '$title'"
                    unless defined $award;

                my ($type_str, $type_color) = ($type // '', 'bold green');
                if ($type_str =~ s{:(\d+)\z}{}) {
                    if ($1 eq '0') {
                        $type_color = 'bold red';
                    }
                }

                my ($s_auth, $s_title) = make_shorts($author, $title);

                my $w = $award ? "*" : '';
                $r //= defined $a ? ''  : 'E';
                $a   = defined $a ? 'A' : '';

                # Work out the size remaining
                my $fixed_size = 2 + 3 + 1 + 1 + 1 + 2 + 1 + 0 + 1 + 8 + 1 + 8;
                my $rem = $columns - $fixed_size - length($timestr);
                my $pre_len  = min(length($pre), int($rem / 2 + 0.5));
                my $post_len = $rem - $pre_len;
                $post .= ' 'x$columns;

                printf("  %s%3s%s %1s%1s%2s %s%s%s%s%s %s%8s%s %s%-8s%s\n",
                       color($type_color), $type_str // '', color('reset'),
                       $w, $a, $r,
                       elide($pre, $pre_len, {truncate => 'left', marker => '…'}),
                       color($type_color), $timestr, color('reset'),
                       elide($post, $post_len, {marker => '…'}),
                       color('bold blue'), elide($s_auth,  8, {marker => '…'}), color('reset'),
                       color('blue'),      elide($s_title, 8, {marker => '…'}), color('reset'),
                      );
            }
            print "            ..."
                if @$sorted > $limit;
            print "\n"
                if $print;
        }
    }

    return;
}


# Gets a hashref with author -> book -> num_awards
sub load_awards {
    # No args

    my %awards;

    my @files = glob("$ENV{HOME}/Calibre\\\ Library/*/*/metadata.opf")
    or die "Unable to find metadata files";
    foreach my $f (@files) {
        $f =~ m{\A \Q$ENV{HOME}/Calibre Library\E /
                   (?<author> .+?) /
                   (?<book> .+?) \s \(\d+\) /
                   metadata\.opf
                \z}xn
            or die "Bad metadata file '$f'";
        my ($author, $book) = @+{qw{ author book }};
        $book = shorten_book($book);

        die "No file '$f'" unless -f $f;
        my $c = read_binary($f);

        my ($content) = $c =~ m{ <meta \s+ name="calibre:user_metadata:\#awards"
                                \s+ content="([^"]+)" />
                               }x;
        $content = decode_json( XML::Entities::decode('all', $content) );
        my $awards = $content->{'#value#'};

        $awards{$author}{$book} = @$awards;
    }

    return \%awards;
}

sub sort_matches {
    my ($matches, $awards) = @_;

    my %rel_to_dist =
        (
         'E'  =>   0,
         '<<' => -20,
         '<'  => -10,
         '~'  => -20,
         '-'  => -10,
         '+'  => -20,
         '>'  => -10,
         '>>' => -20,
        );

    # Preprocess the rows
    my @processed;
    foreach my $m (@$matches) {
        my ($ampm, $rel, $timestr, $quote, $title, $author, $type) = @$m;
        my $exact = (not $ampm and not $rel) ? 1 : 0;
        my $award = $awards->{$author}{$title} // 0;

        my $distance = $rel_to_dist{$rel // 'E'}
            // die "No distance for '$rel'";

        $distance -= 5 if defined $ampm;

        my (undef, $match) = split /:/, $type;
        $match //= 1;

        push @processed, [$exact, $award, $distance, $match, $m];
    }

    my @sorted =
        (sort {
            # In order of preference:
            return
                #  - Match
                $b->[3] <=> $a->[3] ||

                #  - Exact time
                $b->[0] <=> $a->[0] ||

                #  - Distance
                $b->[2] <=> $a->[2] ||

                #  - Num awards
                $b->[1] <=> $a->[1] ||

                # The pointers themselves as a fallback
                $a cmp $b;
         }
         @processed);
    if (@processed > 5 and @processed < 10 and 0) {
        my @p = map { [ @{$_}[0..2], @{ $_->[4] }[0..2] ] } @processed;
        my @s = map { [ @{$_}[0..2], @{ $_->[4] }[0..2] ] } @sorted;
        DEBUG_MSG(\@p, \@s), exit;
    }


    return [ map { $_->[4] } @sorted ];
}

sub make_shorts {
    my ($author, $book) = @_;

    # Take the last word of the author, ignoring Jr. or Sr.
    $author =~ s{_}{}g;
    $author =~ s{\s+ \( [^)]+ \) \z}{}x;
    $author =~ m{(?<au> ( (von|van|de|du|st\.|saint|le|la) \s)* [-\w]+ ) ( \s (Jr | Sr) \. )? \z}xin
        or die "Can't shorten author '$author'";
    $author = $+{au};

    # Take the first meaningful word of the book
    $book =~ s{[_']}{}g;
    $book =~ s{\s+ \( [^)]+ \) \z}{}x;
    $book =~ m{\A ( (the|in|a|an|what|for|on) \s )* (?<bo> [-\w]+) }xin
      or die "Can't shorten book '$book'";
    $book = $+{bo};

    return($author, $book);
}

1;
