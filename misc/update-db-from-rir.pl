#!/usr/bin/perl

use strict;
use warnings;

##############################################################################
# Fetch RIR delegation files and rebuild ipscountry.dat
#
# This script downloads the latest IPv4 allocation data from all five
# Regional Internet Registries (ARIN, RIPE, APNIC, LACNIC, AfriNIC),
# merges the data, adds RFC 6890 reserved ranges, produces a sorted
# text file, and compiles it into ipscountry.dat using txt2ipct.pl.
#
# USAGE:
#   perl misc/update-db-from-rir.pl [output-dir]
#
# The output-dir defaults to lib/Geo/ (where ipscountry.dat lives).
# Requires curl in PATH.
##############################################################################

use File::Spec;
use File::Basename qw(dirname);
use POSIX          qw(ceil);

my $output_dir = $ARGV[0] || File::Spec->catdir( dirname($0), '..', 'lib', 'Geo' );
my $txt_file   = File::Spec->catfile( $output_dir, 'ips-rir.txt' );
my $dat_file   = File::Spec->catfile( $output_dir, 'ipscountry.dat' );
my $txt2ipct   = File::Spec->catfile( dirname($0), 'txt2ipct.pl' );

die "txt2ipct.pl not found at $txt2ipct\n" unless -f $txt2ipct;
die "output directory $output_dir does not exist\n" unless -d $output_dir;

# RIR delegation file URLs
my %rir_urls = (
    arin    => 'https://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest',
    ripencc => 'https://ftp.ripe.net/pub/stats/ripencc/delegated-ripencc-extended-latest',
    apnic   => 'https://ftp.apnic.net/pub/stats/apnic/delegated-apnic-extended-latest',
    lacnic  => 'https://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-latest',
    afrinic => 'https://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-extended-latest',
);

# RFC 6890 reserved ranges not present in RIR data.
# We assign these to ZZ (reserved / private).
my @reserved_ranges = (
    [ '0.0.0.0',     16777216 ],    # 0.0.0.0/8
    [ '10.0.0.0',    16777216 ],    # 10.0.0.0/8
    [ '100.64.0.0',  4194304 ],     # 100.64.0.0/10  (Shared Address Space)
    [ '127.0.0.0',   16777216 ],    # 127.0.0.0/8
    [ '169.254.0.0', 65536 ],       # 169.254.0.0/16 (link-local)
    [ '172.16.0.0',  1048576 ],     # 172.16.0.0/12
    [ '192.0.0.0',   256 ],         # 192.0.0.0/24   (IETF Protocol Assignments)
    [ '192.0.2.0',   256 ],         # 192.0.2.0/24   (TEST-NET-1)
    [ '192.168.0.0', 65536 ],       # 192.168.0.0/16
    [ '198.18.0.0',  131072 ],      # 198.18.0.0/15  (Benchmarking)
    [ '198.51.100.0', 256 ],        # 198.51.100.0/24 (TEST-NET-2)
    [ '203.0.113.0', 256 ],         # 203.0.113.0/24  (TEST-NET-3)
    [ '224.0.0.0',   268435456 ],   # 224.0.0.0/4    (Multicast)
    [ '240.0.0.0',   268435456 ],   # 240.0.0.0/4    (Reserved)
);

# Step 1: Fetch RIR delegation files
print "Fetching RIR delegation files...\n";

my %entries;    # ip_numeric => { ip => ..., country => ..., count => ... }

for my $rir ( sort keys %rir_urls ) {
    my $url = $rir_urls{$rir};
    print "  $rir ... ";

    my @lines = `curl -sL "$url"`;
    if ( $? != 0 ) {
        warn "FAILED (curl exit $?)\n";
        next;
    }

    my $count = 0;
    for my $line (@lines) {
        chomp $line;

        # Skip comments and headers
        next if $line =~ /^#/;
        next if $line =~ /^\d+\|/    # version/summary lines
            && $line !~ /\|ipv4\|/;

        # Format: registry|CC|ipv4|start_ip|count|date|status[|...]
        my @f = split /\|/, $line;
        next unless @f >= 5;
        next unless $f[2] eq 'ipv4';

        my $cc    = uc $f[1];
        my $ip    = $f[3];
        my $hosts = $f[4];

        next unless $cc =~ /^[A-Z]{2}$/;
        next unless $ip =~ /^\d+\.\d+\.\d+\.\d+$/;
        next unless $hosts =~ /^\d+$/ && $hosts > 0;

        my $ipnb = ip2nb($ip);
        $entries{$ipnb} = { ip => $ip, country => $cc, count => $hosts };
        $count++;
    }

    print "$count entries\n";
}

die "No RIR entries fetched — check network connectivity\n" unless keys %entries;

# Step 2: Add reserved ranges (won't overwrite RIR entries)
print "Adding reserved ranges...\n";
for my $r (@reserved_ranges) {
    my ( $ip, $count ) = @$r;
    my $ipnb = ip2nb($ip);
    $entries{$ipnb} ||= { ip => $ip, country => 'ZZ', count => $count };
}

# Step 3: Expand allocations into range boundaries
# RIR data gives start_ip + host_count. Large allocations need to be split
# at power-of-two boundaries because the binary DB format stores one boundary
# IP per entry.
print "Expanding allocations...\n";

my @boundaries;    # [ ip_numeric, country_code ]

for my $ipnb ( sort { $a <=> $b } keys %entries ) {
    my $e     = $entries{$ipnb};
    my $count = $e->{count};
    my $cc    = $e->{country};
    my $start = $ipnb;

    # Split the allocation into power-of-two aligned blocks
    while ( $count > 0 ) {
        # Find the largest power of 2 that fits and is aligned
        my $bit = 1;
        while ( $bit * 2 <= $count && ( $start % ( $bit * 2 ) ) == 0 ) {
            $bit *= 2;
        }
        push @boundaries, [ $start, $cc ];
        $start += $bit;
        $count -= $bit;
    }
}

# Sort by IP ascending — txt2ipct.pl uses unshift (reversing order),
# so ascending input produces descending binary DB (highest IP first).
@boundaries = sort { $a->[0] <=> $b->[0] } @boundaries;

# Step 4: Write text file
print "Writing $txt_file (" . scalar(@boundaries) . " entries)...\n";

open( my $fh, '>', $txt_file ) or die "Cannot write $txt_file: $!\n";
for my $b (@boundaries) {
    printf $fh "%s: %s\n", $b->[1], nb2ip( $b->[0] );
}
close($fh);

# Step 5: Compile to binary using txt2ipct.pl
print "Compiling $dat_file...\n";
my $lib_dir = File::Spec->catdir( dirname($0), '..', 'lib' );
system( $^X, "-I$lib_dir", $txt2ipct, $txt_file, $dat_file );
if ( $? != 0 ) {
    die "txt2ipct.pl failed (exit $?)\n";
}

# Step 6: Clean up intermediate file
unlink $txt_file;

my $size = -s $dat_file;
printf "Done. %s updated (%d bytes, %d entries).\n",
    $dat_file, $size, scalar @boundaries;

# Verify the problematic IP from issue #10
print "\nVerification:\n";
eval {
    require lib;
    lib->import( File::Spec->catdir( dirname($0), '..', 'lib' ) );
    require Geo::IPfree;
    my $geo = Geo::IPfree->new($dat_file);
    for my $test_ip ( '45.128.139.41', '8.8.8.8', '1.1.1.1' ) {
        my ( $cc, $name ) = $geo->LookUp($test_ip);
        printf "  %-16s -> %s (%s)\n", $test_ip, $cc, $name;
    }
};
warn "  Verification skipped: $@\n" if $@;

sub ip2nb {
    my @ip = split( /\./, $_[0] );
    return ( $ip[0] << 24 ) + ( $ip[1] << 16 ) + ( $ip[2] << 8 ) + $ip[3];
}

sub nb2ip {
    my $n = $_[0];
    return join( '.', ( $n >> 24 ) & 0xFF, ( $n >> 16 ) & 0xFF,
        ( $n >> 8 ) & 0xFF, $n & 0xFF );
}
