#!/usr/bin/perl

use strict;
use warnings;

##############################################
# UPDATE ipscountry.dat FROM RIR DELEGATION  #
# FILES (ARIN, RIPE, APNIC, LACNIC, AFRINIC) #
##############################################

use File::Temp qw(tempdir);
use File::Basename qw(dirname);

my $script_dir = dirname(__FILE__);
my $out_txt    = $ARGV[0] || "$script_dir/../lib/Geo/ips-ascii.txt";
my $out_dat    = $ARGV[1] || "$script_dir/../lib/Geo/ipscountry.dat";

# RIR delegation file URLs (HTTPS)
my %rir_urls = (
    arin    => 'https://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest',
    ripencc => 'https://ftp.ripe.net/pub/stats/ripencc/delegated-ripencc-extended-latest',
    apnic   => 'https://ftp.apnic.net/pub/stats/apnic/delegated-apnic-extended-latest',
    lacnic  => 'https://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-extended-latest',
    afrinic => 'https://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-extended-latest',
);

my $tmpdir = tempdir( CLEANUP => 1 );

# Download all RIR files
my @allocations;    # [ ip_number, country_code ]

for my $rir ( sort keys %rir_urls ) {
    my $url  = $rir_urls{$rir};
    my $file = "$tmpdir/$rir.txt";

    print "Downloading $rir delegation file...\n";
    my $rc = system( 'curl', '-sL', '-f', '-o', $file, $url );
    if ( $rc != 0 ) {
        die "Failed to download $rir delegation file from $url\n";
    }

    print "  Parsing $rir...\n";
    open( my $fh, '<', $file ) or die "Cannot open $file: $!\n";
    while ( my $line = <$fh> ) {
        chomp $line;
        next if $line =~ /^#/;
        next if $line =~ /^\s*$/;

        # Format: registry|CC|type|start|value|date|status[|extensions]
        my @fields = split /\|/, $line;
        next unless @fields >= 7;
        next unless $fields[2] eq 'ipv4';

        my $cc    = $fields[1];
        my $start = $fields[3];
        my $count = $fields[4];

        # Skip summary lines (CC is '*')
        next if $cc eq '*';

        # Skip unallocated/reserved entries with no country
        next unless $cc =~ /^[A-Z]{2}$/;

        my $ip_num = _ip2nb($start);
        push @allocations, [ $ip_num, $cc, $start ];
    }
    close($fh);
}

# Add reserved/private IP ranges (RFC 6890) as ZZ entries
my @reserved = (
    [ '0.0.0.0',     'ZZ' ],    # "This host" (RFC 1122)
    [ '10.0.0.0',    'ZZ' ],    # Private-Use (RFC 1918)
    [ '100.64.0.0',  'ZZ' ],    # Shared Address Space / CGNAT (RFC 6598)
    [ '127.0.0.0',   'ZZ' ],    # Loopback (RFC 1122)
    [ '169.254.0.0', 'ZZ' ],    # Link-Local (RFC 3927)
    [ '172.16.0.0',  'ZZ' ],    # Private-Use (RFC 1918)
    [ '192.0.0.0',   'ZZ' ],    # IETF Protocol Assignments (RFC 6890)
    [ '192.0.2.0',   'ZZ' ],    # Documentation TEST-NET-1 (RFC 5737)
    [ '192.168.0.0', 'ZZ' ],    # Private-Use (RFC 1918)
    [ '198.18.0.0',  'ZZ' ],    # Benchmarking (RFC 2544)
    [ '198.51.100.0','ZZ' ],    # Documentation TEST-NET-2 (RFC 5737)
    [ '203.0.113.0', 'ZZ' ],    # Documentation TEST-NET-3 (RFC 5737)
    [ '224.0.0.0',   'ZZ' ],    # Multicast (RFC 3171)
    [ '240.0.0.0',   'ZZ' ],    # Reserved (RFC 1112)
);

for my $r (@reserved) {
    push @allocations, [ _ip2nb( $r->[0] ), $r->[1], $r->[0] ];
}

# Sort by IP number
@allocations = sort { $a->[0] <=> $b->[0] } @allocations;

printf "Total allocations: %d\n", scalar @allocations;

# Write text file (format: CC: start_ip)
print "Writing $out_txt ...\n";
open( my $out_fh, '>', $out_txt ) or die "Cannot open $out_txt: $!\n";
for my $alloc (@allocations) {
    printf $out_fh "%s: %s\n", $alloc->[1], $alloc->[2];
}
close($out_fh);

# Now build the binary database using txt2ipct.pl
print "Building binary database...\n";
my $txt2ipct = "$script_dir/txt2ipct.pl";
if ( !-f $txt2ipct ) {
    die "Cannot find txt2ipct.pl at $txt2ipct\n";
}

system( $^X, "-I$script_dir/../lib", $txt2ipct, $out_txt, $out_dat ) == 0
    or die "txt2ipct.pl failed\n";

# Clean up the intermediate text file
unlink $out_txt;

print "Done. Database updated: $out_dat\n";

# Verify with a quick test
print "\nQuick verification:\n";
my $verify_cmd = qq{$^X -I$script_dir/../lib -MGeo::IPfree -e '
    my \$g = Geo::IPfree->new("$out_dat");
    for my \$ip (qw(8.8.8.8 45.128.139.41 1.1.1.1 185.0.0.1)) {
        my (\$c,\$n) = \$g->LookUp(\$ip);
        printf "  %-16s -> %s (%s)\\n", \$ip, \$c, \$n;
    }
'};
system($verify_cmd);

sub _ip2nb {
    my @ip = split /\./, $_[0];
    return ( $ip[0] << 24 ) + ( $ip[1] << 16 ) + ( $ip[2] << 8 ) + ( $ip[3] || 0 );
}
