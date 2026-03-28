use strict;
use warnings;

use Test::More tests => 13;

use Geo::IPfree;

{    # localhost
    my ( $country, $country_name, $ip ) = Geo::IPfree::LookUp('127.0.0.1');
    is( $country,      'ZZ' );
    is( $country_name, 'Reserved for private IP addresses' );
}

{    # intranet
    my ( $country, $country_name, $ip ) = Geo::IPfree::LookUp('10.0.0.1');
    is( $country,      'ZZ' );
    is( $country_name, 'Reserved for private IP addresses' );
}

{    # www.nic.br
    my ( $country, $country_name, $ip ) = Geo::IPfree::LookUp('200.160.7.2');
    is( $country,      'BR' );
    is( $country_name, 'Brazil' );
}

{    # www.nic.us
    my ( $country, $country_name, $ip ) = Geo::IPfree::LookUp('209.173.53.26');
    is( $country,      'US' );
    is( $country_name, 'United States' );
}

{    # www.nic.fr
    my ( $country, $country_name, $ip ) = Geo::IPfree::LookUp('192.134.4.20');
    is( $country,      'FR' );
    is( $country_name, 'France' );
}

{    # functional LoadDB with custom db path
    use File::Basename;
    my $db = dirname( $INC{'Geo/IPfree.pm'} ) . '/ipscountry.dat';
    Geo::IPfree::LoadDB($db);
    my ( $country, $country_name ) = Geo::IPfree::LookUp('200.160.7.2');
    is( $country,      'BR',     'functional LoadDB + LookUp country code' );
    is( $country_name, 'Brazil', 'functional LoadDB + LookUp country name' );
}

SKIP: {    # does not exist
    my @result = Geo::IPfree::LookUp('dne.undef');
    skip '"dne.undef" should not resolve, but it does for you.', 1
      if @result == 3;
    is( scalar @result, 0, 'undef result' );
}
