#!usr/bin/perl
# add_repeat_types.pl

# adds classification for the repeats

use strict;
use warnings;

if (@ARGV != 4) {die "Usage: <repeat name prefix> <output file> <unclassified repeat file> <REPCLASS output file>";}

my ($prefix, $output, $repeat_in, $repclass_out) = @ARGV;

my %repeat_types;

#my $prefix = "Repeat";
#my $output = "/share/michelmore-scratch2/tiaho/testoutput.txt";
#my $repeat_in = "/share/michelmore-scratch2/lderevnina/Oomycetes/P.effusa/REPEATS/P.effusa_greater1kb.14.mer.rpt.fa_RSfiltered_2";
#my $repclass_out = "/share/michelmore-scratch2/lderevnina/Oomycetes/P.effusa/REPEATS/REPCLASS/Peffusa_repeats/final.out.txt";

# reads through the REPCLASS output and stores (repeat name => type of repeat) into a hash
open(repclass_outfile, "<", $repclass_out) or die "Cannot open $repclass_out";
while (<repclass_outfile>) {
	chomp;
	if ($_ =~ /R=(\d+).*SC\(\w+-> (\w+\-?\w+\s?\w+\s?\w+)\)/ ){
		my $repeat_class;
		if ($2 eq "ltr retrotransposon") {$repeat_class = "#Retrotransposon/LTR";}
		elsif ($2 eq "non-ltr retrotransposon") {$repeat_class = "#Retrotransposon/Non-LTR";}
		elsif ($2 eq "Short Terminal Repeat") {$repeat_class = "#Retrotransposon/SINEs";}
		elsif ($2 eq "dna transposon") {$repeat_class = "#DNA";}
		elsif ($2 eq "helitron") {$repeat_class = "#DNA/Helitron";}	
		$repeat_types{$1} = $repeat_class;
	}
}
close(repclass_outfile);



# reads through the unclassified repeat file and adds classification
open(repeat_infile, "<", $repeat_in) or die "Cannot open $repeat_in";
open(output_file, ">", $output) or die "Cannot open $output";
my $count = 1;
while (<repeat_infile>){
	chomp;
	if ($_ =~ /^>R=(\d+)/){
		my $replace;
		my $number = $1;
		if (exists $repeat_types{$1}){
			$replace = ">" . $prefix . $count . $repeat_types{$1} . " ";
			$_ =~ s/>\S*\s/$replace/;
			$_ = $_ . " R=" . $number;
			print output_file "$_\n";
		} else{
			$replace = ">" . $prefix . $count . "#Unknown ";
			$_ =~ s/>\S*\s/$replace/;
			$_ = $_ . " R=" . $number;
			print output_file "$_\n";
		}
		$count++;
	}else{
		print output_file "$_\n";
	}
}
close(repeat_infile);
close(output_file);