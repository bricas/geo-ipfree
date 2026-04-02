use strict;
use warnings;

use Test::More;

use Geo::IPfree;

my $g = Geo::IPfree->new;

# Verify cache is enabled and starts at 0
ok( $g->{cache}, 'cache is enabled by default' );
is( $g->{CACHE_COUNT}, 0, 'CACHE_COUNT starts at 0' );

# Fill cache with unique IPs to exceed the eviction threshold
# The default $cache_expire is 5000, but we'll test with fewer lookups
# by verifying the counter tracks correctly

# Do a few lookups and check CACHE_COUNT tracks
$g->LookUp('200.160.7.0');
is( $g->{CACHE_COUNT}, 1, 'CACHE_COUNT increments after first lookup' );

$g->LookUp('209.173.53.0');
is( $g->{CACHE_COUNT}, 2, 'CACHE_COUNT increments after second lookup' );

# Cache hit should NOT increment CACHE_COUNT
$g->LookUp('200.160.7.2');    # same /24 as 200.160.7.0 -> cache hit
is( $g->{CACHE_COUNT}, 2, 'CACHE_COUNT unchanged on cache hit' );

# Now test eviction by manually setting CACHE_COUNT near the threshold
$g->{CACHE_COUNT} = 4999;

$g->LookUp('192.134.4.0');
is( $g->{CACHE_COUNT}, 5000, 'CACHE_COUNT reaches threshold' );

# Next unique lookup should trigger eviction
my $cache_before = scalar keys %{ $g->{CACHE} };
$g->LookUp('80.67.169.0');
is( $g->{CACHE_COUNT}, 5000, 'CACHE_COUNT stays at threshold after eviction (evict + add)' );

# Verify CACHE_COUNT doesn't freeze: do more lookups
$g->LookUp('1.2.3.0');
is( $g->{CACHE_COUNT}, 5000, 'CACHE_COUNT stays stable across multiple evictions' );

$g->LookUp('4.5.6.0');
is( $g->{CACHE_COUNT}, 5000, 'CACHE_COUNT remains at threshold, not frozen above it' );

# Clean cache and verify count resets
$g->Clean_Cache();
is( $g->{CACHE_COUNT}, 0, 'CACHE_COUNT resets after Clean_Cache' );

done_testing;
