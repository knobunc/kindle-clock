#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

# If the line is shorter than this, add surrounding lines
use constant SHORT_LINE_LENGTH => 70;

use Archive::Zip;
use Data::Dumper;
use File::Spec;
use XML::Entities;

use lib '.';

use TimeMatch;

$Data::Dumper::Trailingcomma = 1;

# These are the allowed line lengths for books
my %book_len =
    ('David Foster Wallace' =>
         {'Brief Interviews With Hideous Men_ Stories' => 20_000,
          'Infinite Jest'                              => 50_000, # He's wordy :-)
         },
     'David Peace' =>
         {'Occupied City'                              => 12_000},
    );

# Whether to split on something else
my %book_split =
    ('Edgar Allan Poe' =>
         {'The Works of Edgar Allan Poe, Volume 5' => qr{<br/><br/>}i},
     'Gene Wolfe' =>
         {'The Fifth Head of Cerberus'             => qr{<br class="calibre12"/>}i},
     'H. P. Lovecraft' =>
         {'The Horror at Red Hook'                 => qr{<br/>}i},
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
        my $book_split = $book_split{$author}{$s_book} // qr{(*FAIL)};
        my @raw_lines = split m{ ( </(?:pre|p|address|dl|ol|ul|li|dd|dt
                                     |hr|div|blockquote|h[1-6]|td|th
                                     )>
                                 | </span> \s* <br \s* /?>
                                 | $book_split
                                 ) \R*
                               }xin, $contents;
        my @lines;
      LINE_LOOP:
        foreach my $line (@raw_lines) {
            # Skip blank lines
            next LINE_LOOP
                if $line =~ m{\A \s* \z}xin;

            ## First clean out html and turn to text
            $line =~ s{<(sup|h1|h2|h3) [^>/]+>.*?</\g1>}{}sgix;
            $line =~ s{<br [^>]+ /? > \R* }{\n}sgix;
            $line =~ s{< /? [^>]+ >}{}sgix;
            $line = XML::Entities::decode('all', $line);

            # Clean whitespace from the end of all lines
            $line =~ s{ \s+ $}{}xmg;

            # Remove whitespace from the start of the first line and measure the length.
            # Then remove up to that many spaces from the next line.
            $line =~ s{\A ( \s+ ) }{}x;
            if ( my $ws_len = length($1) ) {
                if ($ws_len < 100) {
                    $line =~ s{^ \s{0,$ws_len} }{}xmg;
                }
                else {
                    $line =~ s{^ \s+ }{}xmg;
                }
            }

            # See if the formatting is stupid and the paragraphs aren't reasonable sizes
            # (usually indicating that a line is a full chapter)
            my $len = length($line);
            my $max_len = $book_len{$author}{$s_book} // 10_000;

            die "Long line $len in '$author' '$book' '$name': ".substr($line, 0, 200)."\n"
                if $len > $max_len and
                   $line =~ /\R/ and
                   $line !~ m{PROJECT GUTENBERG LICENSE|Project Gutenberg eBooks are often created};

            push @lines, $line;
        }

        for (my $i = 0; $i < @lines; $i++) {
            my $line = $lines[$i];

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
