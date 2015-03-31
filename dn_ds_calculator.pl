#!usr/bin/perl
#dn_ds_calculator.pl

# calculates the divergence of a set of sequences by kn/ks
# output is named results.txt

use strict;
use warnings;

die "Usage: <tab delimited text file with pairs of sequences to compared by rows> <fasta file with protein sequences> <fasta file with nucleotide sequences>" unless @ARGV == 3;
my ($pro_pairs, $pro_file, $nuc_file) = @ARGV;

my $count = 1;
my %seq_index;
open (my $pro_pairs_fh, "<", $pro_pairs) or die "Cannot open $pro_pairs";
while (<$pro_pairs_fh>){
	chomp;
	# $_ =~ s/\t/\n/;
	my @seq = split("\t", $_);

	$seq_index{$count} = "$seq[0]\t$seq[1]\t"; # stores the sequences with the index number


	open (my $tmp_fh, ">", "list.txt") or die "Cannot open list.txt";
	print $tmp_fh "$seq[0]\n$seq[1]\n"; # prints the pair of sequences into a text file
	close($tmp_fh);

	my $nuc_prefix = "nuc" . $count;
	system `/home/sreyesch/scripts/FastaTools/Fasta_retriever.pl $nuc_file list.txt $nuc_prefix`; # retrieves the nucleotide sequences for the pair
	my $pro_prefix = "prot" . $count;
	system `/home/sreyesch/scripts/FastaTools/Fasta_retriever.pl $pro_file list.txt $pro_prefix`; # retreive the protein sequences for the pair

	my $pro_fasta = $pro_prefix . ".fasta";
	my $clustalo = $pro_prefix . ".clustalo";
	system `/home/sreyesch/MichelmoreBin/clustalo-1.2.0-Ubuntu-x86_64 -i $pro_fasta -o $clustalo`; # sequence alignment at the protein level

	my $nuc_fasta = $nuc_prefix . ".fasta";
	my $codon = $nuc_prefix . ".codon";
	system `/home/lderevnina/tools/pal2nal.v14/pal2nal.pl  $clustalo  $nuc_fasta  -output paml  -nogap  >  $codon`; # formats the fasta nucleotide file using the protein alignment

	open (my $tree_fh, ">", "tree.txt") or die "Cannot open tree.txt";
	print $tree_fh "($seq[0],$seq[1]);\n"; # prints the tree file
	close($tree_fh);

	my $dir = `pwd`;
	chomp $dir;
	my $outfile = $count . ".codeml";
	open (my $control_fh, ">", "codeml.cmt") or die "Cannot open codeml.cmt"; # modify a control file for CodeML
	print $control_fh "
      seqfile = $codon
     treefile = tree.txt
      outfile = $outfile

        noisy = 0   * 0,1,2,3,9: how much rubbish on the screen
      verbose = 0   * 1: detailed output, 0: concise output
      runmode = -2  * 0: user tree;  1: semi-automatic;  2: automatic
                    * 3: StepwiseAddition; (4,5):PerturbationNNI; -2: pairwise

    cleandata = 1   * 'I added on 56/56/5656' Mikita Suyama

      seqtype = 1   * 1:codons; 2:AAs; 3:codons-->AAs
    CodonFreq = 2   * 0:1/61 each, 1:F1X4, 2:F3X4, 3:codon table
        model = 2
                    * models for codons:
                        * 0:one, 1:b, 2:2 or more dN/dS ratios for branches

      NSsites = 0   * dN/dS among sites. 0:no variation, 1:neutral, 2:positive
        icode = 0   * 0:standard genetic code; 1:mammalian mt; 2-56:see below
        Mgene = 0   * 0:rates, 1:separate; 2:pi, 3:kappa, 4:all

    fix_kappa = 0   * 1: kappa fixed, 0: kappa to be estimated
        kappa = 2   * initial or fixed kappa
    fix_omega = 0   * 1: omega or omega_1 fixed, 0: estimate
        omega = 1   * initial or fixed omega, for codons or codon-transltd AAs

    fix_alpha = 1   * 0: estimate gamma shape parameter; 1: fix it at alpha
        alpha = .0  * initial or fixed alpha, 0:infinity (constant rate)
       Malpha = 0   * different alphas for genes
        ncatG = 4   * # of categories in the dG or AdG models of rates

        clock = 0   * 0: no clock, unrooted tree, 1: clock, rooted tree
        getSE = 0   * 0: don't want them, 1: want S.E.s of estimates
 RateAncestor = 0   * (1/0): rates (alpha>0) or ancestral states (alpha=0)
       method = 0   * 0: simultaneous; 1: one branch at a time";
	close($control_fh);

	my $control_file_path = $dir . "/codeml.cmt";
	system ("/home/sreyesch/MichelmoreBin/paml4.7a/bin/codeml", $control_file_path); # run codeml for calculation of the Dn/Ds

	$count++;
}
close($pro_pairs_fh);

# loops through the all the .codeml files; retrieves and prints the results in a new file
my $output_file = "results.txt";
open (my $output_fh, ">", $output_file) or die "Cannot open $output_file";
for (my $i = 1; $i < $count; $i++){
	my $codeml_file = $i . ".codeml";
	open (my $codeml_fh, "<", $codeml_file) or die "Cannot open $codeml_file";
	while (<$codeml_fh>){
		chomp;
		next unless ($_ =~ /^t=/);
		print $output_fh "$i\t$seq_index{$i}\t$_\n";
	}
	close($codeml_fh);
}
close($output_fh);