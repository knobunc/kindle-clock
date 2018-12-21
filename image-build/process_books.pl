#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use File::Find;

use lib '.';

use MultiProcessBooks;

my $basedir = "/home/bbennett/Calibre Library/";

exit main(@ARGV);


sub main {
    my ($force, $which) = handle_args(@_);

    my $mp = MultiProcessBooks->new(dir => 'books');

    $mp->add_sources($force, $which, load_books() );

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

    return ($force, $which);
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

    return [ sort @dirs ];
}
