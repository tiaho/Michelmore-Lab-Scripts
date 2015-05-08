#!usr/bin/perl
#ortholog_finder.pl

# finds the reciprocal best hits and prints the lines they are in

die("Usage: <file1.info2> <file2.info2> <minIdentity> <minCoverage> <outfile>") unless @ARGV == 5;
my ($file1, $file2, $minIdentity, $minCoverage, $outfile) = @ARGV;

# opens file1 and stores {subject} = query into a hash if the min thresholds are met
my %file1_info;
open($fh1, "<", $file1) or die "Cannot open $file1";
while(<$fh1>){
	chomp;

	# splits the lines into variables that we want
	my @split_line = split("\t", $_);
	my $query = $split_line[0];
	my $subject = $split_line[1];
	my $identity = $split_line[4];
	my $length_alignment = $split_line[6];
	my $hit_number = $split_line[7];
	my $length_query_subject = $split_line[12];

	# calculates coverage
	my @split_length_query_subject = split("/", $length_query_subject);
	my $length_query = $split_length_query_subject[0];
	my $coverage = $length_alignment / $length_query;

	# skips ahead to next line if the thresholds are not met
	next if ($identity < $minIdentity or $coverage < $minCoverage or $hit_number != 1);

	# stores the query and subject into a hash
	$file1_info{$subject} = $query;
}
close($fh1);


# prints the header of the outfile
open($outfh, ">", $outfile) or die "Cannot open $outfile";
print $outfh "Query\tSubject\tDescriptSubject\teValue\tIdentity\tNumMatches\tLengthAlignment\tHitNumber\tStartQuery\tEndQuery\tStartSubject\tEndSubject\tLengthQuery/LengthSubject\tGapStat\n";

# opens file2, filters, then prints line if the reciprocal blast exists
open($fh2, "<", $file2) or die "Cannot open $file2";
while(<$fh2>){
	chomp;

	# splits the lines into variables that we want
	my @split_line = split("\t", $_);
	my $query = $split_line[0];
	my $subject = $split_line[1];
	my $identity = $split_line[4];
	my $length_alignment = $split_line[6];
	my $hit_number = $split_line[7];
	my $length_query_subject = $split_line[12];

	# calculates coverage
	my @split_length_query_subject = split("/", $length_query_subject);
	my $length_query = $split_length_query_subject[0];
	my $coverage = $length_alignment / $length_query;

	# print "$identity $coverage $hit_number\n"; 

	# skips ahead to next line if the thresholds are not met
	next if ($identity < $minIdentity or $coverage < $minCoverage or $hit_number != 1);

	# print "$identity $coverage $hit_number $query $subject\n"; 

	# checks to see if there a reciprocal blast hit
	if (exists $file1_info{$query}){
		my $file1_query = $file1_info{$query};
		if ($file1_query eq $subject){
			print $outfh "$_\n"; 
		}
	}

}
close($fh2);
close($outfh);