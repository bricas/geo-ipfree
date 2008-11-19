####################
# GEO::IPFREE TEST #
####################

use Test;
BEGIN { plan tests => 5 };
use Geo::IPfree;

######################### localhost

my ($country,$country_name,$ip) = Geo::IPfree::LookUp("127.0.0.1") ;
ok($country,'L0');

######################### intranet

my ($country,$country_name,$ip) = Geo::IPfree::LookUp("10.0.0.1") ;
ok($country,'I0');

######################### www.nic.br

my ($country,$country_name,$ip) = Geo::IPfree::LookUp("200.160.7.2") ;
ok($country,'BR');

######################### www.nic.us

my ($country,$country_name,$ip) = Geo::IPfree::LookUp("209.173.53.26") ;
ok($country,'US');

######################### www.nic.fr

my ($country,$country_name,$ip) = Geo::IPfree::LookUp("192.134.4.20") ;
ok($country,'FR');

#########################


