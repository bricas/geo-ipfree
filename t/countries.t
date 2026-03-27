use strict;
use warnings;

use Test::More tests => 8;

use_ok('Geo::IPfree');

# get_all_countries returns a hashref
{
    my $g         = Geo::IPfree->new;
    my $countries = $g->get_all_countries;
    ok( ref $countries eq 'HASH', 'returns a hashref' );

    # Spot-check well-known country codes
    is( $countries->{US}, 'United States',  'US present' );
    is( $countries->{GB}, 'United Kingdom', 'GB present' );
    is( $countries->{FR}, 'France',         'FR present' );
    is( $countries->{JP}, 'Japan',          'JP present' );
    is( $countries->{ZZ}, 'Reserved for private IP addresses', 'ZZ present' );
}

# Returned hash is a copy (modifying it doesn't affect internal state)
{
    my $g    = Geo::IPfree->new;
    my $copy = $g->get_all_countries;
    $copy->{US} = 'MODIFIED';
    my $fresh = $g->get_all_countries;
    is( $fresh->{US}, 'United States', 'returned hash is a copy' );
}
