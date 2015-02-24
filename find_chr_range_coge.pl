#!usr/bin/perl
#find_chr_range_coge.pl

# finds the chromosome ranges of the two genomes in CoGe comparison files

use strict;
use warnings;

die "Enter the CoGe condensed.txt file" unless @ARGV == 1;

my $file = $ARGV[0];
my %info;

# reads the comparison.txt file to extract sequence names and gene orders
open(my $fh, "<", $file) or die "Cannot read $file";
while (<$fh>){
	chomp;
	
	next if ($_ =~ /^#/); # skips the line breaks
	
	$_ =~ s/\|{2}/\t/g;
	my @split_line = split("\t", $_);
	
	my $seq1 = $split_line[0];
	my $ord1 = $split_line[8];
	my $seq2 = $split_line[12];
	my $ord2 = $split_line[20];

	$info{1}{$seq1}{$ord1} = 1;
	$info{2}{$seq2}{$ord2} = 2;
}
close($fh);

# sorts the keys in the hash and prints each sequence, first gene, and second gene
open (my $out1, ">", "genome1.txt") or die "Cannot open genome1.txt";
open (my $out2, ">", "genome2.txt") or die "Cannot open genome2.txt";
for my $genome (sort {$a cmp $b} keys %info){
	for my $seq (sort {$a cmp $b} keys % { $info{$genome} } ){
		
		my @geneord;
		for my $ord (sort {$a <=> $b} keys %{ $info{$genome}{$seq} }){
			push (@geneord, $ord);
		}
		
		my $first = shift @geneord;
		my $last = pop @geneord;
		
		if ($genome == 1){ 
			print $out1 "$seq\t$first\t$last\n";
		} else {
			print $out2 "$seq\t$first\t$last\n";
		}
	}
}
close($out1);
close($out2);
