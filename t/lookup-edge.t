use strict;
use warnings;

use Test::More tests => 14;

use_ok('Geo::IPfree');

my $g = Geo::IPfree->new;

# LookUp with double dots should still work
{
    my ( $c, $n, $ip ) = $g->LookUp('200..160.7.2');
    is( $c, 'BR', 'double dots cleaned: country' );
    is( $ip, '200.160.7.2', 'double dots cleaned: IP normalized' );
}

# LookUp with leading dot
{
    my ( $c, $n, $ip ) = $g->LookUp('.200.160.7.2');
    is( $c, 'BR', 'leading dot cleaned: country' );
}

# LookUp with trailing dot
{
    my ( $c, $n, $ip ) = $g->LookUp('200.160.7.2.');
    is( $c, 'BR', 'trailing dot cleaned: country' );
}

# LookUp returns 3 values in list context
{
    my @result = $g->LookUp('192.134.4.20');
    is( scalar @result, 3, 'returns 3 values' );
    is( $result[0], 'FR',     'country code' );
    is( $result[1], 'France', 'country name' );
    like( $result[2], qr/^\d+\.\d+\.\d+\.\d+$/, 'third value is an IP' );
}

# Cache can be disabled
{
    my $g2 = Geo::IPfree->new;
    $g2->{cache} = 0;
    my ( $c1 ) = $g2->LookUp('200.160.7.2');
    is( $c1, 'BR', 'lookup works with cache disabled' );
    ok( !$g2->{CACHE} || !$g2->{CACHE}{'200.160.7.0'},
        'no cache entry when cache disabled' );
}

# Same IP in Faster mode gives same result
{
    my $g2 = Geo::IPfree->new;
    my ( $c1 ) = $g2->LookUp('209.173.53.26');
    $g2->Faster;
    my ( $c2 ) = $g2->LookUp('209.173.53.26');
    is( $c1, $c2, 'disk and Faster mode agree' );
}

# Multiple private IP ranges
{
    my ( $c1 ) = $g->LookUp('192.168.0.1');
    is( $c1, 'ZZ', '192.168.x.x is reserved' );
}
{
    my ( $c1 ) = $g->LookUp('172.16.0.1');
    is( $c1, 'ZZ', '172.16.x.x is reserved' );
}
