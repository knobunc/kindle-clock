package MultiProcessBooks;

use Modern::Perl '2017';

use utf8;

use Exporter::Easy (
  EXPORT => [ qw( DEBUG_MSG ) ],
);

use Archive::Zip;
use Capture::Tiny qw( :all );
use Carp;
use Data::Dumper;
use File::Slurper qw( write_binary );
use List::Util qw( sum min max );
use Parallel::ForkManager;
use Sys::Info;
use String::Elide::Parts qw(elide);
use Term::ANSIColor qw( color colorstrip );
use Term::Size;
use Text::Wrapper;
use Time::HiRes qw( time );

use lib '.';

use TimeMatch;


sub new {
    my ($class, %args) = @_;

    my $self =
        {dir        => ( $args{dir}     // croak "Missing arg dir" ),
         num_tasks  => $args{num_tasks} || get_num_tasks(),
         quiet      => $args{quiet}     || 0,
         pm         => undef,
         tasks      => {},
         task_order => [],
         queue      => [],
         printed    => 0,
         run_start  => undef,
         display    => { what   => 7,
                         author => 18,
                         book   => 0,   # Set later
                         size   => 7,
                         status => 26,
                         FIXED  => 8,   # The number of fixed chars in the string
                       },
        };
    bless($self, $class);

    $self->{pm} = Parallel::ForkManager->new( $self->{num_tasks} );
    $self->{pm}->run_on_finish(
        sub {
            my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $res) = @_;

            # retrieve data structure from child
            if (defined($res)) {  # children are not forced to send anything
                my $t = $self->get_task($ident);
                $t->{dur}    = $res->{dur};
                $t->{exit}   = $exit_code > 0 ? $exit_code : $res->{exit};
                $t->{stderr} = $res->{stderr};
            }
            else {  # problems occurring during storage or retrieval will throw a warning
                print qq|No message received from child process $pid!\n|;
            }

            # Kick off any remaining tasks
            $self->start_jobs();
        });


    # Set up the display stuff
    my ($columns) = Term::Size::chars();
    my $d = $self->{display};
    $d->{book} = $columns - sum(values %$d);
    $d->{book} = 15 if $d->{book} < 15;

    return $self;
}


sub get_num_tasks {
    # No args

    my $info = Sys::Info->new;
    my $cpu  = $info->device('CPU');

    my $num = $cpu->count();

    $num = 1 if $num < 1;

    return $num;
}

sub get_task {
    my ($self, $s) = @_;

    my $t = $self->{tasks}{$s}
        or croak "No task '$s'";

    return $t;
}

sub start_jobs {
    my ($self) = @_;

    # Prime the work queue
    my $pm = $self->{pm};
    while (@{ $self->{queue} } and $pm->running_procs < $pm->max_procs) {
        $self->start_job(shift @{ $self->{queue} });
    }

    return;
}

sub start_job {
    my ($self, $s) = @_;

    $self->get_task($s)->{started} = time;

    my $pm = $self->{pm};
    $pm->start($s)
        and return;

    my $start = time;

    # Run the task
    my ($exit, $stderr) = $self->get_task($s)->{code}->();

    my $dur = time - $start;

    $pm->finish($exit, {dur => $dur, stderr => $stderr, exit => $exit});

    return;
}

sub wait_for_task {
    my ($self, $s) = @_;

    # Loop waiting for the task to complete
    my $t;
  WAIT_LOOP:
    while (1) {
        $self->{pm}->reap_finished_children();

        $t = $self->get_task($s)
            or die "No task '$s'";

        last WAIT_LOOP
            if defined $t->{dur};

         # Update the status line
         $self->print_status($s);

         sleep 0.1;
    }

    return $t;
}

sub _print_status {
    my ($self, $str) = @_;

    my $printed = $self->{printed};

    print "\b"x$printed;
    print  " "x$printed;
    print "\b"x$printed;

    print $str;

    STDOUT->flush();

    # If this was the end of the line, there's no status length
    $self->{printed} = $str =~ /\R\z/ ? 0 : length(colorstrip($str));

    return;
}

sub print_task_start {
    my ($self, $task_name) = @_;

    my $i = $self->get_task($task_name);

    return if $self->{quiet} and $i->{skip};

    my ($skip, $author, $book, $size )
        = @{$i}{qw{ skip author book size }};

    my $d = $self->{display};

    if ($size == 0) {
        $size = '';
    }
    else {
        $size = int($size / 1000) . 'k';
    }

    my ($what, $wcolor) = $skip ? ("Skip", "yellow") : ("Process", "bold green");
    my $acolor = "bold blue";
    my $bcolor = "bold blue";
    my ($w, $a, $b, $s) = map { "$_.$_" } @{$d}{qw( what author book size )};
    printf("%s%${w}s%s: %s%${a}s%s - %s%-${b}s%s%${s}s ",
           color($wcolor), $what,                        color('reset'),
           color($acolor), elide($author, $d->{author}), color('reset'),
           color($bcolor), elide($book,   $d->{book}  ), color('reset'),
                           elide($size,   $d->{size}  ),
          );
    STDOUT->flush();

    return;
}

sub print_task_end {
    my ($self, $task_name) = @_;

    my $i = $self->get_task($task_name);

    return if $self->{quiet} and $i->{skip};

    my $status = "";
    my $err    = "";
    if (not $i->{skip}) {
        if ($i->{exit} == 0) {
            $status = sprintf(" %sDone%s: %s%3ds%s  %6.2fk/s",
                              color('bold green'),            color('reset'),
                              color('bold blue'),  $i->{dur}, color('reset'),
                              $i->{size} / $i->{dur} / 1000 );
        }
        else {
            $status = sprintf(" %sFAILED%s", color('bold red'), color('reset'));
            $err    = $i->{stderr} // '';
            $err    =~ s{\R*\z}{\n\n};
        }
    }


    my $pad = $self->{display}{status} - length(colorstrip($status));

    $self->_print_status(" "x$pad . $status . "\n" . $err);

    return;
}

sub set_title {
    my ($title) = @_;

    printf("\033]0;%s\007", $title);

    return;
}

sub get_icon {
    my ($dur, $done) = @_;

    my @blocks = (qw( _ ▁ ▂ ▃ ▄ ▅ ▆ ▇ ▉ ! ));
    my $bl = @blocks - 1;

    my $l = int($dur / 10);
    $l = $bl if $l > $bl;

    my $color;
    if ($done) {
        $color = "green";
    }
    else {
        $color = "bold red";
    }

    return color($color).$blocks[$l].color('reset');
}

sub print_status {
    my ($self, $cur_task) = @_;

    my $short_count = 0;
    my $long_count  = 0;
    my $done_count  = 0;

    my $time = time;

    my $found = 0;
    my @tasks;
    foreach my $s (@{ $self->{task_order} }) {
        $found = 1 if $s eq $cur_task;
        next unless $found;

        my $t = $self->get_task($s);

        # Ignore ones we are skipping
        next if $t->{skip};

        # Ignore ones we haven't started
        my $start = $t->{started};
        next if not defined $start;

        # Add a . for done, or a number indicating tens of seconds of runtime, or ! if > 100s
        my ($dur, $done);
        if (defined $t->{dur}) {
            $done = 1;
            $dur = $t->{dur};
            $done_count++;
        }
        else {
            $done = 0;
            $dur = $time - $start;
            if ($dur < 30) {
                $short_count++;
            }
            else {
                $long_count++;
            }
        }
        push @tasks, get_icon($dur, $done);
    }

    my $len = $self->{display}{status} - 1;

    # Pad out the tasks if needed
    if (@tasks < $len) {
        push @tasks, (' ')x($len-@tasks);
    }
    elsif (@tasks > $len) {
        # We got too big, flip the display
        @tasks = ();

        $tasks[0] = sprintf("%s%ds+%dl%s &%s %dd%s",
                            color('bold red'),   $short_count,  $long_count, color('reset'),
                            color('bold green'), $done_count,                color('reset'),
                           );

        my $pad = $len - length(colorstrip($tasks[0]));
        $tasks[0] .= " "x$pad
            if $pad > 0;
    }
    my $str = join '', @tasks;

    my @bc = (color('bold blue'), color('reset'));
    my $status = sprintf("%s[%s%s%s]%s", @bc, $str, @bc);
    $self->_print_status($status);

    ### Update the title
    my ($done, $run, $rem, $lapsed, $est_end) = $self->eta($cur_task);

    set_title(sprintf("%d done, %d running, %d remaining.  ETA %s / %s",
                      $done, $run, $rem, fmt_min($lapsed), fmt_min($est_end)));

    return;
}

sub eta {
    my ($self, $cur_task) = @_;

    my $tasks = $self->{num_tasks};

    my $init      = 0;
    my $done      = 0;
    my $run       = 0;
    my $rem       = 0;
    my $done_size = 0;
    my $done_time = 0;
    my $run_size  = 0;
    my $run_time  = 0;
    my $rem_size  = 0;

    my $time = time;

    foreach my $s (@{ $self->{task_order} }) {
        my $t = $self->get_task($s);

        # Ignore ones we are skipping
        next if $t->{skip};

        # Ignore ones we haven't started
        my $start = $t->{started};
        if (not defined $start) {
            # Pending tasks
            $rem++;
            $rem_size += $t->{size} / 1000;
        }
        elsif (defined $t->{dur}) {
            # Ignore ones that errored
            next if $t->{exit} != 0;

            # Finished tasks
            $done++;
            $done_time += $t->{dur};
            $done_size += $t->{size} / 1000;
        }
        else {
            # Running tasks
            $run++;
            $run_time += $time - $start;
            $run_size += $t->{size} / 1000;
        }
    }

    ## Compute the ETA
    # Compute the average rate, or estimate if we don't have enough data yet
    my $guess_rate = 60;
    if ($done >= 2) {
        $guess_rate = $done_size / $done_time;
    }

    # Use the rate time to estimate the remaining time (minus the time the current tasks have run)
    # But we can't end in less than 1 second
    my $est_time = ($run_size + $rem_size) / $guess_rate - $run_time;
    $est_time  /= min( ($run + $rem),  $tasks)
        if $run + $rem;
    $est_time = max($est_time, 1);

    my $lapsed   = time - $self->{run_start};
    my $tot_time = $lapsed + $est_time;

    return ($done+$init, $run, $rem, $lapsed, $tot_time);
}

sub fmt_min {
    my ($sec) = @_;

    my $min = int($sec) / 60;
    $sec   %= 60;
    return sprintf("%d:%02d", $min, $sec);
}

sub run_jobs {
    my ($self) = @_;

    # Estimate all book sizes
    foreach my $t (@{ $self->{task_order} }) {
        $self->estimate_size($t);
    }

    # Log the start time so we can calculate an ETA
    $self->{run_start} = time;

    $self->start_jobs();

    foreach my $t (@{ $self->{task_order} }) {
        $self->print_task_start($t);
        $self->wait_for_task($t);
        $self->print_task_end($t);
    }

    return;
}

sub estimate_size {
    my ($self, $task_name) = @_;

    my $task = $self->get_task($task_name);

    return if $task->{skip};

    my $author = $task->{author};
    my $book   = $task->{book};
    my ($file) = glob("~/\QCalibre Library\E/\Q$author\E/\Q$book\E*\Q (\E*\Q)\E/*epub")
    or die "Unable to find file for '$author' '$book'";

    my $zip = Archive::Zip->new($file)
        or die "Unable to read zipfile '$file': $!";

    my $size = 0;
    foreach my $member (sort {$a->fileName() cmp $b->fileName()} $zip->members()) {
    my $name = $member->fileName();
    next if $name !~ /\.([x]?html?|xml)$/;

    $size += $member->uncompressedSize();
    }

    $task->{size} = $size;

    return;
}

sub add_task {
    my ($self, $task_name, %args) = @_;

    my @av = qw( skip author book code );
    foreach my $a (@av) {
        croak "Missing arg '$a'"
            unless defined $args{$a};
    }
    croak "Extra args" if keys %args != @av;

    push @{ $self->{task_order} }, $task_name;
    push @{ $self->{queue}      }, $task_name
        unless $args{skip};

    $self->{tasks}{$task_name} =
        {skip     => $args{skip},
         author   => $args{author},
         book     => $args{book},
         code     => $args{code},

         dur      => $args{skip} ? 0    : undef,
         started  => undef,
         size     => 0,                 # Filled in by estimate later
        };

    return;
}


sub add_sources {
    my ($self, $force, $which, $sources) = @_;

    my $dir = $self->{dir};

  SOURCE_LOOP:
    foreach my $s (@$sources) {
        my ($author, $book) = split m{/}, $s
            or die "Unable to process '$s'";

        # Shorten the book by lopping at _s unless there are duplicates because of that
        my $ob = shorten_book($book);

        # Find the matching file
        my ($source_file) =
            grep m{ / \Q$author\E / \Q$book\E \s \( \d+ \)/ [^/]+ \. epub \z}xn,
            glob "~/\QCalibre Library\E/\Q$author\E/\Q$book (\E*\Q)\E/*epub";
        die "Unable to find a match for '$author' '$book'"
            unless $source_file;

        # And this is where to write the output
        my $dest_file = "$dir/$author - $ob.dmp";

        # Put the code to run for the task together
        my $code =
            sub {
                # Remove the target file
                if (-f $dest_file) {
                    unlink $dest_file
                        or die "Unable to remove file '$dest_file': $!";
                }

                # Run the command and capture the output
                my ($stdout, $stderr, $exit) = capture {
                    system('./find_times.pl', $source_file);
                };

                if ($exit != 0) {
                    $exit >>= 8;

                    my $err_str =
                        "\tFailed to run './find_times.pl \"$source_file\"' (exit $exit):\n\t$stderr";
                    my $hl = color('bold red');
                    my $rs = color('reset');
                    if ($err_str =~ s{.*?:\s+Long line (\d+) in '(.+?)' '(.+?)' '(.+?)': (.+)\z}
                                     {    Long line ($hl$1$rs) in $hl$2$rs - $hl$3$rs\n\t'$hl$4$rs':\n}s)
                    {
                        my $line = $5;

                        my $indent_size = 4;
                        my $indent = ' 'x$indent_size;
                        my $term_size = Term::Size::chars();

                        my $wrapper = Text::Wrapper->new(columns    => $term_size - $indent_size,
                                                         par_start  => $indent,
                                                         body_start => $indent);
                        $err_str .= $wrapper->wrap($line);
                    }

                    return ($exit, $err_str);
                }

                write_binary($dest_file, $stdout);

                return 0;
        };

        my $skip = 0;
        if (-f $dest_file and not -z $dest_file and not $force and
            ( not $which or "$author - $ob" !~ /$which/i)
            )
        {
            $skip = 1;
        }

        $self->add_task($s,
                        skip     => $skip,
                        author   => $author,
                        book     => $ob,
                        code     => $code,
                       );
    }

    return;
}

1;
