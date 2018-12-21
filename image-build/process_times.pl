#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

# Force the XS parsers
BEGIN {
    $ENV{PERL_TEXT_CSV}     = 'Text::CSV_XS';
    $ENV{PERL_JSON_BACKEND} = 'JSON::XS';
}

use File::Slurper qw( read_binary );
use JSON;
use Text::CSV;
use XML::Entities;

use lib '.';

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

    my $awards = load_awards();
    my $times  = load_times($idir);

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
                my ($a, $r, undef, undef, $title, $author) = @$e;

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

            my $rs = join("  ", map({sprintf("%5d%s", $tc{$_}//0, $_)} @types));

            printf(">> %5s: %5dT  %5dA  %5dE  %5d*  %s\n",
                   $t, int(@{ $times->{$t} || [] }), $ap, $x, $w, $rs);

            my $sorted = sort_matches($ta, $awards);
            foreach my $i (0..9) {
                last if $i >= @$sorted;
                my ($a, $r, $timestr, $quote, $title, $author) = @{ $sorted->[$i] };
                $timestr =~ s{[\n\t]}{ }g;
                $timestr =~ s{\s\s+}{ }g;
                $timestr =~ s{^\s+}{};
                $timestr =~ s{\s+$}{};

                my $award = $awards->{$author}{$title};
                die "No awards entry for '$author' '$title'"
                    unless defined $award;

                my $w = $award ? "*" : '';
                $r //= defined $a ? ''  : 'E';
                $a   = defined $a ? 'A' : '';
                printf("      %1s%1s%2s %-37.37s -- %20.20s | %-20.20s\n",
                       $w, $a, $r, '"'.$timestr.'"', $author, $title);
            }
            print "            ...\n"
                if @$sorted > 10;
        }
    }

    return 0;
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
        my ($ampm, $rel, $timestr, $quote, $title, $author) = @$m;
        my $exact = (not $ampm and not $rel) ? 1 : 0;
        my $award = $awards->{$author}{$title} // 0;

        my $distance = $rel_to_dist{$rel // 'E'}
            // die "No distance for '$rel'";

        $distance -= 5 if defined $ampm;

        push @processed, [$exact, $award, $distance, $m];
    }

    my @sorted =
        (sort {
            # In order of preference:
            return
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
        my @p = map { [ @{$_}[0..2], @{ $_->[3] }[0..2] ] } @processed;
        my @s = map { [ @{$_}[0..2], @{ $_->[3] }[0..2] ] } @sorted;
        DEBUG_MSG(\@p, \@s), exit;
    }


    return [ map { $_->[3] } @sorted ];
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

# Gets a hashref with author -> book -> num_awards
sub load_awards {
    # No args

    my %awards;

    my @files = glob("/home/bbennett/Calibre\\\ Library/*/*/metadata.opf");
    foreach my $f (@files) {
        $f =~ m{\A \Q/home/bbennett/Calibre Library\E /
                   (?<author> .+?) /
                   (?<book> .+?) \s \(\d+\) /
                   metadata\.opf
                \z}xn
            or die "Bad metadata file '$f'";
        my ($author, $book) = @+{qw{ author book }};
        $book =~ s{_ .*}{};

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
