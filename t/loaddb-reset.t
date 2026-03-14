use strict;
use warnings;

use Test::More tests => 6;

use Geo::IPfree;

# LoadDB() must reset Faster() state so lookups use the newly loaded
# database from disk instead of stale in-memory data.

my $g = Geo::IPfree->new;
$g->Faster;

ok( $g->{FASTER},  'FASTER flag set after Faster()' );
ok( $g->{DB},      'DB loaded into memory after Faster()' );

# Reload the database
$g->LoadDB( $g->{dbfile} );

ok( !$g->{FASTER},  'FASTER flag cleared after LoadDB()' );
ok( !$g->{DB},      'in-memory DB cleared after LoadDB()' );
ok( !$g->{DB_SIZE}, 'DB_SIZE cleared after LoadDB()' );

# Lookups still work (using disk path now)
my ( $cc, $name ) = $g->LookUp('200.160.7.2');
is( $cc, 'BR', 'lookup works after LoadDB() reset (disk path)' );
