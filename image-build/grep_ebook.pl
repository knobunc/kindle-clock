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


sub main {
    my ($re_str, @files) = @_;

    my $re = qr{$re_str};

    foreach my $file (@files) {
        search_zip($re, $file);
    }

    return 0;
}


sub search_zip {
    my ($re, $file) = @_;

    my $zip = Archive::Zip->new($file)
        or die "Unable to read zipfile '$file': $!";

    my (undef, undef, $basename) = File::Spec->splitpath($file);

    foreach my $member (sort {$a cmp $b} $zip->members()) {
        my $name = $member->fileName();
        next if $name !~ /\.[x]?html?$/;

        my $contents = $member->contents();
        utf8::decode($contents);
        my @lines = split m{</(?:p|div)>\R*}, $contents;
        foreach my $line (@lines) {
            ## First clean out html and turn to text
            $line =~ s{<sup [^>/]+>.*?</sup>}{}gx;
            $line =~ s{<br [^>]+ /? >}{\n}gx;
            $line =~ s{< /? [^>]+ >}{}gx;
            $line = XML::Entities::decode('all', $line);

            if ($line =~ $re) {
                print $line, "\n\n";
            }

        }
    }

    return;
}
