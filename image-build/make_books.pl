#!/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

my @sources =
    (
     "Anthony Burgess/A Clockwork Orange",
     "Arthur Conan Doyle/The Memoirs of Sherlock Holmes",
     "Arthur Ransome/Swallows and Amazons",
     "Charles Stross/The Apocalypse Codex",
     "Charles Dickens/A Tale of Two Cities",
     "Clifford Stoll/The Cuckoo's Egg_ Tracking a Spy Through the Maze of Computer Espionage",
     "Dashiell Hammett/The Maltese Falcon",
     "David Brin/Earth",
     "Evelyn Waugh/Brideshead Revisited",
     "Frank Herbert/Dune",
     "Graham Greene/The Quiet American",
     "Hunter S. Thompson/Fear and Loathing in Las Vegas",
     "Irvine Welsh/Trainspotting",
     "J. D. Salinger/The Catcher in the Rye",
     "J. R. R. Tolkien/The Fellowship of the Ring",
     "James Joyce/Ulysses",
     "John Steinbeck/The Grapes of Wrath",
     "Mark Haddon/The Curious Incident of the Dog in the Night-Time",
     "Michael Ondaatje/The English Patient",
     "Neal Stephenson/Cryptonomicon",
     "Paul Theroux/The Old Patagonian Express_ By Train Through the Americas",
     "Philip K. Dick/The VALIS Trilogy",
     "Robert A. Heinlein/Stranger in a Strange Land",
     "Roger Zelazny/Nine Princes in Amber",
     "Terry Pratchett/Making Money",
     "Umberto Eco/The Name of the Rose",
     "William Gibson/Neuromancer",
     "Winston S. Churchill/The Gathering Storm",
     "V. S. Naipaul/In a Free State",
    );

my ($force) = @ARGV;

$force //= 0;
my $which;
if ($force and $force !~ /^\d+$/) {
    $which = $force;
    $force = 0;
}

foreach my $s (@sources) {
    my ($author, $book) = split m{/}, $s;
    (my $ob = $book) =~ s{_ .*}{};
    my $cmd = "./find_times.pl ~/\QCalibre Library\E/\Q$author\E/\Q$book (\E*\Q)\E/*epub" .
        " > t/books/\Q$author - $ob.dmp";

    my $start = time;
    my $what = "Processing";
    my $do_skip = 0;
    if (-f "t/books/$author - $ob.dmp" and not $force and
        ( not $which or "$author - $ob" !~ /$which/i)
       )
    {
        $what = "Skipping";
        $do_skip = 1;
    }

    printf "%10s: %30s - %-30s ...", $what, $author, $ob;
    system ($cmd)
        unless $do_skip;

    my $dur = time - $start;
    printf "\b\b\bDone [%3d secs]\n", $dur
        unless $do_skip;

    print "\b\b\b   \n"
        if $do_skip;
}
