#!usr/bin/perl
# repeatmasker.out_parser.pl

# parses the .out file for RepeatMasker

die "Enter the .out file from RepeatMasker" unless @ARGV == 1;
my $file = $ARGV[0];

# parsed file name
my $parsed = $file . ".parsed";

open($fh, "<", $file) or die "Cannot open $file";
open($out, ">", $parsed) or die "Cannot open $parsed";;
my $first = 1;
while(<$fh>){
	chomp;

	# replaces the spaces with a tab
	$_ =~ s/^ +//;
	$_ =~ s/ +/\t/g;

	# skips the header lines
	next unless ($_ =~ /^\d/);

	# splits the line by tab
	my @spot = split("\t", $_);

	# skips the line with * in the last field
	next if $spot[-1] eq "*";

	# changes C to - in the 9th field
	if ($spot[8] eq "C"){
		$spot[8] = "-";
	}

	# prints the header
	if ($first == 1){
		print $out "matching_repeat\trepeat_class/family\tquery_sequence\tbegin_query\tend_query\t(left)_query\tstrand\tbegin_repeat\tend_repeat\t(left)_repeat\tSW_score\tperc_div.\tperc_del.\tperc_ins.\tperc_cov.\n";
		$first = 0;
	}

	# calculates the percent coverage and prints the line
	my $a = $spot[11];
	my $b = $spot[12];
	my $c = $spot[13];
	my $perc_cov;
	if ($spot[8] eq "+"){
		$c =~ /\((\d+)\)/;
		$c = $1;
		$perc_cov = abs($b - $a) / ($b + $c);
		print $out "$spot[9]\t$spot[10]\t$spot[4]\t$spot[5]\t$spot[6]\t$spot[7]\t$spot[8]\t$spot[11]\t$spot[12]\t$spot[13]\t$spot[0]\t$spot[1]\t$spot[2]\t$spot[3]\t";
		printf $out ("%.3f", $perc_cov);
		print $out "\n";
	} else {
		$a =~ /\((\d+)\)/;
		$a = $1;
		$perc_cov = abs($b - $c) / ($b + $a);
		print $out "$spot[9]\t$spot[10]\t$spot[4]\t$spot[5]\t$spot[6]\t$spot[7]\t$spot[8]\t$spot[13]\t$spot[12]\t$spot[11]\t$spot[0]\t$spot[1]\t$spot[2]\t$spot[3]\t";
		printf $out ("%.3f", $perc_cov);
		print $out "\n";
	}
	
}
close($out);
close($fh);