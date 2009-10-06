use strict;
use warnings;

use Test::More 'no_plan';

use_ok( 'Geo::IPfree' );

my @b86 = ( 0 .. 9, 'A' .. 'Z', 'a' .. 'z', split( m{}, q(.,;'"`<>{}[]=+-~*@#%$&!?) ) );

for( 0..85 ) {
    is( Geo::IPfree::dec2baseX( $_ ), sprintf( '%05s', $b85[ $_ ] ), "dec2baseX( '$_' )" );
    is( Geo::IPfree::baseX2dec( $b85[ $_ ] ), $_, "baseX2dec( '$b85[ $_ ]' )" );
}
