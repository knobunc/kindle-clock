#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

# If the line is shorter than this, add surrounding lines
use constant SHORT_LINE_LENGTH => 70;

use Archive::Zip;
use Data::Dumper;
use File::Spec;
use List::Util qw( min max );
use XML::Entities;

use lib '.';

use TimeMatch;

$Data::Dumper::Trailingcomma = 1;

# These are the allowed line lengths for books
my %safe_book =
    ('Edgar Allan Poe' =>
         {'The Works of Edgar Allan Poe, Volume 5' => 1},
     'Gene Wolfe' =>
         {'The Fifth Head of Cerberus'             => 1},
     'H. P. Lovecraft' =>
         {'The Horror at Red Hook'                 => 1},
     'Iris Murdoch' =>
         {'The Sandcastle'                         => 1},
     'John Irving' =>
         {'The World According to Garp'            => 1},
     'John Updike' =>
         {'The Widows of Eastwick'                 => 1},
     'Michael Bishop' =>
         {'No Enemy but Time'                      => 1},

     # The footnotes are ugly here... no good answer yet
     'Richard F. Burton' =>
         {'Personal Narrative of a Pilgrimage to '.
              'Al-Madinah and Meccah_ Volume 2'    => 1,
         },
     'Thomas More' =>
         {'Utopia'                                 => 1},
     'Truman Capote' =>
         {'In Cold Blood'                          => 1},
    );


exit main(@ARGV);

# For highlighting:
#  alias hl="egrep -E '^|<<[^>]+(>>|$)|^[^<>]+>>'"
#  ./find_times.pl ~/Calibre\ Library/James\ Joyce/Dubliners\ \(3196\)/*epub | hl


sub main {
    my ($file, $time_it) = @_;

    search_zip($file, $time_it);

    return 0;
}


sub search_zip {
    my ($file, $time_it) = @_;

    # Pull the author and title
    my ($author, $book) =
        $file =~ m{ /Calibre \s Library/ (?<a> [^/]+) / (?<b> [^/]+) / [^/]+.epub \z }xin
        or die "Unable to work out an author and book from '$file'";

    # Chop the calibre id
    (my $s_book = $book) =~ s{\s\(\d+\)\z}{};

    my $output_dump = 1;
    my @res;

    my $zip = Archive::Zip->new($file)
        or die "Unable to read zipfile '$file': $!";

    my (undef, undef, $basename) = File::Spec->splitpath($file);

    # Set to empty hash to time the regexes, or undef to cancel timing
    my $timing = $time_it ? {} : undef;

    my $members_seen = 0;
    my @members;
    foreach my $member (sort {$a->fileName() cmp $b->fileName()} $zip->members()) {
        my $name = $member->fileName();
        push @members, $name;
        next if $name !~ /\.([x]?html?|xml)$/;

        my $contents = $member->contents();
        utf8::decode($contents);

        next unless $contents =~ m{( \A \Q<?xml \E [^>]+ [?]> \R*
                                     ( <!DOCTYPE \s+ html ( \s+ [^>]+)?> \R* )?
                                     \Q<html \E
                                   | \Q<html xmlns="http://www.w3.org/1999/xhtml"\E
                                   )
                                  }x;
        next unless $contents =~ m{ content="(text/html|\Qhttp://www.w3.org/1999/xhtml\E)
                                  | \Q<meta content="application/xhtml+xml\E
                                  | <!DOCTYPE \s+ html \s+ PUBLIC
                                  | \Q<html \E
                                  }x;
        $members_seen = 1;

        # We only want the body
        if ($contents =~ m{<body(?:\s+[^>]+)?>(.+)</body>}s) {
            $contents = $1;
        } else {
            die "Unable to extract the body from '$name'";
        }

        # Split the lines
        my @raw_lines = split m{ ( </(?:pre|p|address|dl|ol|ul|li|dd|dt
                                     |hr|div|blockquote|h[1-6]|td|th
                                     )>
                                 | </span> \s* <br \s* /?>
                                 ) \R*
                               }xin, $contents;
        my @lines;
      LINE_LOOP:
        foreach my $line (@raw_lines) {
            ## First clean out html and turn to text
            $line =~ s{<(sup|h1|h2|h3) [^>/]+>.*?</\g1>}{}sgix;

            # Determine if are in something that is spacing sensitive
            # TODO: This really needs to be more clever and look at style sheets, but that's
            #       a major change
            my $fixed_formatting = 0;
            if ($line =~ s{\A \s* <pre (\s+ [^>]+)? >}{}xin) {
                # Handle pre blocks
                $fixed_formatting = 1;
            }

            # Nuke all line breaks
            $line =~ s{\R+}{ }g
                unless $fixed_formatting;

            # Turn brs into newlines
            $line =~ s{<br [^>]+ /? >}{\n}sgix;

            # Clean whitespace from the start and end of all lines
            $line =~ s{^  \s+  }{}xmg;
            $line =~ s{   \s+ $}{}xmg;

            # Turn it all to text
            $line =~ s{< /? [^>]+ >}{}sgix;
            $line = XML::Entities::decode('all', $line);

            # Kill consecutive horizontal whitespace
            $line =~ s{ \h{2,} }{ }xg
                unless $fixed_formatting;

            # Skip blank lines
            next LINE_LOOP
                if $line =~ m{\A \s* \z}xin;

            # See if the formatting is stupid and the paragraphs aren't reasonable sizes
            # (usually indicating that a line is a full chapter which means the book
            # is usually not great quality)
            if (not $safe_book{$author}{$s_book}) {
                my $len = length($line);
                die "Long line $len in '$author' '$book' '$name': ".substr($line, 0, 200)." ...\n"
                    if $len > 10_000 and
                        $line =~ /\R/ and
                        $line !~ m{PROJECT GUTENBERG LICENSE|Project Gutenberg eBooks are often created};
            }

            # Separate two newlines into separate lines
            push @lines, split m{ \R ( \h* \R )+ }x, $line;
        }

        for (my $i = 0; $i < @lines; $i++) {
            my $line = $lines[$i];


            # Actually do the match
            $line = do_match($line, undef, $author, $book, $timing);

            if ($line =~ m{<< ([^|>]+) [|] \d+ \w? (:\d)? >>}x) {
                # We had a match

                if (length($lines[$i]) < SHORT_LINE_LENGTH) {
                    # If the line is short, add in the surrounding lines
                    # And re-do the match
                    $line = $lines[$i];
                    $line = $lines[$i-1] . "\n$line" if $i > 0;
                    $line = "$line\n" . $lines[$i+1] if $i < $#lines;

                    $line = do_match($line, undef, $author, $book);
                }

                if (my ($time_bit) = $line =~ m{<< ([^|>]+) [|] \d+ \w? (:\d)? >>}x) {
                    # We can lose the match when we add context
                    my @times = extract_times("<<$time_bit|88>>")
                        or die "Unable to extract time from '$file' '$time_bit': $line";

                    my ($t) = split /: /, $times[0];

                    push @res, [1, "[$t] $basename ($name) - $time_bit", $line];

                    print $line, "\n\n"
                        unless $output_dump;
                }
            }

        }
    }

    die "No members in '$file'.  Saw: " . Dumper(\@members)
        unless $members_seen;

    print Dumper \@res
        if $output_dump and not $timing;

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

    return;
}
