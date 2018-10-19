#!/bin/env perl

use strict;
use warnings;

use Archive::Zip;
use Data::Dumper;
use XML::Entities;

exit main(@ARGV);

sub main {
    my ($file) = @_;

    search_zip($file);

    return 0;
}


sub search_zip {
    my ($file) = @_;

    my $zip = Archive::Zip->new($file)
        or die "Unable to read zipfile '$file': $!";

    foreach my $member ($zip->members()) {
        my $name = $member->fileName();
        next if $name !~ /\.xhtml$/;

        my $contents = $member->contents();
        my @lines = split /\n/, $contents;
        foreach my $line (@lines) {
            ## First clean out html and turn to text
            $line =~ s{< /? [^>]+ >}{}gx;
            $line = XML::Entities::decode('all', $line);

            ## Now do the matches

            # Simple times
            $line =~ s{ \b (\d{1,2}:\d{1,2}) \b }{<<$1>>}xgi;

            # O'Clocks
            $line =~ s{ \b (\d{1,2} \s+ o(?:'|’)?clock) \b }{<<$1>>}xgi;

            # Relative times
#            $line =~ s{ \b ( (?: at | after | before ) \s+ \d{1,2}) \b }{<<$1>>}xgi;

            print $line, "\n\n"
                if $line =~ /<</;
        }
    }

    return;
}
