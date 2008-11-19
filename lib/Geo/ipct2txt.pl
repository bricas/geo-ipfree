#!/usr/bin/perl

##################################
# CONVERT IPSCOUNTRY.DAT TO TXT  #
##################################

  my $ipsdb_fl = $ARGV[0] || './ipscountry.dat' ;
  my $ipstxt_fl = $ARGV[1] || './ips-ascii.txt' ;
  
  my @baseX = qw(0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z . , ; ' " ` < > { } [ ] = + - ~ * @ # % $ & ! ?) ;
  
  if ( $ARGV[0] =~ /^-+h/i || $#ARGV < 1 ) {
print qq`
________________________________________________________

This tool will convert a Geo::IPfree dat file to ASCII.

  USE: perl $0 ./ipscountry.dat ./ips-ascii.txt

Enjoy! :-P
________________________________________________________
`;

exit ;
  }
  
########
# INIT #
########
  
  my $buffer ;
  
  open (LOG,$ipsdb_fl) ;
  
  while( sysread(LOG, $buffer , 1 , length($buffer) ) ) {
    if ($buffer =~ /##start##$/s  ) { last ;}
  }

  my @IPS ;

  my $c = 0 ;
  while( sysread(LOG, $buffer , 7) ) {
    my $country = substr($buffer , 0 , 2) ;
    my $iprange = substr($buffer , 2) ;
    
    my $range = baseX2dec($iprange) ;

    my $ip = nb2ip($range) ;
    my $ip_prev = nb2ip($range-1) ;
    
    push(@IPS , $country , $ip , $ip_prev) ;
    $c+=3 ;
    
    print "." ;
  }
  
  print "\n\nSaving...\n" ;
  
  my @OUT ;
  
  for (my $i = 0 ; $i <= $#IPS ; $i+=3) {
    my $ct = @IPS[$i] ;
    my $ip = @IPS[$i+1] ;
    my $ipprev = @IPS[$i-1] ;
    
    if ($ip ne '1.0.0.0.0' && $ct =~ /[\w-]{2}/) {
      push(@OUT , "$ct: $ip $ipprev") ;    
    }

  }
  
  open (NEWLOG,">$ipstxt_fl") ;
    foreach my $OUT_i ( reverse @OUT ) {
      print NEWLOG "$OUT_i\n" ;
    }
  close(NEWLOG) ;
  
  close (LOG) ;
  
  print "\nOK! $ipstxt_fl created!\n" ;

#############
# BASEX2DEC #
#############

sub baseX2dec {
  my ( $baseX ) = @_ ;
  
  if (! %baseX ) {
    my $c = 0 ;
    %baseX = map { $_ => ($c++) } @baseX ;
  }
  
  my $base = @baseX ;

  @base = split("" , $baseX) ;
  
  my $dec ;
  
  my $i = -1 ;
  foreach my $base_i ( reverse @base ) {
    $i++ ;
    my $n = $baseX{$base_i} ;
    
    $dec += $n * ($base**$i) ;
  }
  
  return( $dec ) ;
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

    my $r = $x - ($ci*256) ;
    push(@ip , $r) ;

    $x = $ci ;
  }
  
  push(@ip , $x) if $x > 0 ;
  
  while( $#ip < 3 ) { push(@ip , 0) ;}
  
  @ip = reverse (@ip) ;
    
  return( join (".", @ip) ) ;
}

#######
# END #
#######



