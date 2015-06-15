#!/usr/bin/perl

use strict;
use warnings;

use Benchmark;
use Geo::IPfree;

my $count = shift || 5000;
my @ips;
push @ips, rand_ip() for 1..$count;
@ips = (@ips) x 2;
my @ips_faster = @ips;

my $geo = Geo::IPfree->new();
$geo->{ cache } = 0;

my $geo_faster = Geo::IPfree->new();
$geo_faster->Faster();

timethese( $count * 2,
    {
        geo => sub { $geo->LookUp( pop @ips ); },
        geo_faster => sub { $geo_faster->LookUp( pop @ips_faster ); }
    }
);

sub rand_ip {
    return join( '.',
        int( rand( 255 ) ),
        int( rand( 255 ) ),
        int( rand( 255 ) ),
        int( rand( 255 ) ) );
}
