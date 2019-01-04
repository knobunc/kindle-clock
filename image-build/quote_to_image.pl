#!/usr/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use Clone qw( clone );
use Cwd qw( abs_path );
use Data::Dumper;
use GD;
use Image::Magick;
use List::Util qw( min max );
use Parallel::ForkManager;
use Sys::Info;
use Text::CSV;

# Set up our fonts
$ENV{GDFONTPATH} = abs_path("./fonts");
my $font_path        = "LinLibertine_RZah";
my $font_path_bold   = "LinLibertine_RBah";
my $font_path_italic = "LinLibertine_RZIah";
my $credit_font_size = 18;

# Image dimensions
my $width  = 600;
my $height = 800;

# Text margin
my $margin = 26;

# Bounds on the font sizes
# A long quote of 125 words or 700 characters gives us a font size of 23, so 18 is a safe min
my $min_font_size =  18;
my $max_font_size = 120;

# Run it
exit main(@ARGV);

#####

sub main {
    my ($csv_file, $image_path) = @_;
    die "Usage: $0 <csv_file> <output_dir>\n"
        unless $image_path;

    my $csv = Text::CSV->new ( { binary => 1, sep_char => '|', strict => 1 } )
        or die "Cannot use CSV: ".Text::CSV->error_diag ();

    my $fh = IO::File->new($csv_file, '<:encoding(utf8)')
        or die "Can't read '$csv_file': $!";

    my $pm = Parallel::ForkManager->new(get_num_tasks());

    my @tasks;
    my $row_num = -1;
  LOAD_LOOP:
    while (my $row = $csv->getline($fh)) {
        $row_num++;

#        last if $row_num == 50;
#        next if $row_num != 27;

        my ($time, $timestr, $quote, $title, $author) = map { clean_space($_) } @$row;

        $time =~ s{\A (\d\d) : (\d\d) \z}{$1$2}x
            or die "Bad time '$time'";

        my $imagenumber = get_imagenumber($time);
        push @tasks, [$time, $timestr, $quote, $title, $author, $imagenumber, $row_num];
    }

  TASK_LOOP:
    while (@tasks) {
        my @subtasks = splice(@tasks, 0, 20);

        $pm->start()
            and next TASK_LOOP;

        foreach my $t (@subtasks) {
            my ($time, $timestr, $quote, $title, $author, $imagenumber, $row_num) = @$t;
            make_quote_images($image_path, $time, $quote, $timestr, $title, $author,
                              $imagenumber, $row_num);
        }

        $pm->finish();
    }

    $pm->wait_all_children();

    return 0;
}

sub clean_space {
    my ($str) = @_;

    $str =~ s/^\s+|\s+$//g;
    $str =~ s{\s+}{ };

    return $str;
}

sub get_imagenumber {
    my ($time) = @_;

    # Serial number for when there is more than one quote for a certain minute
    state $imagenumber = 0;
    state $previoustime = 0;
    if ($time == $previoustime) {
        $imagenumber++;
    } else {
        $imagenumber = 0;
    }
    $previoustime = $time;

    return $imagenumber;
}

sub make_quote_images {
    my ($image_path, $time, $quote, $timestr, $title, $author, $imagenumber, $ln) = @_;

    ## QUOTE
    # Render the text nicely and return the image handle
    my ($img, $font_size) = render_text($quote, $timestr, $title, $author);

    my $ql = 70;
    my $qs = length($quote) > $ql ? substr($quote, 0, $ql-3) . "..." : $quote;
    printf("%s_%03d (len %5d, font %3d): %s\n",
           $time, $imagenumber, length($quote), $font_size, $qs);

    # Save the image
    my $basename = sprintf("quote_%s_%03d", $time, $imagenumber);
    my $file_nc = $basename.'.png';
    imgtopng($img, "$image_path/$file_nc");

    ## METADATA
    # create another version, with title and author in the image
    add_source($img, $title, $author);

    # Save the image with metadata
    my $file_c = $basename.'_credits.png';
    imgtopng($img, "$image_path/metadata/$file_c");

    $img = undef;

    return;
}

sub imgtopng {
    my ($img, $file) = @_;

    open my $fh, '>:raw', $file
        or die "Unable to write to '$file': $!";
    print $fh $img->png();
    close $fh;

    colorimg_to_grey($file);

    return;
}

sub render_text {
    my ($quote, $timestr, $title, $author) = @_;

    # Get the word pieces
    my $pieces = get_word_pieces($quote, $timestr);

    # How many lines will the source take
    my $source_lines = get_source_lines($title, $author);

    # Do a binary search of the space
    my $hi_font = $max_font_size + 1;
    my $lo_font = $min_font_size - 1;

    my $lo_lines = undef;
    my $lo_img;

    my $font_size;

    while ($lo_font < $hi_font ) {
        $font_size = $lo_font + int(($hi_font - $lo_font) / 2 + 0.5);

        my ($paragraphHeight, $lines) = fit_text($pieces, $font_size, $source_lines);

        if ($paragraphHeight) {
            # This font fit, make it the new low
            $lo_font  = $font_size;
            $lo_lines = $lines;
        }
        else {
            # This font did not fit, make it one above the new high
            $hi_font = $font_size - 1;
        }
    }
    $font_size = $lo_font;

    # Render at the size we found
    my $img = draw_text($lo_lines, $font_size);

    return ($img, $font_size);
}

sub get_word_pieces {
    my ($quote, $timestr) = @_;

    # First, find the timestr to be highlighted in the quote
    my $ts_loc = index( lc($quote), lc($timestr) );
    die "Unable to find '$timestr' in '$quote'" if $ts_loc == -1;

    # Need the -1 to make split match the trailing spaces
    my @li = split(/\s/, substr($quote, 0, $ts_loc), -1);

    # Determine the position of the timestr in the quote (which word it is first in)
    my $timestr_starts = @li - 1;
    $timestr_starts = 0 if $timestr_starts < 0;

    # Divide text in an array of words, based on spaces
    my @quote_array   = split /\s/, $quote;
    my @timestr_array = split /\s/, $timestr;

    my @word_pieces;
    for my $i (0 .. @quote_array - 1) {
        my $word = $quote_array[$i];

        # Change the look of the text if it is part of the time string
        my @pieces = ();
        if ( $i >= $timestr_starts and $i < ($timestr_starts + @timestr_array) ) {
            # This word has part of the timestr in it, we need to highlight some of it
            my $time_word = $timestr_array[$i - $timestr_starts];

            my ($pre, $hi, $post) = $word =~ m{\A (.*?) (\Q$time_word\E) (.*) \z}xi
                or die "Unable to find '$time_word' in '$word'";

            push @pieces, [$font_path,      "grey",  $pre ] if $pre;
            push @pieces, [$font_path_bold, "black", $hi  ];
            push @pieces, [$font_path,      "grey",  $post] if $post;
        }
        else {
            # Normal word, no part of the timestr is in it
            push @pieces, [$font_path, "grey", $word];
        }

        push @word_pieces, \@pieces;
    }

    return \@word_pieces;
}

sub fit_text {
    my ($word_pieces, $font_size, $source_lines) = @_;

    # Make a copy so we can munge up the input
    $word_pieces = clone($word_pieces);

    # Track the x and y position of words
    my ($pos_x, $pos_y) = ($margin, $margin + $font_size);

    # Work out the farthest we can go down the page
    # We need to leave space for the margin and two rows of text
    my $credit_leading = get_leading($credit_font_size, $font_path);
    my $font_descend   = get_descend($font_size,        $font_path);
    my $max_x = $width - $margin;
    my $max_y = $height - $font_descend - ( $credit_leading * $source_lines ) - $margin;

    # Get the line spacing
    my $leading = get_leading($font_size, $font_path);

    my $base_width = 0;
    my @lines;
    foreach my $wp (@$word_pieces) {
        # Measure the word's width
        my $wordwidth = 0;
        foreach my $p (@$wp) {
            my ($font, $textcolor, $word) = @$p;
            my ($w) = measureSizeOfTextbox($font_size, $font, $word);

            $wordwidth += $w;
        }

        # If one word exceeds the width of the image (which can happen when the quote is very short),
        # then stop trying to make the font size even bigger.
        if ($wordwidth > $max_x) {
            return;
        }

        # Measure the size of the space and include it after the word
        my $space_width = get_space_width($font_size, $wp->[-1][0]);
        $wp->[-1][2] .= " ";

        # If the line plus the extra word is too wide for the specified width, then write
        # the word on the next line.
        if (@lines == 0 or ($pos_x + $wordwidth) >= $max_x ) {
            # 'carriage return': Reset x to the beginning of the line and push y down a line
            $pos_y += $leading
                if @lines > 0;

            if ($pos_y >= $max_y) {
                # This call to fit_text returned a paragraph that is in fact higher than the height
                # of the image, return without those values to indicate we went too far
                return;
            }

            # New line, add this word's pieces
            push @lines, [ @$wp ];
            $pos_x = $margin + $wordwidth + $space_width;
        }
        else {
            # New word on existing line
            $pos_x += $wordwidth + $space_width;

            # See if these pieces can be combined
            my $lp = $lines[-1][-1];
            foreach my $p (@$wp) {
                if ($lp->[0] eq $p->[0] and # Font
                    $lp->[1] eq $p->[1])    # Color
                {
                    # They can be combined
                    $lp->[2] .= $p->[2];
                }
                else {
                    push @{ $lines[-1] }, $p;
                    $lp = $p;
                }
            }
        }
    }

    return ($pos_y, \@lines);
}

sub draw_text {
    my ($lines, $font_size) = @_;

    # Create image
    my $img = GD::Image->new($width, $height)
        or die "Cannot create new GD::Image";

    # Define the colors
    my %color =
        (bg    => $img->colorAllocate(255, 255, 255),
         grey  => $img->colorAllocate(125, 125, 125),
         black => $img->colorAllocate(  0,   0,   0),
        );

    my $max_x = $width - $margin;

    # Variable to hold the x and y position of words
    my ($pos_x, $pos_y) = ($margin, $margin + $font_size);

    my $leading = get_leading($font_size, $font_path);

    foreach my $line (@$lines) {
        # Write the pieces to the image
        $pos_x = $margin;
        foreach my $p (@$line) {
            my ($font, $textcolor, $word) = @$p;
            my $color = $color{$textcolor}
                // die "No color for '$textcolor'";
            my ($w) = dimensions( $img->stringFT($color, $font, $font_size, 0,
                                                 $pos_x, $pos_y, $word) );

            # Add the piece's width
            $pos_x += $w;
        }

        $pos_y += $leading;
    }

    return ($img);
}

sub measureSizeOfTextbox {
    my ($font_size, $font_path, $text) = @_;

    return dimensions( GD::Image->stringFT(1, $font_path, $font_size, 0, 0, 0, $text) );
}

sub dimensions {
    #   llx     lly     lrx     lry    urx    ury
    my ($min_x, $max_y, $max_x, undef, undef, $min_y) = @_;

    my $width  = ( $max_x - $min_x );
    my $height = ( $max_y - $min_y );
    my $left   = abs( $min_x ) + $width;
    my $top    = abs( $min_y ) + $height;

    return($width, $height, $left, $top);
}

# Will the source take 1 or 2 lines
sub get_source_lines {
    my ($title, $author) = @_;

    my $pieces    = get_credit_pieces($author, $title);
    my $metawidth = measure_credit_pieces($pieces);

    my $max_width = $width - $margin*3;
    my $num_lines = $metawidth > $max_width ? 2 : 1;

    if (wantarray) {
        return ($num_lines, $pieces);
    }
    return $num_lines;
}

sub add_source {
    my ($img, $title, $author) = @_;

    my ($num_lines, $pieces) = get_source_lines($title, $author);

    my $line1 = [];
    my $line2 = $pieces;

    if ($num_lines > 1) {
        # This needs to be displayed over more than one line, let's do it
        # We want the first line to be a little longer than the second, so try moving each word
        # until we get longer

        while (@$line2) {
            my $w1 = measure_credit_pieces($line1);
            my $w2 = measure_credit_pieces($line2);

            last if $w1 > $w2;

            push(@$line1, shift(@$line2));
        }
    }

 print_credit_line($img, $line1, 1) if @$line1;
    print_credit_line($img, $line2, 2);
}

sub print_credit_line {
    my ($img, $pieces, $line_num) = @_;

    my $offset_y = 0;
    if ($line_num == 1) {
        $offset_y = get_leading($credit_font_size, $font_path);
    }

    $pieces = coalesce_credit_pieces($pieces);

    my $text_width = measure_credit_pieces($pieces);

    my $l_text = join " ", map {$_->[1]} @$pieces;

    my $x_pos = $width - $text_width - $margin;
    my $y_pos = $height - $margin - $offset_y;

    my $space_width = get_space_width($credit_font_size, $font_path);
    my $black_c = $img->colorExact(  0,   0,   0);

    my $first = 1;
    foreach my $p (@$pieces) {
        if (not $first) {
            $x_pos += $space_width;
        }
        $first = 0;

        my ($font, $word, $word_width) = @$p;
        $img->stringFT($black_c, $font, $credit_font_size, 0, $x_pos, $y_pos, $word);
        $x_pos += $word_width;
    }
}

sub get_leading {
    my ($font_size, $font) = @_;

    # The Golden Ratio spacing
    return int( $font_size * 1.618 );

    # Compute the size by looking at the bounds
    # my (undef, $two_line_h) = measureSizeOfTextbox($font_size, $font, "m\nm");
    # my (undef, $m_h)        = measureSizeOfTextbox($font_size, $font, "m");

    # return $two_line_h - $m_h;
}

# Work out how much things descend below the baseline
sub get_descend {
    my ($font_size, $font) = @_;

    # Compute the size by looking at the bounds of certain letters
    my (undef, $m_h)        = measureSizeOfTextbox($font_size, $font, "m");
    my (undef, $j_h)        = measureSizeOfTextbox($font_size, $font, "j");

    return $j_h - $m_h;
}

sub get_credit_pieces {
    my ($author, $title) = @_;
    my @pieces;

    my $em_dash = "—";
    $author = $em_dash . $author . ",";

    foreach my $aw (split /\s+/, $author) {
        push @pieces, [$font_path,        $aw];
    }
    foreach my $tw (split /\s+/, $title) {
        push @pieces, [$font_path_italic, $tw];
    }

    add_measurements_to_credit_pieces(\@pieces);

    return \@pieces;
}

sub add_measurements_to_credit_pieces {
    my ($pieces) = @_;

    # Size the pieces since we know the font used
    foreach my $p (@$pieces) {
        my ($font, $word) = @$p;
        my ($width) = measureSizeOfTextbox($credit_font_size, $font, $word);
        $p->[2] = $width;
    }

    return;
}

sub measure_credit_pieces {
    my ($pieces) = @_;

    my $space_width = get_space_width($credit_font_size, $font_path);

    my $width = 0;
    my $first = 1;
    foreach my $p (@$pieces) {
        if (not $first) {
            $width += $space_width;
        }
        $first = 0;

        $width += $p->[2];
    }

    return $width;
}

sub coalesce_credit_pieces {
    my ($pieces) = @_;
    my @new_pieces;

    my $last_piece = undef;
    foreach my $p (@$pieces) {
        if (not defined $last_piece or $p->[0] ne $last_piece->[0]) {
            $last_piece = $p;
            push @new_pieces, $p;
        }
        else {
            $last_piece->[1] .= " " . $p->[1];
        }
    }

    add_measurements_to_credit_pieces(\@new_pieces);

    return \@new_pieces;
}

sub get_space_width {
    my ($size, $font) = @_;

    state %space_width;

    if (not defined $space_width{$size}{$font}) {
        my ($s1) = measureSizeOfTextbox($size, $font, 'T .');
        my ($s2) = measureSizeOfTextbox($size, $font, 'T.');
        $space_width{$size}{$font} = $s1 - $s2;
    }

    return $space_width{$size}{$font};
}

sub colorimg_to_grey {
    my ($file) = @_;

    # Convert the image we made to greyscale
    state $im = Image::Magick->new(magick => 'png');

    # Define the image you want to convert
    $im->Read($file);

    # Set grayscale
    $im->Quantize(colorspace=>'gray');

    # Write the new file
    unlink($file);

    # Write the last image in the sequence if there are multiple
    # Quality is defined here -- http://imagemagick.org/script/command-line-options.php#quality
    $im->[-1]->Write(filename => $file, quality => '92');

    return;
}

sub get_num_tasks {
    # No args

    my $info = Sys::Info->new;
    my $cpu  = $info->device('CPU');

    return $cpu->count();
}

sub DEBUG_MSG {
    my @dump = @_;

    my ($package, $filename, $line) = caller;

    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Sortkeys = 1;
    print STDERR "Debug at $filename:$line:\n", Dumper(@dump);

    return;
}
