#!/bin/env perl

use Modern::Perl '2017';

use Parallel::ForkManager;
use Sys::Info;

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

my ($force) = @ARGV;

# See if they want to force everything or just a single item
$force //= 0;
my $which;
if ($force and $force !~ /^\d+$/) {
    $which = $force;
    $force = 0;
}

my %tasks;

my $pm = Parallel::ForkManager->new(get_num_tasks());
$pm->run_on_finish(
    sub {
        my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $res) = @_;

        # retrieve data structure from child
        if (defined($res)) {  # children are not forced to send anything
            $tasks{$ident}{dur} = $res->{dur};
        }
        else {  # problems occurring during storage or retrieval will throw a warning
            print qq|No message received from child process $pid!\n|;
        }

        # Kick off any remaining tasks
        start_jobs();
    });

my @work_queue;
SOURCE_LOOP:
foreach my $s (@sources) {
    my ($author, $book) = split m{/}, $s;
    (my $ob = $book) =~ s{_ .*}{};
    my $cmd = "./find_times.pl ~/\QCalibre Library\E/\Q$author\E/\Q$book (\E*\Q)\E/*epub" .
        " > t/books/\Q$author - $ob.dmp";

    my $do_skip = 0;
    if (-f "t/books/$author - $ob.dmp" and not $force and
        ( not $which or "$author - $ob" !~ /$which/i)
      )
    {
        $do_skip = 1;
    }

    $tasks{$s} =
        {do_skip  => $do_skip,
         author   => $author,
         book     => $book,
         ob       => $ob,
         dur      => $do_skip ? 0    : undef,
         start    => $do_skip ? time : undef,
         cmd      => $cmd,
        };

    next SOURCE_LOOP
        if $do_skip;

    push @work_queue, $s;
}

start_jobs();

foreach my $s (@sources) {
    my $i = $tasks{$s};

    my ($do_skip, $author, $book, $ob, )
        = @{$i}{qw{ do_skip author book ob }};

    my $what = $do_skip ? "Skipping" : "Processing";
    printf "%10.10s: %20.20s - %-50.50s  ...", $what, $author, $ob;
    STDOUT->flush();

    $i = wait_for_task($s)
        or die "No task info for '$s'";
    my $dur = $i->{dur};

    printf "\b\b\bDone [%3d secs]\n", $dur
        unless $do_skip;

    print "\b\b\b   \n"
        if $do_skip;
}

exit;

sub do_status {
    print "Done %3d   Running %3d   Waiting %3d\n";
}

sub start_jobs {
    # No args

    # Prime the work queue
    while (@work_queue and $pm->running_procs < $pm->max_procs) {
        start_job(shift @work_queue);
    }
}

sub start_job {
    my ($s) = @_;

    $pm->start($s)
        and return;

    my $start = time;

    system($tasks{$s}{cmd});

    my $dur = time - $start;

    $pm->finish($?, {dur => $dur});

    return;
}

sub wait_for_task {
    my ($s) = @_;

    # Loop waiting for the task to complete
    my $t;
  WAIT_LOOP:
    while (1) {
         $pm->reap_finished_children();

        $t = $tasks{$s}
            or die "No task '$s'";

        last WAIT_LOOP
            if defined $t->{dur};

         sleep 0.1;
    }

    return $t;
}

sub get_num_tasks {
    # No args

    my $info = Sys::Info->new;
    my $cpu  = $info->device('CPU');

    return $cpu->count();
}
