#!/bin/env perl
use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use Lingua::LinkParser;
use Lingua::LinkParser::Definitions qw(define);
use Term::Size;

extend_definitions();

## This script demonstrates how to navigate a linkage using a word object.

my ($sent, $wpos) = @ARGV;

my $parser = new Lingua::LinkParser(verbosity => 0);

my $sentence = $parser->create_sentence($sent)
    or die "Can't parse '$sent'";
my $linkage  = $sentence->linkage(1)
    or die "Can't parse '$sent'";

$linkage->compute_union();

my @words = $linkage->words();
my %linktypes;
my $wnum = -1;
for my $word (@words) {
    $wnum++;
    print $word->text, ": ($wnum)\n"
        if 1;

    my @links = $word->links;
    foreach my $link (@links) {
        $link->{index} -= 1;

        my $dir = $wnum == $link->lword ? 'to' : 'from';
        print "  link type ", $link->linklabel, " $dir word ", $link->linkword, "\n"
            if 1;

#        dump_link($link);

        $linktypes{$link->linklabel} = 1;
    }
}

print "\n\n";

if (1) {
    my $l = $linkage->new_as_string();
    $l =~ s{\)}{)\n}g;
    $l =~ s{^\(\(}{(\n(}g;
    $l =~ s{\(}{ (}g;
    $l =~ s{^ }{};

    print $l;

    print "\n\n";
}

print $parser->get_diagram($linkage);

print "\n\n";

# See if the word is a time
my $is_timey = 0;
if (defined $wpos) {
    my $wnum = find_word_num($sent, $wpos)
        or die "Unable to find word '$wpos'";
    my $word = $words[$wnum]
        or die "No word at '$wnum'";

    print $word->text, ":\n"
        if 1;

    my @links = $word->links;
  LINK_LOOP:
    foreach my $link (@links) {
        $link->{index} -= 1;

        if ($link->linklabel =~ m{\A( J[spu] )\z}xn) {
            $is_timey = 1;
            last LINK_LOOP;
        }
    }
}

# Add the definitions
if (1) {
    my ($columns) = Term::Size::chars();
    foreach my $t (sort keys %linktypes) {
        my ($st, $ld) = define($t);
        ($st, $ld) = ('?', '?')
            unless $ld;
        $st =~ s{\s+\z}{};
        $ld =~ s{\s+\z}{};

        my $width = 9;
        $ld = split_line($ld, $width, $columns-$width);

        printf "%-2s: %-2s - %s\n", $t, $st, $ld;
    }
}


print $is_timey ? "TIMEY\n" : "NOT TIMEY\n";

exit;

sub split_phrase {
    my ($line) = @_;

    # Remove characters that don't seem to matter
    $line =~ s{["]}{ }g;

    # Add a space around special characters so they can split into different words
    $line =~ s{([-.!#$%&*()\[\]{}?+])/}{ $1 }g;

    # Clean the line
    $line = lc $line;
    $line =~ s{\s\s+}{ }g;
    $line =~ s{^\s+}{};
    $line =~ s{\s+$}{};

    my @words = split m{ }, $line;

    return @words;
}

sub find_word_num {
    my ($line, $word) = @_;

    $word = lc($word);
    my @words = split_phrase($line);

    my $loc = 0;
    foreach my $w (@words) {
        $loc++;
        return $loc
            if $w eq $word;
    }

    return undef;
}

sub split_line {
    my ($line, $offset, $width) = @_;

    my @lines = ("");
    foreach my $p ( split(/(\s+)/, $line) ) {
        if (length($lines[-1] . $p) > $width) {
            # Too long, make a new line
            push @lines, "";

            # If we made a new line, eat the whitespace between lines
            next if $p =~ /^\s+$/;
        }
        $lines[-1] .= $p;
    }

    my $rep = "\n" . " "x$offset;
    return join($rep, @lines);
}

sub dump_link {
    my ($link) = @_;

    printf "%20s: %s\n", "num_domains",  $link->num_domains;
    printf "%20s: %s\n", "domain_names", join("", $link->domain_names);
    printf "%20s: %s\n", "label",        $link->label  // '-';
    printf "%20s: %s\n", "llabel",       $link->llabel // '-';
    printf "%20s: %s\n", "rlabel",       $link->rlabel // '-';
    printf "%20s: %s\n", "lword",        $link->lword;
    printf "%20s: %s\n", "rword",        $link->rword;
    printf "%20s: %s\n", "length",       $link->length;
    printf "%20s: %s\n", "linklabel",    $link->linklabel;
    printf "%20s: %s\n", "linkword",     $link->linkword;
    printf "%20s: %s\n", "linkposition", $link->linkposition;
    print "\n";

    return;
}

sub extend_definitions {
    %Lingua::LinkParser::Definitions::SHORT_DEFS =
        (%Lingua::LinkParser::Definitions::SHORT_DEFS,
         IV => 'The IV link connnects to the main verbs of infinitive clauses. The goal of IV is to make the correspondance between link-grammar and traditional dependency grammars more concrete. IV always makes a cycle with the TO link, which identifies the start of the infinitive phrase.',
         WV => 'WV is used to attach the wall to the head-verb of the sentence. The goal of WV is to make the correspondance between link-grammar and traditional dependency grammars more concrete. WV always makes a cycle with the W link, which identifies the subject.',
        );

    return;
}
