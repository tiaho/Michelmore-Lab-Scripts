#!usr/bin/perl
# split_alingments.pl

# splits a protein alignment by half, and splits the nucleotide sequence based on the number of amino acids/gaps present

use strict;
use warnings;

die "Usage: <protein alignment file> <nucleotide fasta file> <prefix for output files>\n" unless @ARGV == 3;

my ($align, $seq, $prefix) = @ARGV;

# stores some protein info in a hash
open (align_file, "<", $align) or die "Cannot open $align\n";
my %info;
my ($protein_name, $protein_seq);
my $first = 1;
while (<align_file>){
	chomp;
	if ($_ =~ /^>(\w+)/){ # header line
		if ($first == 1){ # don't want to run this for the first fasta lines
			$first = 0;
		} else{ # stores info for the previous sequence into a hash
			$info{$protein_name}{"seq"} = $protein_seq;
			$info{$protein_name}{"length"} = length($protein_seq);
			$info{$protein_name}{"midpoint"} = length($protein_seq)/2;
			undef $protein_seq; # empties the protein_seq variable
		}
		$protein_name = $1;
	} else{ # line with sequence
		$protein_seq .= $_; # adds this chunk to the growing sequence
	}
}
close(align_file);

# stores info for last sequnce in hash
$info{$protein_name}{"seq"} = $protein_seq;
$info{$protein_name}{"length"} = length($protein_seq);
$info{$protein_name}{"midpoint"} = length($protein_seq)/2;

# stores some nucleotide info in a hash
open (seq_file, "<", $seq) or die "Cannot open $seq\n";
my $nuc_seq;
$first = 1;
while (<seq_file>){
	chomp;
	if ($_ =~ /^>(\w+)/){ # header line
		if ($first == 1){ # don't want to run this for the first fasta lines
			$first = 0;
		} else{ # stores info for the previous sequence into a hash
			$info{$protein_name}{"nuc_seq"} = $nuc_seq;
			undef $nuc_seq; # empties the nuc_seq variable
		}
		$protein_name = $1;
	} else{ # line with sequence
		$nuc_seq .= $_; # adds this chunk to the growing sequence
	}
}
close(seq_file);

# stores info for last sequnce in hash
$info{$protein_name}{"nuc_seq"} = $nuc_seq;
	
# makes the output files
my $al_spl_pro_5utr = $prefix . "_aligned_splitted_protein_5utr.fasta";
my $al_spl_pro_3utr = $prefix . "_aligned_splitted_protein_3utr.fasta";
my $spl_pro_5utr = $prefix . "_splitted_protein_5utr.fasta";
my $spl_pro_3utr = $prefix . "_splitted_protein_3utr.fasta";
my $spl_nuc_5utr = $prefix . "_splitted_nucleotide_5utr.fasta";
my $spl_nuc_3utr = $prefix . "_splitted_nucleotide_3utr.fasta";

open (out1, ">", $al_spl_pro_5utr) or die "Cannot open $al_spl_pro_5utr";
open (out2, ">", $al_spl_pro_3utr) or die "Cannot open $al_spl_pro_3utr";
open (out3, ">", $spl_pro_5utr) or die "Cannot open $spl_pro_5utr";
open (out4, ">", $spl_pro_3utr) or die "Cannot open $spl_pro_3utr";
open (out5, ">", $spl_nuc_5utr) or die "Cannot open $spl_nuc_5utr";
open (out6, ">", $spl_nuc_3utr) or die "Cannot open $spl_nuc_3utr";

# loops through the hash to split the sequences, prints sequences
for my $protein (keys %info){
	my $seq = $info{$protein}{'seq'};
	my $nuc_seq = $info{$protein}{'nuc_seq'};
	my $midpoint = $info{$protein}{'midpoint'};

	my $five_name = ">" . $protein . "_5utr";
	my $three_name = ">". $protein . "_3utr";

	# splits the aligned protein sequence
	my $five = substr($seq, 0, $midpoint);
	print out1 "$five_name\n$five\n";
	my $three = substr($seq, $midpoint);
	print out2 "$three_name\n$three\n";

	# removes gaps from the splitted aligned protein sequence
	my $five_nogaps = remove_gaps($five);
	print out3 "$five_name\n$five_nogaps\n";
	my $three_nogaps = remove_gaps($three);
	print out4 "$three_name\n$three_nogaps\n";

	# splits the nucleotide sequence
	my $five_nuc_len = length($five_nogaps) * 3;
	my $five_nuc = substr($nuc_seq, 0, $five_nuc_len);
	print out5 "$five_name\n$five_nuc\n";
	my $three_nuc_len = length($three_nogaps) * 3;
	my $three_nuc = substr($nuc_seq, $five_nuc_len);
	print out6 "$three_name\n$three_nuc\n";

}

close(out1);
close(out2);
close(out3);
close(out4);
close(out5);
close(out6);



### SUBROUTINES
sub remove_gaps{
	my $seq = $_[0];
	my $seq_nogaps;
	my @seq_array = split('', $seq);
	for (my $i = 0; $i < length($seq); $i++){
		if ($seq_array[$i] ne "-"){
			$seq_nogaps .= $seq_array[$i];
		}
	}
	return ($seq_nogaps);
}