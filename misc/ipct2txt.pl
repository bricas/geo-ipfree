#!/usr/bin/perl

use strict;
use warnings;

require Geo::IPfree;

##################################
# CONVERT IPSCOUNTRY.DAT TO TXT  #
##################################

my $ipsdb_fl  = $ARGV[ 0 ] || './ipscountry.dat';
my $ipstxt_fl = $ARGV[ 1 ] || './ips-ascii.txt';

my @baseX  = (
    0 .. 9,
    'A' .. 'Z',
    'a' .. 'z',
    split( m{}, q(.,;'"`<>{}[]=+-~*@#%$&!?) )
);

if ( $ARGV[ 0 ] =~ /^-+h/i || $#ARGV < 1 ) {
    print qq`
________________________________________________________

This tool will convert a Geo::IPfree dat file to ASCII.

  USE: perl $0 ./ipscountry.dat ./ips-ascii.txt

Enjoy! :-P
________________________________________________________
`;

    exit;
}

my $buffer;

open( LOG, $ipsdb_fl );

while ( sysread( LOG, $buffer, 1, length( $buffer ) ) ) {
    if ( $buffer =~ /##start##$/s ) { last; }
}

my @IPS;

my $c = 0;
while ( sysread( LOG, $buffer, 7 ) ) {
    my $country = substr( $buffer, 0, 2 );
    my $iprange = substr( $buffer, 2 );

    my $range = Geo::IPfree::baseX2dec( $iprange );

    my $ip      = Geo::IPfree::nb2ip( $range );
    my $ip_prev = Geo::IPfree::nb2ip( $range - 1 );

    push( @IPS, $country, $ip, $ip_prev );
    $c += 3;

    print ".";
}

print "\n\nSaving...\n";

my @OUT;

for ( my $i = 0; $i <= $#IPS; $i += 3 ) {
    my $ct     = $IPS[ $i ];
    my $ip     = $IPS[ $i + 1 ];
    my $ipprev = $IPS[ $i - 1 ];

    if ( $ip ne '1.0.0.0.0' && $ct =~ /[\w-]{2}/ ) {
        push( @OUT, "$ct: $ip $ipprev" );
    }

}

open( NEWLOG, ">$ipstxt_fl" );
foreach my $OUT_i ( reverse @OUT ) {
    print NEWLOG "$OUT_i\n";
}
close( NEWLOG );

close( LOG );

print "\nOK! $ipstxt_fl created!\n";
