#!/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use Archive::Zip;
use Data::Dumper;
use File::Spec;
use XML::Entities;

use lib '.';

use TimeMatch;

exit main(@ARGV);

# For highlighting:
#  ./find_times.pl ~/Calibre\ Library/James\ Joyce/Dubliners\ \(3196\)/*epub | egrep -E '^|<<[^>]+(>>|$)|^[^<>]+>>'



sub main {
    my ($file) = @_;

    search_zip($file);

    return 0;
}


sub search_zip {
    my ($file) = @_;

    my $output_dump = 1;
    my @res;

    my $zip = Archive::Zip->new($file)
        or die "Unable to read zipfile '$file': $!";

    my (undef, undef, $basename) = File::Spec->splitpath($file);

    my $members_seen = 0;
    foreach my $member (sort {$a cmp $b} $zip->members()) {
        my $name = $member->fileName();
        next if $name !~ /\.([x]?html?|xml)$/;

        my $contents = $member->contents();
        utf8::decode($contents);

        next unless $contents =~ m{\A \Q<?xml \E [^>]+ [?]> \r?\n
                                   \Q<html \E
                                  }x;
        next unless $contents =~ m{content="text/html};

        my @lines = split m{</(?:p|div)>\R*}, $contents;
        foreach my $line (@lines) {
            ## First clean out html and turn to text
            $line =~ s{<(sup|h1|h2|h3) [^>/]+>.*?</\g1>}{}sgix;
            $line =~ s{<br [^>]+ /? >}{\n}sgix;
            $line =~ s{< /? [^>]+ >}{}sgix;
            $line = XML::Entities::decode('all', $line);

            $line = do_match($line);

            if ($line =~ /<</) {
                my ($time_bit) = $line =~ m{<< ([^|>]+) [|] \d+ \w? (:\d)? >>}x;
                push @res, [1, "$basename ($name) - $time_bit", $line];

                print $line, "\n\n"
                    unless $output_dump;
            }

        }
    }

    die "No members in '$file'"
        unless $members_seen;

    print Dumper \@res
        if $output_dump;

    return;
}
