use strict;
use warnings;

use Test::More;

use Geo::IPfree;

# Verify that disk-mode and Faster-mode LookUp produce identical results
# for a range of IPs including boundary cases.

my @test_ips = (
    '0.0.0.0',
    '0.0.0.1',
    '1.0.0.0',
    '1.0.0.1',
    '8.8.8.8',
    '10.0.0.1',
    '127.0.0.1',
    '172.16.0.1',
    '192.134.4.20',
    '192.168.1.1',
    '200.160.7.2',
    '209.173.53.26',
    '223.255.255.255',
    '224.0.0.1',
    '255.255.255.254',
    '255.255.255.255',
);

plan tests => scalar @test_ips;

my $disk = Geo::IPfree->new;
my $fast = Geo::IPfree->new;
$fast->Faster;

for my $ip (@test_ips) {
    my @d = $disk->LookUp($ip);
    my @f = $fast->LookUp($ip);
    is( $d[0], $f[0], "disk and Faster agree for $ip ($d[0])" );
}
