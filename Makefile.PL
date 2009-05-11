use strict;
use warnings;

use ExtUtils::MakeMaker;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Geo/IPfree.pm > README' );
}

WriteMakefile(
    DISTNAME      => 'Geo-IPfree',
    NAME          => 'Geo::IPfree',
    AUTHOR        => 'Graciliano M. P. <gm@virtuasites.com.br>',
    ABSTRACT_FROM => 'lib/Geo/IPfree.pm',
    VERSION_FROM  => 'lib/Geo/IPfree.pm',
    (   eval { ExtUtils::MakeMaker->VERSION( 6.21 ) }
        ? ( LICENSE => 'perl' )
        : ()
    ),
    PREREQ_PM => {
        'Test::More' => '0.47',
        'Memoize'    => 0,
    },
);

