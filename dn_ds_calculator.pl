#!usr/bin/perl
#dn_ds_calculator.pl

# calculates the divergence of a set of sequences by kn/ks

use strict;
use warnings;
use Getopt::Std;
use vars qw($opt_h $opt_s $opt_p $opt_d $opt_m $opt_N $opt_r $opt_i $opt_c);
getopts('h:s:p:d:m:N:r:i:c:');



# checks to see if all options has an input
if (defined($opt_h)) {
    print "
		Required Options:
        -s <tab delimited file with lines of sequences to compared by rows>
        -p <fasta file with protein sequences>
        -d <fasta file with nucleotide sequences>
        -m <-m option for RAxML>
        -N <-N option for RAxML>
        -r <runmode option for codeml> suggested value: -2
        -i <icode option for codeml> suggested value: 0
        -c <clock option for codeml> suggested value: 0
	\n";
	exit;
} elsif ( !(defined($opt_s)) || !(defined($opt_p)) || !(defined($opt_d)) || !(defined($opt_m)) || !(defined($opt_N)) || !(defined($opt_r)) || !(defined($opt_i)) || !(defined($opt_c)) ) {
	die "
	Required Options:
        -s <tab delimited file with lines of sequences to compared by rows>
        -p <fasta file with protein sequences>
        -d <fasta file with nucleotide sequences>
        -m <-m option for RAxML>
        -N <-N option for RAxML>
        -r <runmode option for codeml> suggested value: -2
        -i <icode option for codeml> suggested value: 0
        -c <clock option for codeml> suggested value: 0
	\n";

}



# defines the options as variables
my $pro_list = $opt_s;
my $pro_file = $opt_p;
my $nuc_file = $opt_d;
my $raxml_m = $opt_m;
my $raxml_n = $opt_N;
my $codeml_r = $opt_r;
my $codeml_i = $opt_i;
my $codeml_c = $opt_c;



# reads the protein list
my $count = 0;
my @seq_list;
open (my $pro_list_fh, "<", $pro_list) or die "Cannot open $pro_list";
while (<$pro_list_fh>){
	chomp;
	
	$seq_list[$count] = $_;

	$count++;
}
close($pro_list_fh);



# reads through the array
my $count2 = 1;
for (my $i = 0; $i < $count - 1; $i++){
	my $line = $seq_list[$i];
	chomp $line;

	my @seq = split("\t", $line);

	open (my $tmp_fh, ">", "list.txt") or die "Cannot open list.txt";
	for (my $j = 0; $j < scalar(@seq); $j++){
		print $tmp_fh "$seq[$j]\n"; # prints the pair of sequences into a text file
	}
	close($tmp_fh);

	# runs Fasta_retriever.pl on both nucleotide and protein files
	my $nuc_prefix = "nuc" . $count2;
	system `/home/sreyesch/scripts/FastaTools/Fasta_retriever.pl $nuc_file list.txt $nuc_prefix`; # retrieves the nucleotide sequences for the pair
	# my $pro_prefix = "prot" . $count2;
	system `/home/sreyesch/scripts/FastaTools/Fasta_retriever.pl $pro_file list.txt tmp_prot`; # retreive the protein sequences for the pair

	# get rid of * in the protein fasta file
	my $pro_prefix = "prot" . $count2;
	my $prot_file = $pro_prefix . ".fasta";
	open (my $prot_fh, "<", "tmp_prot.fasta") or die "Cannot open tmp_prot.fasta";
	open (my $prot_out, ">", $prot_file) or die "Cannot open $prot_file";
	while(<$prot_fh>){
		chomp;
		if ($_ =~ /^>/){
			# do nothing
		} else {
			$_ =~ s/\*$//; # delete * if at end of a sequence
			$_ =~ s/\*/X/g; # change other * to 
		}
		print $prot_out "$_\n";
	}
	close ($prot_fh);
	close ($prot_out);

	# runs clustal
	my $pro_fasta = $pro_prefix . ".fasta";
	my $clustalo = $pro_prefix . ".clustalo";
	system `/home/sreyesch/MichelmoreBin/clustalo-1.2.0-Ubuntu-x86_64 --force -i $pro_fasta -o $clustalo`; # sequence alignment at the protein level

	# runs pal2nal.pl twice, one output for codeml, second output for raxml
	my $nuc_fasta = $nuc_prefix . ".fasta";
	my $codon_codeml = $nuc_prefix . ".codon.codeml";
	system `/home/lderevnina/tools/pal2nal.v14/pal2nal.pl  $clustalo  $nuc_fasta  -output paml  -nogap  >  $codon_codeml`; # formats the fasta nucleotide file using the protein alignment
	my $codon_raxml = $nuc_prefix . ".codon.raxml";
	system `/home/lderevnina/tools/pal2nal.v14/pal2nal.pl  $clustalo  $nuc_fasta  -output fasta  -nogap  >  $codon_raxml`; # formats the fasta nucleotide file using the protein alignment

	# read the .codon output of pan2nal and verify the 1st number on the 1st line is not a 0
	open (my $codon_fh, "<", $codon_codeml) or die "Cannot read $codon_codeml";
	my $firstLine = <$codon_fh>; 
	close ($codon_fh);
	$firstLine =~ /^\s+(\d+)/;
	die "There are no residues without gaps in $codon_codeml" if ($1 == 0);

	# runs a different program depending on if we have 2 or 3+ gene in a list
	my $dir = `pwd`;
	chomp $dir;
	my $codeml_input;
	if (scalar(@seq) == 2){
		open (my $tree_fh, ">", "tree.txt") or die "Cannot open tree.txt";
		print $tree_fh "($seq[0],$seq[1]);\n"; # prints the tree file
		close($tree_fh);
		$codeml_input = "tree.txt";
	} else {
		my $name = $nuc_prefix . ".RAxML";
		my $log = $name . ".log";
		system `/home/sreyesch/MichelmoreBin/standard-RAxML-master/raxmlHPC-PTHREADS -T 2 -s $codon_raxml -m $raxml_m -N $raxml_n -w $dir -n $name -p 12345 -x 12345 > $log`;
		$codeml_input = "RAxML_bestTree." . $name;
	}

	# runs codeml
	my $codeml_outfile = $count2 . ".codeml";
	open (my $control_fh, ">", "codeml.cmt") or die "Cannot open codeml.cmt"; # modify a control file for CodeML
	print $control_fh "
	      seqfile = $codon_codeml
	     treefile = $codeml_input
	      outfile = $codeml_outfile

	        noisy = 0   		* 0,1,2,3,9: how much rubbish on the screen
	      verbose = 0   		* 1: detailed output, 0: concise output
	      runmode = $codeml_r  	* 0: user tree;  1: semi-automatic;  2: automatic
	                    		* 3: StepwiseAddition; (4,5):PerturbationNNI; -2: pairwise

	    cleandata = 1   		* 'I added on 56/56/5656' Mikita Suyama

	      seqtype = 1   		* 1:codons; 2:AAs; 3:codons-->AAs
	    CodonFreq = 2   		* 0:1/61 each, 1:F1X4, 2:F3X4, 3:codon table
	        model = 2
	                    		* models for codons:
	                        	* 0:one, 1:b, 2:2 or more dN/dS ratios for branches

	      NSsites = 0   		* dN/dS among sites. 0:no variation, 1:neutral, 2:positive
	        icode = $codeml_i   * 0:standard genetic code; 1:mammalian mt; 2-56:see below
	        Mgene = 0   		* 0:rates, 1:separate; 2:pi, 3:kappa, 4:all

	    fix_kappa = 0   		* 1: kappa fixed, 0: kappa to be estimated
	        kappa = 2   		* initial or fixed kappa
	    fix_omega = 0   		* 1: omega or omega_1 fixed, 0: estimate
	        omega = 1   		* initial or fixed omega, for codons or codon-transltd AAs

	    fix_alpha = 1   		* 0: estimate gamma shape parameter; 1: fix it at alpha
	        alpha = .0  		* initial or fixed alpha, 0:infinity (constant rate)
	       Malpha = 0   		* different alphas for genes
	        ncatG = 4   		* # of categories in the dG or AdG models of rates

	        clock = $codeml_c   * 0: no clock, unrooted tree, 1: clock, rooted tree
	        getSE = 0   		* 0: don't want them, 1: want S.E.s of estimates
	 RateAncestor = 0   		* (1/0): rates (alpha>0) or ancestral states (alpha=0)
	       method = 0   		* 0: simultaneous; 1: one branch at a time";
	close($control_fh);
	my $control_file_path = $dir . "/codeml.cmt";
	system ("/home/sreyesch/MichelmoreBin/paml4.7a/bin/codeml", $control_file_path); # run codeml for calculation of the Dn/Ds

	# runs parse_codeml_output.pl
	system `perl /home/tiaho/scripts/parse_codeml_output.pl $codeml_outfile`;

	$count2++;
}