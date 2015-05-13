#!usr/bin/perl
#parse_codeml_output.pl

# parses the codeml output into 5 files: main table, stats table, and 3 matrices (dN/dS, dN, dS)

use strict;
use warnings;
use POSIX qw/floor/;

die "Enter the codeml output file" unless @ARGV == 1;
my $codeml = $ARGV[0];

# extracts the prefix from the input file for the output files, and creates the output files
my ($prefix, undef) = split(/\./, $codeml);
my $output1 = $prefix . ".maintable";

# bunch of hashes
my %stat_table_info;
my %matrices_info;

# reads the codeml output file and extracts needed info
# my $index;
my ($index1, $index2);
my $count = 0;
my $read_lines = "no";
open (my $infile, "<", $codeml) or die "Cannot read $codeml";
open (my $outfile1, ">", $output1) or die "Cannot read $output1";
while(<$infile>){
	chomp;

	# finds where the section we want starts
	if ($_ =~ /^(\d+) \((\S+)\) \.{3} (\d+) \((\S+)\)/){

		# reads all the following lines now
		$read_lines = "yes";

		# assigns some variables captured from the regex
		my $seq1 = $2;
		my $seq2 = $4;
		$index1 = $1;
		$index2 = $3;
		# $index = $index1 . "." . $index2;

		# prints the sequences to the main table
		print $outfile1 "$2\t$4";

		# stores the index and sequence info in a hash
		$stat_table_info{$index1}{$index2}{seq} = "$seq1\t$seq2";

	} elsif ($_ =~ /t=\s+(\d+\.\d+)\s+S=\s+(\d+\.\d+)\s+N=\s+(\d+\.\d+)\s+dN\/dS=\s+(\d+\.\d+)\s+dN\s+=\s+(\d+\.\d+)\s+dS\s+=\s?(\d+\.\d+)/){

		# stores variables in stat table hash
		$stat_table_info{$index1}{$index2}{dNdS} = $4;
		$stat_table_info{$index1}{$index2}{dN} = $5;
		$stat_table_info{$index1}{$index2}{dS} = $6;

		# prints the line of stats to the main table
		print $outfile1 "$1\t$2\t$3\t$4\t$5\t$6\n";

	} elsif ($_ =~ /^(\w+\.\d+)/){
		$count++;
		$matrices_info{$count} = $1;
	} else {
		# skips lines until we find the line we want
		next;
	}
	
}
close($infile);
close($outfile1);



# goes through %stats_table_info to calculate the statistics
my @dnds_info = calculate_stats("dNdS", \%stat_table_info);
my @dn_info = calculate_stats("dN", \%stat_table_info);
my @ds_info = calculate_stats("dS", \%stat_table_info);

# # prints the stats into a file
my $output2 = $prefix . ".stattable";
open(my $outfile2, ">", $output2) or die "Cannot read $output2";
print $outfile2 " \tmean\tmedian\tstdev\n";
print $outfile2 "dn/ds";
print_line(@dnds_info);
print $outfile2 "dn";
print_line(@dn_info);
print $outfile2 "ds";
print_line(@ds_info);
close($outfile2);



# prints the matrices for dn/ds, dn, and ds
print_matrix($prefix, "dNdS", \%matrices_info, \%stat_table_info);
print_matrix($prefix, "dN", \%matrices_info, \%stat_table_info);
print_matrix($prefix, "dS", \%matrices_info, \%stat_table_info);



###################
### SUBROUTINES ###
###################

# extracts the values the calculate the stats for
sub extract_values {
	my ($value, $hash_ref) = @_;
	my @numbers;
	my %hash = %$hash_ref;
	for my $ind1 (keys %hash){
		for my $ind2 (keys %{ $hash{$ind1} }){
			push @numbers, $hash{$ind1}{$ind2}{$value};
		}
	}

	return @numbers;
}

# calculates the mean
sub mean {
	my @numbers = @_;
	my $sum = 0;
	foreach (@numbers){
		$sum += $_;
	}
	my $mean = $sum / (scalar @numbers);

	return $mean;
}

# calculates the median
sub median {
	my @numbers = @_;
	my $num_values = scalar(@numbers);
	my @sorted = sort {$a <=> $b} @numbers;
	my $midpoint = $num_values / 2;
	
	my $median;
	if ($num_values%2 == 1){ # odd number of values
		$median = $sorted[floor($midpoint)];
	} else { # even number of values
		my $num1 = $midpoint;
		my $num2 = $midpoint - 1;
		$median = ($sorted[$num1] + $sorted[$num2]) / 2;
	}

	return $median;
}

# calculates the standard deviation
sub stdev {
	my ($mean, @numbers) = @_;
	my @tmp_numbers;
	foreach (@numbers){
		my $tmp = ($_ - $mean) * ($_ - $mean);
		push @tmp_numbers, $tmp;
	}
	my $sum;
	foreach (@tmp_numbers){
		$sum += $_;
	}
	my $stdev = sqrt($sum / scalar(@tmp_numbers));

	return $stdev;
}

# does all the calculations for each data type
sub calculate_stats {
	my ($value, $stat_hash) = @_;
	my @list = extract_values($value, $stat_hash);
	my $mean_value = mean(@list);
	my $median_value = median(@list);
	my $stdev_value = stdev($mean_value, @list);

	return($mean_value, $median_value, $stdev_value);
}

# prints the line with each value only having up to the 3rd after the decimal
sub print_line {
	my @list = @_;
	foreach (@list){
		print $outfile2 "\t";
		printf $outfile2 ("%.4f", $_);
	}
	print $outfile2 "\n";
}

# prints matrices
sub print_matrix {
	my ($prefix, $type, $matrix_hash, $stat_hash) = @_;
	my %matrix_hash = %$matrix_hash;
	my %stat_hash = %$stat_hash;

	my $output = $prefix . "." . $type . ".matrix";
	open(my $fh, ">", $output) or die "Cannot read $output";

	# prints the header 
	for (my $h = 1; $h <= $count; $h++){
		print $fh "\t$matrix_hash{$h}";
	}
	print $fh "\n";
	
	# prints the values in the matrix
	for (my $i = 1; $i <= $count; $i++){
		print $fh "$matrix_hash{$i}\t";
		for (my $j = 1; $j <= $count; $j++){
			if ($i == $j){ # print N/A
				print $fh "N/A\t";
			} else{
				if (exists $stat_hash{$i}{$j}{$type}){ # it is in the hash
					print $fh "$stat_hash{$i}{$j}{$type}\t";
				} else{
					print $fh "$stat_hash{$j}{$i}{$type}\t"; # use $i and $j swapped
				}
			}
		}
		print $fh "\n";
	}
	close($fh);
}