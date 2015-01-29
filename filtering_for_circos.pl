#!usr/bin/perl
#filtering_for_circos.pl

# filters output files from dag_mergeBlock_getLinks_v4.pl to prepare for plotting with Circos

use strict;
use warnings;

die "Usage: <filtered karyotype file for the reference genome> <Circos.links file> <karyotype file for the other genome>" unless @ARGV == 3;

my ($ref, $links, $other) = @ARGV;

# opens the filtered karyotype file for the reference genome and extracts the sequence names
open(my $reffile, "<", $ref) or die "Cannot open $ref\n";
my @ref_seq;
while (<$reffile>){
	chomp;
	my @split_line = split("\t", $_);
	my $seq_name = $split_line[2];
	push @ref_seq, $seq_name;
}
close($reffile);

# opens the Circos link file and retrieves the links that that match to the reference genome
my $out1 = $links . ".filtered";
open (my $outfile1, ">", $out1) or die "Cannot open $out1\n";
open (my $linkfile, "<", $links) or die "Cannot open $links\n";
my @scaffold_seq;
while (<$linkfile>){
	chomp;
	my ($link_name, $seq1_name, $seq1_coord1, $seq1_coord2, undef, undef, $seq2_name, $seq2_coord1, $seq2_coord2) = split("\t", $_);
	if (grep {$_ eq $seq2_name} @ref_seq){ # $seq2 contains the reference genome sequences
			push @scaffold_seq, $seq1_name unless (grep {$_ eq $seq1_name} @scaffold_seq); # only adds the seq name to the array if it does not already exist
			print $outfile1 "$_\n";
	} elsif (grep {$_ eq $seq1_name} @ref_seq){ # $seq1 contains the reference genome sequences
			push @scaffold_seq, $seq2_name unless (grep {$_ eq $seq2_name} @scaffold_seq); # only adds the seq name to the array if it does not already exist
			print $outfile1 "$_\n";
	}
}
close($linkfile);
close($outfile1);


# opens the filtered Circos link file and retrieves the best link for each of the sequences for the other genome
my $filtered_links = $out1;
open (my $filteredlinkfile, "<", $filtered_links) or die "Cannot open $filtered_links\n";
my %scaffold_info;
my $scaffold;
my $start_coord;
my $ref_genome_seq_name;
my $greatest_length = 0;
my $first = 1;
while (<$filteredlinkfile>){
	chomp;
	my ($link_name, $seq1_name, $seq1_coord1, $seq1_coord2, undef, undef, $seq2_name, $seq2_coord1, $seq2_coord2) = split("\t", $_);
	if (grep {$_ eq $seq2_name} @ref_seq){ # $seq1 contains the scaffold sequences
		my $temp_length = $seq1_coord2 - $seq1_coord1;
		if ($first){
			$scaffold = $seq1_name;
			$first = 0;
		}
		if ($seq1_name ne $scaffold){
			$scaffold_info{$ref_genome_seq_name}{$start_coord} = $seq1_name;
			$greatest_length = 0;
		}
		if ($temp_length > $greatest_length){
			$greatest_length = $temp_length;
			$scaffold = $seq1_name;
			$ref_genome_seq_name = $seq2_name;
			$start_coord = $seq2_coord1;
		}
	} elsif (grep {$_ eq $seq1_name} @ref_seq){ # $seq1 contains the scaffold sequences
		my $temp_length = $seq2_coord2 - $seq2_coord1;
		if ($first){
			$scaffold = $seq2_name;
			$first = 0;
		}
		if ($seq2_name ne $scaffold){
			$scaffold_info{$ref_genome_seq_name}{$start_coord} = $seq2_name;
			$greatest_length = 0;

		}
		if ($temp_length > $greatest_length){
			$greatest_length = $temp_length;
			$scaffold = $seq2_name;
			$ref_genome_seq_name = $seq1_name;
			$start_coord = $seq1_coord1;
		}
	}
}
close($filteredlinkfile);

# sorts the scaffold info hash by first the order of the sequence names in the filtered reference genome karyotype file then by the position of the sequence
my @best_scaffolds;
foreach (@ref_seq){
	for my $start_pos (sort {$a<=>$b} keys %{$scaffold_info{$_}} ){
		push @best_scaffolds, $scaffold_info{$_}{$start_pos};
	}
}

# opens the karyotype file for the other genome to extract the filtered lines
open (my $otherfile, "<", $other) or die "Cannot read $other\n";
my %other_karyotype_info;
while (<$otherfile>){
	chomp;
	my (undef, undef, $seq, undef, undef, undef, undef) = split("\t", $_);
	if (grep {$_ eq $seq} @scaffold_seq){
		$other_karyotype_info{$seq} = $_;
	}
}
close($otherfile);


# retrieve the lines from the other genome's karyotype file that matches the filtered best link Circos file
my $out2 = $other . ".filtered.sorted";
open (my $outfile2, ">", $out2) or die "Cannot open $out2\n";
foreach (@best_scaffolds){
	print $outfile2 "$other_karyotype_info{$_}\n";
}
close($outfile2);