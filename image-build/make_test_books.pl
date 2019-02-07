#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use lib '.';

use MultiProcessBooks;


my @sources =
    (
     "A. S. Byatt/Possession",
     "Anthony Burgess/A Clockwork Orange",
     "Arthur Conan Doyle/The Memoirs of Sherlock Holmes",
     "Arthur Ransome/Swallows and Amazons",
     "Charles Stross/The Apocalypse Codex",
     "Charles Dickens/A Tale of Two Cities",
     "Clifford Stoll/The Cuckoo's Egg_ Tracking a Spy Through the Maze of Computer Espionage",
     "Dashiell Hammett/The Maltese Falcon",
     "David Brin/Earth",
     "David Foster Wallace/Infinite Jest",
     "Douglas Adams/Dirk Gently's Holistic Detective Agency",
     "Evelyn Waugh/Brideshead Revisited",
     "Frank Herbert/Dune",
     "Graham Greene/The Quiet American",
     "Hunter S. Thompson/Fear and Loathing in Las Vegas",
     "Irvine Welsh/Trainspotting",
     "J. D. Salinger/The Catcher in the Rye",
     "J. R. R. Tolkien/The Fellowship of the Ring",
     "James Joyce/Ulysses",
     "John Steinbeck/The Grapes of Wrath",
     "Jules Verne/Around the World in Eighty Days",
     "Mark Haddon/The Curious Incident of the Dog in the Night-Time",
     "Michael Ondaatje/The English Patient",
     "Neal Stephenson/Cryptonomicon",
     "Paul Theroux/The Old Patagonian Express_ By Train Through the Americas",
     "Philip K. Dick/The VALIS Trilogy",
     "Robert A. Heinlein/Stranger in a Strange Land",
     "Roger Zelazny/Nine Princes in Amber",
     "Terry Pratchett/Making Money",
     "Thomas Pynchon/Gravity's Rainbow",
     "Umberto Eco/The Name of the Rose",
     "William Gibson/Neuromancer",
     "Winston S. Churchill/The Gathering Storm",
     "V. S. Naipaul/In a Free State",
    );

exit main(@ARGV);


sub main {
    my ($force, $which, $quiet) = handle_args(@_);

    my $mp = MultiProcessBooks->new(dir => 't/books');

    $mp->add_sources($force, $which, \@sources);

    $mp->run_jobs();

    return 0;
}

sub handle_args {
    my ($force) = @_;

    # See if they want to force everything or just a single item
    $force //= 0;
    my $which;
    if ($force and $force !~ /^\d+$/) {
        $which = $force;
        $force = 0;
    }

    return ($force, $which, 0);
}
