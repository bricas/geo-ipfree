use strict;
use warnings;

use Test::More tests => 12;

use Geo::IPfree;

# Verify that the binary search in LookUp() produces correct results
# for boundary IPs and typical lookups, in both disk and Faster modes.

my $disk = Geo::IPfree->new;
my $fast = Geo::IPfree->new;
$fast->Faster;

my @cases = (
    [ '0.0.0.0',         'ZZ', 'lowest IP' ],
    [ '255.255.255.255', 'ZZ', 'highest IP' ],
    [ '127.0.0.1',       'ZZ', 'loopback' ],
    [ '8.8.8.8',         'US', 'well-known public IP' ],
    [ '200.160.7.2',     'BR', 'Brazilian IP' ],
    [ '192.134.4.20',    'FR', 'French IP' ],
);

for my $case (@cases) {
    my ( $ip, $expected_cc, $label ) = @$case;

    my ($cc_disk) = $disk->LookUp($ip);
    $disk->Clean_Cache;
    is( $cc_disk, $expected_cc, "disk mode: $label ($ip)" );

    my ($cc_fast) = $fast->LookUp($ip);
    $fast->Clean_Cache;
    is( $cc_fast, $expected_cc, "Faster mode: $label ($ip)" );
}
