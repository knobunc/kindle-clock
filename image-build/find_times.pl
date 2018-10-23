#!/bin/env perl

use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';

use Archive::Zip;
use Data::Dumper;
use XML::Entities;

use lib '.';

use TimeMatch;

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

    foreach my $member (sort {$a cmp $b} $zip->members()) {
        my $name = $member->fileName();
        next if $name !~ /\.[x]?html$/;

        my $contents = $member->contents();
        utf8::decode($contents);
        my @lines = split /\n/, $contents;
        foreach my $line (@lines) {
            ## First clean out html and turn to text
            $line =~ s{< /? [^>]+ >}{}gx;
            $line = XML::Entities::decode('all', $line);

            $line = do_match($line);

            print $line, "\n\n"
                if $line =~ /<</;
        }
    }

    return;
}
