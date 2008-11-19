#!/usr/bin/perl

use Benchmark ;
use Geo::IPfree;

my $GEO = Geo::IPfree->new() ;

$GEO->Faster ;

timethese (5000, {t1 => sub { &TEST ;} });

sub TEST {
  my @ret = $GEO->LookUp(rand_ip()) ;
#  print ">> @ret\n" ;
#  Geo::IPfree::LookUp(rand_ip()) ;
#  Geo::IPfree::LookUp(rand_ip()) ;
#  Geo::IPfree::LookUp(rand_ip()) ;
#  Geo::IPfree::LookUp(rand_ip()) ;
#  Geo::IPfree::LookUp(rand_ip()) ;
}

###########
# RAND_IP #
###########

sub rand_ip {
  return( int(rand(255)) .'.'. int(rand(255)) .'.'. int(rand(255)) .'.'. int(rand(255))) ;
}

#######
# END #
#######


