use strict;
use warnings;

use Test::More tests => 10;

use Geo::IPfree;

my $geo = Geo::IPfree->new;

# Valid IPs still work
{
    my ( $cc, $name ) = $geo->LookUp('200.160.7.2');
    is( $cc, 'BR', 'valid IP 200.160.7.2 returns BR' );
}

# Boundary: octets at 255 are valid
{
    my ( $cc, $name, $ip ) = $geo->LookUp('255.255.255.255');
    ok( defined $cc, '255.255.255.255 is a valid IP (returns a result)' );
}

# Boundary: octets at 0 are valid
{
    my ( $cc, $name, $ip ) = $geo->LookUp('0.0.0.1');
    ok( defined $cc, '0.0.0.1 is a valid IP (returns a result)' );
}

# Invalid: octet > 255 should croak
{
    eval { $geo->LookUp('256.1.2.3') };
    like( $@, qr/Invalid IP address/, '256.1.2.3 croaks (first octet > 255)' );
}

{
    eval { $geo->LookUp('1.256.2.3') };
    like( $@, qr/Invalid IP address/, '1.256.2.3 croaks (second octet > 255)' );
}

{
    eval { $geo->LookUp('1.2.256.3') };
    like( $@, qr/Invalid IP address/, '1.2.256.3 croaks (third octet > 255)' );
}

{
    eval { $geo->LookUp('1.2.3.256') };
    like( $@, qr/Invalid IP address/, '1.2.3.256 croaks (fourth octet > 255)' );
}

# The original silent-wrong-result bug: 200.300.400.500 returned "Brazil"
{
    eval { $geo->LookUp('200.300.400.500') };
    like( $@, qr/Invalid IP address/, '200.300.400.500 croaks instead of returning wrong country' );
}

{
    eval { $geo->LookUp('999.999.999.999') };
    like( $@, qr/Invalid IP address/, '999.999.999.999 croaks' );
}

# Functional (non-OO) interface also validates
{
    eval { Geo::IPfree::LookUp('300.1.2.3') };
    like( $@, qr/Invalid IP address/, 'functional LookUp also validates octets' );
}
