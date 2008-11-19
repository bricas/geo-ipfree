#!/usr/bin/perl

##################################
# CONVERT IPSCOUNTRY.DAT TO TXT  #
##################################

  my $ipstxt_fl = $ARGV[0] || './ips-ascii.txt' ;
  my $ipsdb_fl = $ARGV[1] || './ipscountry.dat' ;
  
  my $HEADERS_BLKS = 256 ;
  
  my @baseX = qw(0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z . , ; ' " ` < > { } [ ] = + - ~ * @ # % $ & ! ?) ;
  
  my (%baseX,$base) ;

####################
# DECLARE BASE LIB #
####################

{
  my $c = 0 ;
  %baseX = map { $_ => ($c++) } @baseX ;
  $base = @baseX ;
  
  foreach my $Key ( keys %countrys ) { $countrys{$Key} =~ s/_/ /gs ;}
}

########
# HELP #
########
  
  if ( $ARGV[0] =~ /^-+h/i || $#ARGV < 1 ) {
print qq`
_________________________________________________________

This tool will convert the ASCII database (from ipct2txt)
to Geo::IPfree dat file.

  USE: perl $0 ./ips-ascii.txt ./ipscountry.dat

Enjoy! :-P
_________________________________________________________
`;

exit ;
}

########
# INIT #
########

  my @DB ;
  
  print "Reading...\n" ;

  open (LOG,$ipstxt_fl) ;
  while ($line = <LOG>) {
    my ($country,$ip0,$ip1) = ( $line =~ /([\w-]{2}):\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+\.\d+\.\d+\.\d+)/gs );
    
    my $range = ip2nb($ip0) ;
    my $iprange = dec2baseX($range);
    
    push(@DB , "$country$iprange") ;
  }
  close (LOG) ;
  
  @DB = reverse @DB ;
  
  my %headers ;
  
  my (%headers,$c) ;
  my $pos = 0 ;
  
  my $blk_sz = int ( ($#DB+1) / $HEADERS_BLKS ) ;
  
  print "BLK size: $blk_sz\n" ;

  foreach my $DB_i ( @DB ) {
    if ($c == 0) {
      #my $country = substr($DB_i , 0 , 2) ;
      my $iprange = substr($DB_i , 2) ;
      my $range = baseX2dec($iprange) ;
      $headers{$range} = $pos ;
    }
    $c++ ;
    
    if ($c >= $blk_sz) { $c = 0 ;}
    $pos+=7 ;
  }
  
  print "Saving...\n" ;
  
  open (NEWLOG,">$ipsdb_fl") ;
  my $sel= select(NEWLOG); $|=1; select($sel);
  
  my $date = &get_date ;
  
print NEWLOG qq`###############################################################
## IPs COUNTRY DATABASE ($date)                ##
###############################################################
## This is the database used in the Perl module GeoIPfree.   ##
##                                                           ##
## FORMAT:                                                   ##
##                                                           ##
##   the DB has a list of IP ranges & countrys, for          ##
##   example, from 200.128.0.0 to 200.103.255.255 the IPs    ##
##   are from BR. To make a fast access to the DB the        ##
##   format try to use less bytes per input (block). The     ##
##   file was in ASCII and in blocks of 7 bytes: XXnnnnn     ##
##                                                           ##
##     XX    -> the country code (BR,US...)                  ##
##     nnnnn -> the IP range using a base of 85 digits       ##
##              (not in dec or hex to get space).            ##
##                                                           ##
##  To convert this file to another format see the tool      ##
##  ipct2txt.pl in the same directory of Geo/IPfree.pm       ##
##                                                           ##
## See CPAN for updates...                                   ##
###############################################################

`;

  print NEWLOG "\n##headers##" ;
  my $headers ;
  foreach my $Key (sort {$b <=> $a} keys %headers ) {
    $headers .= "$Key=$headers{$Key}#" ;
  }
  print NEWLOG length($headers) . "##$headers" ;

  print NEWLOG "\n\n##start##" ;
  foreach my $DB_i ( @DB ) { print NEWLOG $DB_i ;}
  
  print "\nOK! $ipsdb_fl created\n" ;
  
############
# GET_DATE #
############

sub get_date {

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

  $mon++ ;
  $year += 1900 ;
  
  $sec = "0$sec" if $sec < 10 ;
  $min = "0$min" if $min < 10 ;
  $hour = "0$hour" if $hour < 10 ;
  
  $mday = "0$mday" if $mday < 10 ;
  $mon = "0$mon" if $mon < 10 ;

  return( "$year-$mon-$mday $hour:$min:$sec" ) ;
}

#########
# IP2NB #
#########

sub ip2nb {
  my @ip = split(/\./ , $_[0]) ;
  #return( 16777216* $ip[0] + 65536* $ip[1] + 256* $ip[2] + $ip[3] ) ;
  return( ($ip[0]<<24) + ($ip[1]<<16) + ($ip[2]<<8) + $ip[3] ) ;
}

#########
# NB2IP #
#########

sub nb2ip {
  my ( $ipn ) = @_ ;
  
  my @ip ;
  
  my $x = $ipn ;
  
  while($x > 1) {
    my $c = $x / 256 ;
    my $ci = int($x / 256) ;
    #push(@ip , $x - ($ci*256)) ;
    push(@ip , $x - ($ci<<8)) ;
    $x = $ci ;
  }
  
  push(@ip , $x) if $x > 0 ;
  
  while( $#ip < 3 ) { push(@ip , 0) ;}
  
  @ip = reverse (@ip) ;
    
  return( join (".", @ip) ) ;
}
 
#############
# DEC2BASEX #
#############

sub dec2baseX {
  my ( $dec ) = @_ ;
  
  my @base ;
  my $x = $dec ;
  
  while($x > 1) {
    my $c = $x / $base ;
    my $ci = int($x / $base) ;
    push(@base , $x - ($ci*$base) ) ;
    $x = $ci ;
  }
  
  push(@base , $x) if $x > 0 ;
  
  while( $#base < 4 ) { push(@base , 0) ;}
  
  my $baseX ;
  
  foreach my $base_i ( reverse @base ) {
    $baseX .= $baseX[$base_i] ;
  }
  
  return( $baseX ) ;
}

#############
# BASEX2DEC #
#############

sub baseX2dec {
  my ( $baseX ) = @_ ;
  
  my @base = split("" , $baseX) ;
  my $dec ;

  my $i = -1 ;
  foreach my $base_i ( reverse @base ) {
    $i++ ;
    $dec += $baseX{$base_i} * ($base**$i) ;
  }

  return( $dec ) ;
}

#######
# END #
#######

