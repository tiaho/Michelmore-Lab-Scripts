#!usr/bin/perl
# ltr_to_gff3_parser.pl

# parses the Domains_Ages.txt and FinalClusters.Annotations.txt.classified.txt files to a gff3 file

use strict; use warnings;

die "Usage: <Domains_Ages.txt file> <FinalClusters.Annotations.txt.classified.txt file>\n" unless @ARGV == 2;
my ($domain_ages, $classified) = @ARGV;

# creates the outfile name
my @subname = split("\\.", $domain_ages);
my $gff3 = $subname[0] . ".gff3";

# goes through the FinalClusters.Annotations.txt.classified file to extract the clusters and types
my %cluster_type_info;
open (my $classified_file, "<", $classified) or die "Cannot open $classified\n";
while (<$classified_file>){
	chomp;
	my ($cluster, $type, undef) = split("\t", $_);
	$cluster_type_info{$cluster} = $type;
}
close($classified_file);

# goes through the Domain_Ages file to extract the other fields needed for the gff3 file 
open(my $infile, "<", $domain_ages) or die "Cannot open $domain_ages\n";
open(my $outfile, ">", $gff3) or die "Cannot open $gff3\n";
while (<$infile>){
	chomp;
	my ($id, $name, $divergence, $estimatedage) = split("\t", $_);
	my ($ltr_seq, $coords) = split("__", $name);
	my $seq = substr($ltr_seq, 5);
	my ($start, $end) = split("_", $coords);
	my $cluster_type;
	if (exists $cluster_type_info{$id}){ # checks to see if this cluster type exists
		$cluster_type = $cluster_type_info{$id};
	} else{
		$cluster_type = "N/A"
	}
	print $outfile "$seq\tpredictedLTR\tltrharvest\t$start\t$end\t.\t.\t.\tID=$name;Name=$name;Divergence=$divergence;EstimatedAge=$estimatedage;ClusterID=$id;type=$cluster_type\n";
}
close($infile);
close($outfile);