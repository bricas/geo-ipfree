use strict;
use warnings;

use Test::More tests => 10;

use Geo::IPfree;

# Regression test for https://github.com/bricas/geo-ipfree/pull/1
#
# The ipscountry.dat database contains ranges that split within a /24 block.
# For example, 195.60.95.0/24 has CY (.0-.127) and GB (.128-.255).
# Previously, LookUp() normalized every IP to its .0 form before lookup,
# which meant all IPs in a /24 block returned the same (wrong) country.

my $geo = Geo::IPfree->new;

{    # IP in the lower range of a split /24 — should be CY
    my ( $cc, $name, $ip ) = $geo->LookUp('195.60.95.1');
    is( $cc,   'CY', '195.60.95.1 is in Cyprus range' );
    is( $name, 'Cyprus' );
    is( $ip,   '195.60.95.1', 'returned ip is the actual IP, not .0' );
}

{    # IP in the upper range of the same /24 — should be GB, not CY
    my ( $cc, $name, $ip ) = $geo->LookUp('195.60.95.200');
    is( $cc,   'GB', '195.60.95.200 is in United Kingdom range' );
    is( $name, 'United Kingdom' );
    is( $ip,   '195.60.95.200', 'returned ip is the actual IP, not .0' );
}

# Verify cache isolation: looking up one IP must not pollute results for
# another IP in the same /24 that belongs to a different country.
$geo->Clean_Cache;

{    # Seed cache with the .0 IP (CY)
    my ( $cc1 ) = $geo->LookUp('195.60.95.0');
    is( $cc1, 'CY', 'cache seed: 195.60.95.0 is CY' );

    # Now look up a higher IP in the same /24 — must not return cached CY
    my ( $cc2 ) = $geo->LookUp('195.60.95.200');
    is( $cc2, 'GB', '195.60.95.200 is GB even after .0 was cached as CY' );
}

# Also verify with Faster mode (in-memory DB)
my $fast = Geo::IPfree->new;
$fast->Faster;

{
    my ( $cc1 ) = $fast->LookUp('195.60.95.1');
    is( $cc1, 'CY', 'Faster mode: 195.60.95.1 is CY' );

    my ( $cc2 ) = $fast->LookUp('195.60.95.200');
    is( $cc2, 'GB', 'Faster mode: 195.60.95.200 is GB' );
}
