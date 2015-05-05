#!usr/bin/perl
#parse_rfam_file.pl

# parses the Rfam.seed file from rfam into separate files, based on the type

die "Enter the Rfam.seed file" unless @ARGV == 1;
my $file = $ARGV[0];

# creates all the outfiles
$mirna_file = "gene_miRNA";
$ribozyme_file = "gene_ribozyme";
$rrna_file = "gene_rRNA";
$snrna_file = "gene_snRNA";
$snrna_snorna_cdbox_file = "gene_snRNA_snoRNA_CD-box";
$snrna_snorna_hacabox_file = "gene_snRNA_snoRNA_HACA-box";
$snrna_snorna_scarna_file = "gene_snRNA_snoRNA_scaRNA";
$snrna_splicing_file = "gene_snRNA_splicing";
$srna_file = "gene_sRNA";
$trna_file = "gene_tRNA";

# opens all the files
open($fh, "<", $file) or die "Cannot open $file";
open($mirna, ">", $mirna_file) or die "Cannot open $mirna_file";
open($ribozyme, ">", $ribozyme_file) or die "Cannot open $ribozyme_file";
open($rrna, ">", $rrna_file) or die "Cannot open $rrna_file";
open($snrna, ">", $snrna_file) or die "Cannot open $snrna_file";
open($snrna_snorna_cdbox, ">", $snrna_snorna_cdbox_file) or die "Cannot open $snrna_snorna_cdbox_file";
open($snrna_snorna_hacabox, ">", $snrna_snorna_hacabox_file) or die "Cannot open $snrna_snorna_hacabox_file";
open($snrna_snorna_scarna, ">", $snrna_snorna_scarna_file) or die "Cannot open $snrna_snorna_scarna_file";
open($snrna_splicing, ">", $snrna_splicing_file) or die "Cannot open $snrna_splicing_file";
open($srna, ">", $srna_file) or die "Cannot open $srna_file";
open($trna, ">", $trna_file) or die "Cannot open $trna_file";

# sets some needed variables
my $temp; # temp variable for storing lines
my $p = "no"; # yes or no for printing a line
my $type;

# loops through the Rfam.seed file
while(<$fh>){
	$temp = $temp . $_; # stores the line in a temp variable

	chomp;

	if ($p eq "yes"){
		print $type "$_\n"; 
	} else{
		# don't print anything
	}

	if ($_ =~ /^\/\//){ # end of a stockholm alignment
		$p = "no"; # don't print anything until we find the next desired type
		$temp = undef; # clears temp variable
	}

	# searches for the types we want
	if ($_ =~ /#=GF TP/){
		if ($_ =~ /Gene; miRNA;/){
			$type = $mirna;
		} elsif ($_ =~ /Gene; ribozyme;/){
			$type = $ribozyme;
		} elsif ($_ =~ /Gene; rRNA;/){
			$type = $rrna;
		} elsif ($_ =~ /Gene; snRNA;/){
			$type = $snrna;
		} elsif ($_ =~ /Gene; snRNA; snoRNA; CD-box;/){
			$type = $snrna_snorna_cdbox;
		} elsif ($_ =~ /Gene; snRNA; snoRNA; HACA-box;/){
			$type = $snrna_snorna_hacabox;
		} elsif ($_ =~ /Gene; snRNA; snoRNA; scaRNA;/){
			$type = $snrna_snorna_scarna;
		} elsif ($_ =~ /Gene; snRNA; splicing;/){
			$type = $snrna_splicing;
		} elsif ($_ =~ /Gene; sRNA;/){
			$type = $srna;
		} elsif ($_ =~ /Gene; tRNA;/){
			$type = $trna;
		}

		print $type "$temp";
		$p = "yes";
	}
}

#closes all the files
close($fh);
close($mirna);
close($ribozyme);
close($rrna);
close($snrna);
close($snrna_snorna_cdbox);
close($snrna_snorna_hacabox);
close($snrna_snorna_scarna);
close($snrna_splicing);
close($srna);
close($trna);