package Process;

use Modern::Perl '2017';

use utf8;

# Force the XS parsers
BEGIN {
    $ENV{PERL_JSON_BACKEND} = 'JSON::XS';
}

use Exporter::Easy (
  EXPORT => [ qw( print_matches) ],
);

use Carp;
use File::Slurper qw( read_binary );
use JSON;
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
                $timestr =~ s{[\n\t]}{ }g;
                $timestr =~ s{\s\s+}{ }g;
                $timestr =~ s{^\s+}{};
                $timestr =~ s{\s+$}{};

                my $award = $awards->{$author}{$title};
                die "No awards entry for '$author' '$title'"
                    unless defined $award;

                my ($type_str, $type_col) = ($type // '', 'bold green');
                if ($type_str =~ s{:(\d+)\z}{}) {
                    if ($1 eq '0') {
                        $type_col = 'bold red';
                    }
                }

                my $w = $award ? "*" : '';
                $r //= defined $a ? ''  : 'E';
                $a   = defined $a ? 'A' : '';
                printf("  %s%3s%s %1s%1s%2s %-37.37s %20.20s | %-20.30s\n",
                       color($type_col), $type_str // '', color('reset'),
                       $w, $a, $r, elide('"'.$timestr.'"', 37), $author, $title);
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

1;
