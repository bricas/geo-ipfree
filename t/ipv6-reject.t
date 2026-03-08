use strict;
use warnings;

use Test::More tests => 5;

use Geo::IPfree;

my $geo = Geo::IPfree->new();

# Full IPv6 address
eval { $geo->LookUp('2001:0db8:85a3:0000:0000:8a2e:0370:7334') };
like( $@, qr/IPv6 addresses are not supported/, 'full IPv6 address croaks' );

# Compressed IPv6
eval { $geo->LookUp('2001:db8::1') };
like( $@, qr/IPv6 addresses are not supported/, 'compressed IPv6 address croaks' );

# IPv6 loopback
eval { $geo->LookUp('::1') };
like( $@, qr/IPv6 addresses are not supported/, 'IPv6 loopback croaks' );

# Functional interface
eval { Geo::IPfree::LookUp('fe80::1') };
like( $@, qr/IPv6 addresses are not supported/, 'functional interface croaks on IPv6' );

# IPv4 still works fine
my ( $country, $country_name ) = $geo->LookUp('127.0.0.1');
is( $country, 'ZZ', 'IPv4 still works after IPv6 check' );
