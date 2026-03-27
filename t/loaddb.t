use strict;
use warnings;

use Test::More tests => 11;
use File::Spec;

use_ok('Geo::IPfree');

# new() with no arguments finds the default DB
{
    my $g = Geo::IPfree->new;
    ok( $g, 'new() without arguments' );
    ok( $g->{dbfile},  'dbfile attribute set' );
    ok( $g->{handler}, 'file handler open' );
    ok( $g->{start},   'start position found' );
    ok( ref $g->{searchorder} eq 'ARRAY' && @{ $g->{searchorder} } > 0,
        'searchorder populated' );
}

# LoadDB with directory path (should auto-append ipscountry.dat)
{
    my $g    = Geo::IPfree->new;
    my $dir  = File::Spec->catpath( ( File::Spec->splitpath( $g->{dbfile} ) )[ 0, 1 ] );
    my $g2   = Geo::IPfree->new($dir);
    ok( $g2, 'new() with directory path' );
    ok( $g2->{start} > 0, 'DB loaded from directory' );
}

# LoadDB with nonexistent file should croak
{
    eval { Geo::IPfree->new('/nonexistent/path/to/db.dat') };
    like( $@, qr/Can't load database/, 'croak on missing DB file' );
}

# Reload DB preserves functionality
{
    my $g = Geo::IPfree->new;
    my ( $c1 ) = $g->LookUp('200.160.7.2');
    $g->LoadDB( $g->{dbfile} );
    my ( $c2 ) = $g->LookUp('200.160.7.2');
    is( $c1, $c2, 'reload DB gives consistent results' );
}

# searchorder is sorted ascending
{
    my $g      = Geo::IPfree->new;
    my @sorted = sort { $a <=> $b } @{ $g->{searchorder} };
    is_deeply( $g->{searchorder}, \@sorted, 'searchorder is sorted ascending' );
}
