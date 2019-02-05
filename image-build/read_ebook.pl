#!/bin/env perl

use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';

use lib '.';

use Archive::Zip;
use TimeMatch;
use XML::LibXML;
use XML::LibXML::XPathContext;


exit main(@ARGV);

# For highlighting:
#  alias hl="egrep -E '^|<<[^>]+(>>|$)|^[^<>]+>>'"
#  ./find_times.pl ~/Calibre\ Library/James\ Joyce/Dubliners\ \(3196\)/*epub | hl


sub main {
    my ($file) = @_;

    search_ebook($file);

    return 0;
}


sub search_ebook {
    my ($file) = @_;

    my $zip = read_epub($file);

    my $cont = get_container($file, $zip);

    return;
}


sub read_epub {
    my ($file) = @_;

    my $zip = Archive::Zip->new($file)
        or die "Unable to read zipfile '$file': $!";

    # Check the mimetype
    my $m = $zip->contents('mimetype')
        or die "Unable to read 'mimetype' from '$file'";
    my $mt = "application/epub+zip";
    die "Bad mimetype '$m' expected '$mt'"
        unless $m eq $mt;

    return $zip;
}

sub get_rootfile {
    my ($file, $zip) = @_;

    # Pull the container xml
    my $c = $zip->contents('META-INF/container.xml')
        or die "Unable to read 'META-INF/container.xml' from '$file'";

    # Parse it and find the root node
    my $dom = XML::LibXML->load_xml(string => $c);

    my $xpc = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs('c', 'urn:oasis:names:tc:opendocument:xmlns:container');

    my @cn = $xpc->findnodes('/c:container/c:rootfiles/'.
                             'c:rootfile[@media-type="application/oebps-package+xml"]');
    die "Unable to find the root file in '$file' (@cn)\n"
        if @cn != 1;

    my $path = $cn[0]->getAttribute('full-path')
        or die "Unable to read full-path from '$file'";

    return $path;
}

sub get_container {
    my ($file, $zip) = @_;

    # Work out the root file
    my $rootfile = get_rootfile($file, $zip);

    # Pull the container xml
    my $r = $zip->contents($rootfile)
        or die "Unable to read '$rootfile' from '$file'";

    # Parse it
    my $dom = XML::LibXML->load_xml(string => $r);

    my $xpc = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs('dc',  'http://purl.org/dc/elements/1.1/');
    $xpc->registerNs('opf', 'http://www.idpf.org/2007/opf');

    my @mn = $xpc->findnodes('/opf:package/opf:manifest/opf:item')
        or die "Unable to find the manifest in '$file' '$rootfile'\n";

    my @sp = $xpc->findnodes('/opf:package/opf:spine/opf:itemref')
        or die "Unable to find the spine in '$file' '$rootfile'\n";

    my @gu = $xpc->findnodes('/opf:package/opf:guide/opf:reference')
        or die "Unable to find the guide in '$file' '$rootfile'\n";

    DEBUG_MSG(\@mn)
}
