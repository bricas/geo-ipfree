use strict;
use warnings;

use Test::More tests => 5;

use Geo::IPfree;

# Test 1: nslookup returns empty string when inet_aton returns undef (DNS failure)
{
    no warnings 'redefine';
    local *Socket::inet_aton = sub { return undef };
    my $result = Geo::IPfree::nslookup('nonexistent.invalid');
    is( $result, '', 'nslookup returns empty string when DNS fails' );
}

# Test 2: nslookup returns empty string when inet_aton returns packed 0.0.0.0
{
    no warnings 'redefine';
    local *Socket::inet_aton = sub { return "\0\0\0\0" };
    my $result = Geo::IPfree::nslookup('nonexistent.invalid');
    is( $result, '', 'nslookup returns empty string for 0.0.0.0 response' );
}

# Test 3: nslookup retries with www. prefix before giving up
{
    no warnings 'redefine';
    my @calls;
    local *Socket::inet_aton = sub { push @calls, $_[0]; return undef };
    Geo::IPfree::nslookup('example.invalid');
    is( scalar @calls, 2, 'nslookup tries twice (with and without www.)' );
    is( $calls[1], 'www.example.invalid', 'second attempt prepends www.' );
}

# Test 4: nslookup returns valid IP when inet_aton succeeds
{
    no warnings 'redefine';
    local *Socket::inet_aton = sub { return pack( 'C4', 93, 184, 216, 34 ) };
    my $result = Geo::IPfree::nslookup('example.com');
    is( $result, '93.184.216.34', 'nslookup returns dotted IP on success' );
}
