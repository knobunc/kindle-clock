#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use File::Find;
use Getopt::Euclid;

use lib '.';

use MultiProcessBooks;

my $basedir = "$ENV{HOME}/Calibre Library/";

exit main(@ARGV);


sub main {
    my ($force, $which, $quiet) = handle_args();

    my $mp = MultiProcessBooks->new(dir => 'books', quiet => $quiet);

    $mp->add_sources($force, $which, load_books() );

    $mp->run_jobs();

    return 0;
}

sub handle_args {
    # No args


    my $force = 0;
    my $which;
    if ($ARGV{'--all'}) {
        $force = 1;
    }
    elsif ($ARGV{'--pattern'}) {
        $which = $ARGV{'--pattern'};
    }

    my $quiet = $ARGV{'--quiet'};

    return ($force, $which, $quiet);
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

__END__

==head1 NAME

make_books.pl - Generate book dumps from epubs in your calibre library matching the pattern.

==head1 VERSION

This documentation refers to make_books.pl version 1.0.0

==head1 USAGE

    make_books.pl [options]

==head1 REQUIRED ARGUMENTS

None.

=head1 OPTIONS

=over

=item -p <pattern> | --pattern <pattern>

If given it will regenerate books matching the pattern.

=item -a | --all

Regenerate all books.

=item -q | --quiet

Supress skipped items.

=back

=head1 AUTHOR

Benjamin Bennett (sink@limey.net)

=head1 BUGS

There are undoubtedly serious bugs lurking somewhere in this code.
Bug reports and other feedback are most welcome.

=head1 COPYRIGHT

Copyright (c) 2019, Benjamin Bennett. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)
