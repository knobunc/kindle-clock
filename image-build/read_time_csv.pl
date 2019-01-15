#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use String::Elide::Parts qw(elide);
use Term::ANSIColor qw( color colorstrip );
use Term::Size;
use Text::CSV;
use Text::Wrapper;

# Run it
exit main(@ARGV);

#####

sub main {
    my (@csv_files) = @_;
    die "Usage: $0 <csv_files...>\n"
        unless @csv_files;

    my $csv = Text::CSV->new(
        { binary => 1, sep_char => '|', strict => 1, quote_space => 0, eol => $/ }
        )
        or die "Cannot use CSV: ".Text::CSV->error_diag ();

    foreach my $csv_file (@csv_files) {
        my $fh = IO::File->new($csv_file, '<:encoding(utf8)')
            or die "Can't read '$csv_file': $!";

        my @lines;
        while (my $row = $csv->getline($fh)) {
            my ($time, $timestr, $quote, $title, $author) = @$row;
            push @lines, [$time, $timestr, $quote, $title, $author];
        }

        @lines = sort {substr($a->[0], -5) cmp substr($b->[0], -5)} @lines;

        foreach my $line (@lines) {
            print_line(@$line);
        }
    }

    return 0;
}

sub print_line {
    my ($time, $timestr, $quote, $title, $author) = @_;

    my ($columns) = Term::Size::chars();
    my $tw = 10;
    my $aw = 30;
    my $sw = $columns - $tw - 2 - $aw - 3;

    printf("%s%${tw}s%s: %s%${aw}s%s - %s%-${sw}s%s\n",
           color('bold blue'),  $time,               color('reset'),
           color('bold green'), elide($author, $aw), color('reset'),
           color('bold cyan'),  elide($title,  $sw), color('reset'),
          );

    $quote =~ s{(\Q$timestr\E)}{color('bold red') . $1 . color('reset')}e;

    my $indent  = ' 'x4;
    my $wrapper = Text::Wrapper->new(columns    => $columns-2,
                                     par_start  => $indent,
                                     body_start => $indent);
    print $wrapper->wrap($quote), "\n";

    return;
}
