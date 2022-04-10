# NAME

Geo::IPfree - Geo::IPfree - Look up the country of an IPv4 address

# VERSION

version 1.160001

# SYNOPSIS

```perl
use Geo::IPfree;

my $geo = Geo::IPfree->new;
my( $code1, $name1 ) = $geo->LookUp( '200.176.3.142' );

# use memory to speed things up
$geo->Faster;

# lookup by hostname
my( $code2, $name2, $ip2 ) = $geo->LookUp( 'www.cnn.com' );
```

# DESCRIPTION

Geo::IPfree is a Perl module that determines the originating country of an
arbitrary IPv4 address. It uses a local file-based database to provide basic
geolocation services.

An updated version of the database can be obtained by visiting the Webnet77 
website: [http://software77.net/geo-ip/](http://software77.net/geo-ip/).

# METHODS

## new( \[$db\] )

Creates a new Geo::IPfree instance. Optionally, a database filename may be
passed in to load a custom data set rather than the version shipped with the
module.

## LoadDB( $filename )

Load a specific database to use to look up the IP addresses.

## LookUp( $ip | $hostname )

Given an IP address or a hostname, this function returns three things:

- The ISO 3166 country code (2 chars)
- The country name
- The IP address resolved

**NB:** In order to use the location services on a hostname, you will need
to have an internet connection to resolve a host to an IP address.

If you pass a private IP address (for example 192.168.0.1), you'll get back a country
code of ZZ, and country name of "Reserved for private IP addresses".

## Clean\_Cache( )

Clears any cached lookup data.

## Faster( )

Make the LookUp() faster, which is good if you're going to be calling Lookup() many times. This will load the entire DB into memory and read from there,
not from disk (good way for slow disk or network disks), but use more memory. The module "Memoize" will be enabled for some internal functions too.

Note that if you call Lookup() many times, you'll end up using a lot of memory anyway, so you'll be better off using a lot of memory from the start by calling Faster(),
and getting an improvement for all calls.

## nslookup( $host, \[$last\_lookup\] )

Attempts to resolve a hostname to an IP address. If it fails on the first pass
it will attempt to resolve the same hostname with 'www.' prepended. `$last_lookup`
is used to suppress this behavior.

## ip2nb( $ip )

Encodes `$ip` into a numerical representation.

## nb2ip( $number )

Decodes `$number` back to an IP address.

## dec2baseX( $number )

Converts a base 10 (decimal) number to base 86.

## baseX2dec( $number )

Converts a base 86 number to base 10 (decimal).

## get\_all\_countries()

Returns one Hash Ref with the list of known countries.
The key is the ISO 3166 country code (2 chars) and the value the country name in english.

Example:

```perl
     {
       '--' => 'N/A',
       'A1' => 'Anonymous Proxy',
       'A2' => 'Satellite Provider',
       'AC' => 'Ascension Island',
       'AD' => 'Andorra',
       'AE' => 'United Arab Emirates',
       'AF' => 'Afghanistan',
       'AG' => 'Antigua and Barbuda',
       ...
    }
```

# VARS

- $GeoIP->{db}

    The database file in use.

- $GeoIP->{handler}

    The database file handler.

- $GeoIP->{dbfile}

    The database file path.

- $GeoIP->{cache} BOOLEAN

    Set/tell if the cache of LookUp() is on. If it's on it will cache the last 5000 queries. Default: 1

    The cache is good when you are parsing a list of IPs, generally a web log.
    If in the log you have many lines with the same IP, GEO::IPfree won't have to make a full search for each query,
    it will cache the last 5000 different IPs. After 5000 IPs an existing IP is removed from the cache and the new
    data is stored.

    Note that the Lookup make the query without the last IP number (xxx.xxx.xxx.0),
    then the cache for the IP 192.168.0.1 will be the same for 192.168.0.2 (they are the same query, 192.168.0.0).

# DB FORMAT

The data file has a list of IP ranges & countries, for example, from 200.128.0.0 to
200.103.255.255 the IPs are from BR. To make a fast access to the DB the format
tries to use less bytes per input (block). The file was in ASCII and in blocks
of 7 bytes: XXnnnnn

```
XX    -> the country code (BR,US...)
nnnnn -> the IP range using a base of 85 digits
         (not in dec or hex to get space).
```

See CPAN for updates of the DB...

# NOTES

The file ipscountry.dat is a dedicated format for Geo::IPfree.
To convert it see the tool "ipct2txt.pl" in the `misc` directory.

The module looks for `ipscountry.dat` in the following locations:

- /usr/local/share
- /usr/local/share/GeoIPfree
- through @INC (as well as all @INC directories plus "/Geo")
- from the same location that IPfree.pm was loaded

# SEE ALSO

- http://software77.net/geo-ip/

# MAINTAINER

Brian Cassidy <bricas@cpan.org>

# THANK YOU

Thanks to Laurent Destailleur (author of AWStats) that tested it on many OS and
fixed bugs for them, like the not portable sysread, and asked for some speed improvement.

# AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Graciliano M. P.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
