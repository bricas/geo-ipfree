#############################################################################
## Name:        Geo/IPfree.pm
## Purpose:     Look up country of IP Address.
## Author:      Graciliano M. P.
## Modified by:
## Created:     20/10/2002
## RCS-ID:      
## Copyright:   (c) 2002 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################
#
# Laurent Destailleur improvements:
# - Changed "sysread" to "read".
#  for cleaner code, better compatibility and to fix bug of using not always working 'tell' with 'sysread'.
# - Added $this->{searchorder}, for speed improvment, avoiding sort for each lookup.
# - Trap errors on open().
#

package Geo::IPfree;
use 5.006;
use Memoize;
use Carp qw() ;
use strict qw(vars) ;

require Exporter;
our @ISA = qw(Exporter);

our $VERSION = '0.2';

our @EXPORT = qw(LookUp LoadDB) ;
our @EXPORT_OK = @EXPORT ;

my $def_db = 'ipscountry.dat' ;

my @baseX = qw(0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z . , ; ' " ` < > { } [ ] = + - ~ * @ # % $ & ! ?) ;

my %countrys = qw(
-- N/A L0 localhost I0 IntraNet A1 Anonymous_Proxy A2 Satellite_Provider
AD Andorra AE United_Arab_Emirates AF Afghanistan AG Antigua_and_Barbuda AI Anguilla AL Albania AM Armenia AN Netherlands_Antilles 
AO Angola AP Asia/Pacific_Region AQ Antarctica AR Argentina AS American_Samoa AT Austria AU Australia AW Aruba AZ Azerbaijan BA Bosnia_and_Herzegovina BB Barbados BD Bangladesh 
BE Belgium BF Burkina_Faso BG Bulgaria BH Bahrain BI Burundi BJ Benin BM Bermuda BN Brunei_Darussalam BO Bolivia BR Brazil BS Bahamas BT Bhutan BV Bouvet_Island BW Botswana 
BY Belarus BZ Belize CA Canada CC Cocos_(Keeling)_Islands CD Congo,_The_Democratic_Republic_of_the CF Central_African_Republic CG Congo CH Switzerland CI Cote_D'Ivoire CK Cook_Islands 
CL Chile CM Cameroon CN China CO Colombia CR Costa_Rica CU Cuba CV Cape_Verde CX Christmas_Island CY Cyprus CZ Czech_Republic DE Germany DJ Djibouti DK Denmark DM Dominica 
DO Dominican_Republic DZ Algeria EC Ecuador EE Estonia EG Egypt EH Western_Sahara ER Eritrea ES Spain ET Ethiopia EU Europe FI Finland FJ Fiji FK Falkland_Islands_(Malvinas) 
FM Micronesia,_Federated_States_of FO Faroe_Islands FR France FX France,_Metropolitan GA Gabon GB United_Kingdom GD Grenada GE Georgia GF French_Guiana GH Ghana GI Gibraltar 
GL Greenland GM Gambia GN Guinea GP Guadeloupe GQ Equatorial_Guinea GR Greece GS South_Georgia_and_the_South_Sandwich_Islands GT Guatemala GU Guam GW Guinea-Bissau GY Guyana 
HK Hong_Kong HM Heard_Island_and_McDonald_Islands HN Honduras HR Croatia HT Haiti HU Hungary ID Indonesia IE Ireland IL Israel IN India IO British_Indian_Ocean_Territory 
IQ Iraq IR Iran,_Islamic_Republic_of IS Iceland IT Italy JM Jamaica JO Jordan JP Japan KE Kenya KG Kyrgyzstan KH Cambodia KI Kiribati KM Comoros KN Saint_Kitts_and_Nevis 
KP Korea,_Democratic_People's_Republic_of KR Korea,_Republic_of KW Kuwait KY Cayman_Islands KZ Kazakhstan LA Lao_People's_Democratic_Republic LB Lebanon LC Saint_Lucia LI Liechtenstein 
LK Sri_Lanka LR Liberia LS Lesotho LT Lithuania LU Luxembourg LV Latvia LY Libyan_Arab_Jamahiriya MA Morocco MC Monaco MD Moldova,_Republic_of MG Madagascar MH Marshall_Islands 
MK Macedonia,_the_Former_Yugoslav_Republic_of ML Mali MM Myanmar MN Mongolia MO Macau MP Northern_Mariana_Islands MQ Martinique MR Mauritania MS Montserrat MT Malta MU Mauritius 
MV Maldives MW Malawi MX Mexico MY Malaysia MZ Mozambique NA Namibia NC New_Caledonia NE Niger NF Norfolk_Island NG Nigeria NI Nicaragua NL Netherlands NO Norway NP Nepal 
NR Nauru NU Niue NZ New_Zealand OM Oman PA Panama PE Peru PF French_Polynesia PG Papua_New_Guinea PH Philippines PK Pakistan PL Poland PM Saint_Pierre_and_Miquelon PN Pitcairn 
PR Puerto_Rico PS Palestinian_Territory,_Occupied PT Portugal PW Palau PY Paraguay QA Qatar RE Reunion RO Romania RU Russian_Federation RW Rwanda SA Saudi_Arabia SB Solomon_Islands 
SC Seychelles SD Sudan SE Sweden SG Singapore SH Saint_Helena SI Slovenia SJ Svalbard_and_Jan_Mayen SK Slovakia SL Sierra_Leone SM San_Marino SN Senegal SO Somalia SR Suriname 
ST Sao_Tome_and_Principe SV El_Salvador SY Syrian_Arab_Republic SZ Swaziland TC Turks_and_Caicos_Islands TD Chad TF French_Southern_Territories TG Togo TH Thailand TJ Tajikistan 
TK Tokelau TM Turkmenistan TN Tunisia TO Tonga TP East_Timor TR Turkey TT Trinidad_and_Tobago TV Tuvalu TW Taiwan,_Province_of_China TZ Tanzania,_United_Republic_of UA Ukraine 
UG Uganda UM United_States_Minor_Outlying_Islands US United_States UY Uruguay UZ Uzbekistan VA Holy_See_(Vatican_City_State) VC Saint_Vincent_and_the_Grenadines VE Venezuela 
VG Virgin_Islands,_British VI Virgin_Islands,_U.S. VN Vietnam VU Vanuatu WF Wallis_and_Futuna WS Samoa YE Yemen YT Mayotte YU Yugoslavia ZA South_Africa ZM Zambia ZR Zaire ZW Zimbabwe
) ;

my (%baseX,$base,$THIS) ;

my $cache_expire = 1000 ;

####################
# DECLARE BASE LIB #
####################

{
  my $c = 0 ;
  %baseX = map { $_ => ($c++) } @baseX ;
  $base = @baseX ;
  
  foreach my $Key ( keys %countrys ) { $countrys{$Key} =~ s/_/ /gs ;}
}

#######
# NEW #
#######

sub new {
  my ($class, $db_file) = @_ ;

  if ($#_ <= 0 && $_[0] !~ /^[\w:]+$/) {
    $class = 'Geo::IPfree' ;
    $db_file = $_[0] ;
  }
  
  my $this = {} ;
  bless($this , $class) ;

  if (!defined $db_file) { $db_file = &find_db_file ;}
  
  $this->{dbfile} = $db_file ;
  
  $this->LoadDB($db_file) ;
  
  $this->{cache} = 1 ;

  return( $this ) ;
}

##########
# LOADDB #
##########

sub LoadDB {
  my $this = shift ;
  my ( $db_file ) = @_ ;

  if (-d $db_file) { $db_file .= "/$def_db" ;}

  if (!-s $db_file) { Carp::croak("Can't load database, blank or not there: $db_file") ;}

  $this->{db} = $db_file ;

  my ($handler,$buffer) ;
  open($handler,$db_file) || Carp::croak("Failed to open database file $db_file for read!") ;
  binmode($handler) ;
  
  if ( $this->{pos} ) { delete($this->{pos}) ;}
  
  while( read($handler, $buffer , 1 , length($buffer) ) ) {
    if ($buffer =~ /##headers##(\d+)##$/s  ) {
      my $headers ;
      read($handler, $headers , $1 ) ;
      my (%head) = ( $headers =~ /(\d+)=(\d+)/gs );
      foreach my $Key ( keys %head ) { $this->{pos}{$Key} = $head{$Key} ;}
      $buffer = '' ;
    }
    elsif ($buffer =~ /##start##$/s  ) {
      $this->{start} = tell($handler) ;
      last ;
    }
  }
    
  @{$this->{searchorder}} = ( sort {$a <=> $b} keys %{$this->{pos}} ) ;
  
  $this->{handler} = $handler ;
}

##########
# LOOKUP #
##########

sub LookUp {
  my $this ;
  
  if ($#_ == 0) {
    if (!$THIS) { $THIS = Geo::IPfree->new() ;}
    $this = $THIS ;
  }
  else { $this = shift ;}

  my ( $ip ) = @_ ;
  
  $ip =~ s/\.+/\./gs ;
  $ip =~ s/^\.// ;
  $ip =~ s/\.$// ;
  
  if ($ip !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) { $ip = nslookup($ip) ;}

  ## Since the last class is always from the same country, will try 0 and cache 0:
  my $ip_class = $ip ;
  $ip_class =~ s/\.\d+$/\.0/ ;

  if ( $this->{cache} && $this->{CACHE}{$ip_class} ) { return( @{$this->{CACHE}{$ip_class}} , $ip_class ) ;}
  
  my $ipnb = ip2nb($ip_class) ;
  
  my $buf_pos = 0 ;

  foreach my $Key ( @{$this->{searchorder}} ) {
    if ($ipnb <= $Key) { $buf_pos = $this->{pos}{$Key} ; last ;}
  }
  
  my ($buffer,$country,$iprange) ;
  
  ## Will use the DB in the memory:
  if ( $this->{FASTER} ) {
    while($buf_pos < $this->{DB_SIZE}) {
      $buffer = substr($this->{DB} , $buf_pos , 7) ;
      $country = substr($buffer , 0 , 2) ;
      $iprange = baseX2dec( substr($buffer , 2 , 5) ) ;
      $buf_pos += 7 ;
      if ($ipnb >= $iprange) { last ;}
    }
  }
  ## Will read the DB in the disk:
  else {
    seek($this->{handler} , 0 , 0) if $] < 5.006001 ; ## Fix bug on Perl 5.6.0
    seek($this->{handler} , $buf_pos + $this->{start} , 0) ;
    while( read($this->{handler} , $buffer , 7) ) {
      $country = substr($buffer , 0 , 2) ;
      $iprange = baseX2dec( substr($buffer , 2) ) ;
      if ($ipnb >= $iprange) { last ;}
    }
  }
  
  if ( $this->{cache} ) {
    $this->{CACHE}{$ip_class} = [$country , $countrys{$country}] ;
    $this->{CACHE}{x}++ ;
    if ( $this->{CACHE}{x} > $cache_expire ) { $this->Clean_Cache ;}
  }

  return( $country , $countrys{$country} , $ip_class ) ;
}

##########
# FASTER #
##########

sub Faster {
  my $this = shift ;
  
  seek($this->{handler} , 0 , 0) ; ## Fix bug on Perl 5.6.0
  seek($this->{handler} , $this->{start} , 0) ;
  1 while( read($this->{handler}, $this->{DB} , 1024*4 , length($this->{DB}) ) ) ;
  
  $this->{DB_SIZE} = length($this->{DB}) ;

  memoize('dec2baseX') ;
  memoize('baseX2dec') ;

  ## Too many memory and not soo fast:
  #memoize('ip2nb') ;
  #memoize('nb2ip') ;
  
  $this->{FASTER} = 1 ;
}

###############
# CLEAN_CACHE #
###############

sub Clean_Cache { delete $_[0]->{CACHE} ; 1 ;}

############
# NSLOOKUP #
############

sub nslookup {
  my ( $host ) = @_ ;
  require Socket ;
  my $iaddr = Socket::inet_aton($host) ;
  my @ip = unpack('C4',$iaddr) ;
  if (! @ip && ! $_[1]) { return( &nslookup("www.$host",1) ) ;}
  return( join (".",@ip) ) ;
}

################
# FIND_DB_FILE #
################

sub find_db_file {
  my $lib_path ;

  foreach my $Key ( keys %INC ) {
    if ($Key =~ /^IPfree.pm$/i) {
      my ($lib) = ( $INC{$Key} =~ /^(.*?)[\\\/]+[^\\\/]+$/gs ) ;
      if (-e "$lib/$def_db") { $lib_path = $lib ; last ;}
    }
  }

  if ($lib_path eq '') {
    foreach my $INC_i ( @INC ) {
      my $lib = "$INC_i/Geo" ;
      if (-e "$lib/$def_db") { $lib_path = $lib ; last ;}
    }
  }
  
  if ($lib_path eq '') {
    foreach my $dir ( @INC , '/tmp' , '/usr/local/share' , '/usr/local/share/GeoIPfree' ) {
      if (-e "$dir/$def_db") { $lib_path = $dir ; last ;}
    }
  }
  
  return( "$lib_path/$def_db" ) ;
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

1;

__END__

=head1 NAME

Geo::IPfree - Look up country of IP Address. This module make this off-line and the DB of IPs is free & small.

=head1 SYNOPSIS

  use Geo::IPfree;
  my ($country,$country_name) = Geo::IPfree::LookUp("192.168.0.1") ;
  
  ... or ...
  
  use Geo::IPfree qw(LookUp) ;
  my ($country,$country_name) = LookUp("200.176.3.142") ;
  
  ... or ...

  use Geo::IPfree;
  my $GeoIP = Geo::IPfree->new('/GeoIPfree/ipscountry.dat') ;
  $GeoIP->Faster ; ## Enable the faster option.
  my ($country,$country_name,$ip) = $GeoIP->LookUp("www.cnn.com") ; ## Getting by Hostname.
  
  $GeoIP->LoadDB('/GeoIPfree/ips.dat') ;
  
  my ($country,$country_name,$ip) = $GeoIP->LookUp("www.sf.net") ; ## Getting by Hostname.
  
  ... or ...
  
  use Geo::IPfree;  
  my $GeoIP = Geo::IPfree::new() ; ## Using the default DB!
  my ($country,$country_name) = $GeoIP->LookUp("64.236.24.28") ;

=head1 DESCRIPTION

  This package comes with it's own database to look up the IP's country, and is totally free.
  
  Take a look in CPAN for updates...


=head1 METHODS

=over 4

=item LoadDB

Load the database to use to LookUp the IPs.

=item LookUp

Returns the ISO 3166 country (XX) code for an IP address or Hostname.

**If you send a Hostname you will need to be connected to the internet to resolve the host IP.

=item Clean_Cache

Clean the memory used by the cache.

=item Faster

Make the LookUp() faster, good for big amount of LookUp()s. This will load all the DB in the memory (200Kb) and read from there,
not from HD (good way for slow HD or network disks), but use more memory. The module "Memoize" will be enabled for some internal functions too.

Note that if you make a big amount of querys to LookUp(), in the end the amount of memory can be big, than is better to use more memory from the begin and make all faster.

=back

=head1 VARS

=over 4

=item $GeoIP->{db}

The database file in use.

=item $GeoIP->{handler}

The database file handler.

=item $GeoIP->{dbfile}

The database file path.

=item $GeoIP->{cache} BOOLEAN

Set/tell if the cache of LookUp() is on. If it's on it will cache the last 1000 querys. Default: 1

The cache is good when you are parsing a list of IPs, generally a web log.
If in the log you have many lines with the same IP, GEO::IPfree don't need to make a full search for each query,
it will cache the last 1000 different IPs. After each 1000 IPs the cache is cleaned to restart it.

Note that the Lookup make the query without the last IP number (xxx.xxx.xxx.0),
then the cache for the IP 192.168.0.1 will be the same for 192.168.0.2 (they are the same query, 192.168.0.0).

=back

=head1 DB FORMAT

the DB has a list of IP ranges & countrys, for example, from 200.128.0.0 to
200.103.255.255 the IPs are from BR. To make a fast access to the DB the format
try to use less bytes per input (block). The file was in ASCII and in blocks
of 7 bytes: XXnnnnn

  XX    -> the country code (BR,US...)
  nnnnn -> the IP range using a base of 85 digits
           (not in dec or hex to get space).

See CPAN for updates of the DB...

=head1 NOTES

The file ipscountry.dat is made only for Geo::IPfree and has their own format.
To convert it see the tool "ipct2txt.pl" in the same path of Geo/IPfree.pm.

=head1 CHAGES

0.2 - Sat Mar 22 18:10 2003

   - Change sysread() to read() for better portability.
   - Speed improvement for multiples LookUp().
     4 times faster!

0.01.1 - Nov 6 14:05:03 2002 (not released on CPAN)

   - Fix seek bug for Perl 5.6.0 on multiples LookUp().


=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>.

Thanks to Laurent Destailleur (author of AWStats) that tested it on many OS and
fixed bugs for them, like the not portable sysread, and asked for some speed improvement.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


