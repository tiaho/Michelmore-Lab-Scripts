#!usr/bin/perl
#extract_sequences_run_clustal.pl

# extracts sequences needed for multiple sequence alignments, then runs clustal
# input: directory containing the sequences to be extracted

use strict;
use warnings;

die "Usage: <directory containing the sequences to be extracted> <FASTA file with the sequences> <out file prefix>" unless @ARGV == 3;
my ($directory, $fasta, $prefix) = @ARGV;

opendir(my $opendir, $directory) or die "Cannot open $directory";
while (my $file = readdir($opendir)){
	next if ($file =~ /^\./); # skips the . and .. folders
	my $filepath = $directory . "/" . $file;
	system`/home/sreyesch/scripts/FastaTools/Fasta_retriever.pl $fasta $filepath $prefix`;
	my $file_for_clustal = $prefix . ".fasta";
	my $clustal_output = $prefix . "_" . $file . ".aln";
	system`/home/sreyesch/MichelmoreBin/clustalo-1.2.0-Ubuntu-x86_64 --threads 2 --outfmt st --in $file_for_clustal --out $clustal_output`;
	system`rm $file_for_clustal`; # don't need the fasta file, removes it
}
closedir($opendir);