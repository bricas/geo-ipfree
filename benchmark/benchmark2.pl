#!/usr/bin/perl

use Geo::IPfree;


my $gi = Geo::IPfree::new();
$gi->Faster ;

my $timebefore=time();
print "$timebefore\n";
foreach my $j (100..200) {
	foreach my $i (100..200) {
		my ($res,$resname)=$gi->LookUp("$j.50.$i.50");
	}
}
my $timeafter=time();
print "$timeafter\n";
print "Last: ".($timeafter-$timebefore)." seconds\n";
print "Speed: ".(101*101/($timeafter-$timebefore)||1)." lookup/s\n";
my ($res,$resname)=$gi->LookUp("200.50.200.50");
print "Example of last lookup: $res $resname\n";

0;

