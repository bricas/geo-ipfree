use strict;
use warnings;

use Test::More tests => 11;

use Geo::IPfree;


{ # localhost
    my ($country,$country_name,$ip) = Geo::IPfree::LookUp("127.0.0.1") ;
    is($country,'ZZ');
    ok(!defined $country_name);
}

{ # intranet
    my ($country,$country_name,$ip) = Geo::IPfree::LookUp("10.0.0.1") ;
    is($country,'ZZ');
    ok(!defined $country_name);
}

{ # www.nic.br
    my ($country,$country_name,$ip) = Geo::IPfree::LookUp("200.160.7.2") ;
    is($country,'BR');
    is($country_name, 'Brazil');
}

{ # www.nic.us
    my ($country,$country_name,$ip) = Geo::IPfree::LookUp("209.173.53.26") ;
    is($country,'US');
    is($country_name, 'United States');
}

{ # www.nic.fr
    my ($country,$country_name,$ip) = Geo::IPfree::LookUp("192.134.4.20") ;
    is($country,'EU');
    is($country_name, 'Europe');
}

{ # does not exist
    ok( !defined Geo::IPfree::LookUp('dne.undef') );
}
