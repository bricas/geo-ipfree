#!/usr/bin/perl

use strict;
use warnings;

use Benchmark;
use Geo::IPfree;

my $geo = Geo::IPfree->new();
if( defined $ENV{ GEOIP_FASTER } ) {
    print "Geo::IPfree->Faster enabled.\n";
    $geo->Faster;
}
else {
    print "Geo::IPfree->Faster not enabled, set GEOIP_FASTER=1 to benchmark it.\n";
}

timethese( 5000,
    { geo_lookup => sub { my @ret = $geo->LookUp( rand_ip() ); } } );

sub rand_ip {
    return join( '.',
        int( rand( 255 ) ),
        int( rand( 255 ) ),
        int( rand( 255 ) ),
        int( rand( 255 ) ) );
}
