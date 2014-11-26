#!usr/bin/perl
# add_ltr_types.pl

# adds classification for the LTRs

use strict;
use warnings;

if (@ARGV != 3) {die "Usage: <fasta file> <annotated sequences file> <output file>";}

my ($fasta, $anno, $output) = @ARGV;

my %repeat_types;

#my $fasta = "/share/michelmore-scratch2/tiaho/LTREndive/ltrdigest/Cend.1.v5.Scaffolds.ltrharvest.bySizesAll.ltrdigest_complete.fas";
#my $anno = "/share/michelmore-scratch2/tiaho/LTREndive/ltrdigest/LTR_Lettuce_AllSizes_Domains.FinalClusteredSequences.txt.annotated.txt";
#my $output = "/share/michelmore-scratch2/tiaho/testoutput.txt";

# reads through the annotated sequences file and stores (repeat name => type of repeat) into a hash
open(anno_file, "<", $anno) or die "Cannot open $anno";
while (<anno_file>) {
	chomp;

	# gets the name of the repeat
	$_ =~ /\s(\w+)\s/;
	my $name = $1;

	# gets the type of repeat
	my $repeat_class;
	if ($_ =~ /Copia/){
		$repeat_class = "Copia";
	} elsif ($_ =~ /Gypsy/){
		$repeat_class = "Gypsy";
	} else {
		$repeat_class = "Unknown";
	}

	# stores the repeat name and its class into a hash
	$repeat_types{$name} = $repeat_class;
}
close(anno_file);



# reads through the fasta file and adds the type of ltr
open(fasta_file, "<", $fasta) or die "Cannot open $fasta";
open(output_file, ">", $output) or die "Cannot open $output";
while (<fasta_file>){
	chomp;
	if ($_ =~ /^>(\w+)/){
		my $replace;
		my $name = $1;
		if (exists $repeat_types{$name}){ # repeats that are in the annotated sequences file
			$replace = ">" . $name . "#LTR/" . $repeat_types{$name} . " ltrharvest";
			$_ =~ s/>\w+/$replace/;
			print output_file "$_\n";
		} else{ # repeats that are not in the annotated sequences file
			$replace = ">" . $name . "#LTR/Unknown ltrharvest";
			$_ =~ s/>\w+/$replace/;;
			print output_file "$_\n";
		}
	}else{ # non header lines
		print output_file "$_\n";
	}
}
close(fasta_file);
close(output_file);