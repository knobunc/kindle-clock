#!/bin/env perl

use strict;
use warnings;

use utf8;
use open ':std', ':encoding(UTF-8)';

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


    # Numbers 1-9 as words
    my $low_num_re = qr{ one | two | three | four | five | six | seven | eight | nine }xi;

    # The hours 1-12 as words
    my $hour_word_re = qr{ $low_num_re | ten | eleven | twelve | noon | midnight }xi;

    # The minutes
    my $min_word_re =
        qr{ # 1-9
            (?: oh [\s-] | \b )? $low_num_re
          | # 10-19
            ( ten | eleven | twelve | thirteen | fourteen | fifteen |
              sixteen | seventeen | eighteen | nineteen)
          | # 20-59
            (?: twenty | thirty | forty | fifty ) (?: - $low_num_re )?
          }xi;

    # Hour digits
    my $hour_dig_re = qr{ [01]?\d | 2[0-4] }xi;
    
    # Min / sec digits
    my $minsec_dig_re = qr{ [0-5]?\d | 60 }xi;
    
    # The hours as words or numbers
    my $hour_re = qr{ $hour_dig_re | $hour_word_re }xi;

    # The am / pm permutations
    my $ampm_re = qr{ [ap]m \b | [ap][.] \s* m[.] }xi;

    # Boundary after
    my $ba_re = qr{ \b | (?= \W ) | \z }xi;
    

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

            # 2300h, 23.00h, 2300 hrs, 2300z
            $line =~ s{ \b ( $hour_dig_re [.:]? $minsec_dig_re (?: : $minsec_dig_re )? (?: h | z | \s* hrs ) ) $ba_re }{<<$1>>}xgi;

            # Simple times
            # 12:37
            $line =~ s{ \b ( $hour_dig_re : $minsec_dig_re (?: : $minsec_dig_re )? (?: \s* $ampm_re )? ) $ba_re }{<<$1>>}xgi;

            # Untrustworthy times... need an indication that it is a time, not just some number
            # at 1237, to 1237, is 1237, was 1237, by 1237
            $line =~ s{ \b (?: at | to | is | was | by ) \s+ ( \d{1,2} [.]? \d\d ) $ba_re }{<<$1>>}xgi;
            # 11.32 pm
            $line =~ s{ \b ( $hour_dig_re [.]? $minsec_dig_re [.]? $minsec_dig_re? \s* $ampm_re ) $ba_re }{<<$1>>}xgi;
	
	    # Word times
	    # eleven fifty-six
	    $line =~ s{ \b ( $hour_re [\s.-]+ $min_word_re (?: $ampm_re )?) $ba_re }{<<$1>>}xgi;

	    # O'Clocks
	    # 1 o'clock
	    $line =~ s{ \b ( $hour_re [?]? \s+ o(?: ['’] \s* | f \s+ the \s+ )?clock ) $ba_re }
	              {<<$1>>}xgi;

	    # PMs
	    # 1 pm, one p.m.
	    $line =~ s{ \b ( $hour_re [?]? \s* $ampm_re ) $ba_re }{<<$1>>}xgi;
	    # three in the morning
	    $line =~ s{ \b ( $hour_re [?]? \s+ in \s+ the \s+ (?: morning | afternoon ) ) $ba_re }{<<$1>>}xgi;
	
	    # Relative times
	    $line =~ s{ \b ( (?: at | after | before | about | by | until 
			      | upon | till | around | nearly ) \s+
			     (?: \w+ \s+ )?
			     $hour_re ) $ba_re }{<<$1>>}xgi;

	    # Times to/from hour
	    # 5 minutes to midnight, ten minutes past noon
	    $line =~ s{ \b ( (?: (?: \b $min_word_re | \d{1,2} | A ) (?: \s+ | - ) 
			      (?: minute s? \s+ )?
			      (?: and \s+ (?: a \s+ half | a \s+ quarter 
                                           | $min_word_re \s+ second s? )? \s+ )?
			      (?: minute s? \s+ )?
			      | (?: (?: half | quarter | three \s+ quarters ) (?: \s+ | - ) )
			      | (?: just | nearly )
			     )
			     (?: to | past | of ) [\s-]+
			     $hour_re $ampm_re? ) $ba_re }{<<$1>>}xgi;
	    
	    # Struck / strikes
	    $line =~ s{ \b (?: clock | bell ) s? \s+ [\w\s]* 
			    (?: struck | strikes | striking | strike | striketh |
			     beat   | beats   | beating ) \s+ 
			    ( $hour_dig_re_re | thirteen ) $ba_re }
	              {<<$1>>}xgi;
	    $line =~ s{ \b stroke \s+ of \s+ ( $hour_re | thirteen ) $ba_re }
	              {<<$1>>}xgi;
	    
	    # Noon / midnight
	    $line =~ s{ \b ( noon | noonday | midnight ) $ba_re }{<<$1>>}xgi;
	    
            print $line, "\n\n"
                if $line =~ /<</;
        }
    }

    return;
}
