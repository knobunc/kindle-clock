#!/bin/env perl

use Modern::Perl '2017';

use Data::Dumper;
use File::Find;
use Parallel::ForkManager;
use Sys::Info;

use utf8;
use open ':std', ':encoding(UTF-8)';

my $basedir = "/home/bbennett/Calibre Library/";


my ($force) = @ARGV;

# See if they want to force everything or just a single item
$force //= 0;
my $which;
if ($force and $force !~ /^\d+$/) {
    $which = $force;
    $force = 0;
}

my %tasks;
my $printed = 0;

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

my @sources = load_books();

my @work_queue;
SOURCE_LOOP:
foreach my $s (@sources) {
    my ($author, $book) = split m{/}, $s
        or die "Unable to process '$s'";

    (my $ob = $book) =~ s{_ .*}{};
    my $cmd = "./find_times.pl ~/\QCalibre Library\E/\Q$author\E/\Q$book (\E*\Q)\E/*epub" .
        " > books/\Q$author - $ob.dmp";

    my $do_skip = 0;
    my $file = "books/$author - $ob.dmp";
    if (-f $file and not -z $file and not $force and
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
         started  => 0,
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
    printf "%10.10s: %20.20s - %-45.45s  ", $what, $author, $ob;
    STDOUT->flush();

    $i = wait_for_task($s)
        or die "No task info for '$s'";
    my $dur = $i->{dur};

    clear_status();

    printf "Done [%3d secs]\n", $dur
        unless $do_skip;

    print "\n"
        if $do_skip;
}

exit;

sub start_jobs {
    # No args

    # Prime the work queue
    while (@work_queue and $pm->running_procs < $pm->max_procs) {
        start_job(shift @work_queue);
    }
}

sub start_job {
    my ($s) = @_;

    $tasks{$s}{started} = 1;

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

         # Update the status line
         print_status($s);

         sleep 0.1;
    }

    return $t;
}

sub clear_status {
    print "\b"x$printed;
    print  " "x$printed;
    print "\b"x$printed;

    $printed = 0;

    return;
}

sub print_status {
    my ($cur_task) = @_;

    my $str = "";
    foreach my $s (sort keys %tasks) {
        next unless $s ge $cur_task;
        my $t = $tasks{$s};

        # Ignore ones we are skipping
        next if $t->{do_skip};

        # Ignore ones we haven't started
        next if not $t->{started};

        # Add an o for running and a . for done
        $str .= defined $t->{dur} ? '.' : 'o';
    }

    clear_status();
    print $str;
    STDOUT->flush();

    $printed = length($str);

    return;
}

sub get_num_tasks {
    # No args

    my $info = Sys::Info->new;
    my $cpu  = $info->device('CPU');

    return $cpu->count();
}

sub load_books {
    my () = @_;
    my @dirs;

    my $wanted = sub {
        my ($dev,$ino,$mode,$nlink,$uid,$gid);

        if ((($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) and
            -f _ and
            /^.*epub\z/s)
        {
            my $dir = $File::Find::dir;

            $dir =~ s{\A\Q$basedir\E}{};
            $dir =~ s{ \(\d+\)\Z}{};

            push @dirs, $dir;
        }

    };

    File::Find::find({wanted => $wanted, no_chdir => 1}, $basedir);

    return sort @dirs;
}
