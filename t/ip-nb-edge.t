use strict;
use warnings;

use Test::More tests => 18;

use_ok('Geo::IPfree');

# Boundary: 0.0.0.0
is( Geo::IPfree::ip2nb('0.0.0.0'), 0, 'ip2nb 0.0.0.0 = 0' );
is( Geo::IPfree::nb2ip(0), '0.0.0.0', 'nb2ip 0 = 0.0.0.0' );

# Boundary: 255.255.255.255 (max IPv4)
is( Geo::IPfree::ip2nb('255.255.255.255'), 4294967295, 'ip2nb 255.255.255.255 = 2^32-1' );
is( Geo::IPfree::nb2ip(4294967295), '255.255.255.255', 'nb2ip 2^32-1 = 255.255.255.255' );

# Boundary: first octet only
is( Geo::IPfree::ip2nb('1.0.0.0'), 16777216, 'ip2nb 1.0.0.0' );
is( Geo::IPfree::nb2ip(16777216), '1.0.0.0', 'nb2ip 1.0.0.0' );

# Boundary: second octet
is( Geo::IPfree::ip2nb('0.1.0.0'), 65536, 'ip2nb 0.1.0.0' );
is( Geo::IPfree::nb2ip(65536), '0.1.0.0', 'nb2ip 0.1.0.0' );

# Boundary: third octet
is( Geo::IPfree::ip2nb('0.0.1.0'), 256, 'ip2nb 0.0.1.0' );
is( Geo::IPfree::nb2ip(256), '0.0.1.0', 'nb2ip 0.0.1.0' );

# Boundary: last octet only
is( Geo::IPfree::ip2nb('0.0.0.1'), 1, 'ip2nb 0.0.0.1 = 1' );
is( Geo::IPfree::nb2ip(1), '0.0.0.1', 'nb2ip 1 = 0.0.0.1' );

# Roundtrip: various IPs
my @ips = ( '10.20.30.40', '192.168.1.1', '172.16.0.1', '8.8.8.8', '224.0.0.1' );
for my $ip (@ips) {
    my $nb = Geo::IPfree::ip2nb($ip);
    is( Geo::IPfree::nb2ip($nb), $ip, "roundtrip $ip" );
}
