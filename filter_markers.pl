#!usr/bin/perl
#filter_markers.pl

# filters markers for a certain window size and fills in missing data

use strict; use warnings;
use POSIX;
use Data::Dumper;

if (@ARGV != 5 and @ARGV != 4){
	print"\nTo filter markers and fill in missing data: <.map file> <.loc file> <output .map file> <output .loc file> <window size>\n";
	print"or\n";
	die "To just filter markers: <.map file> <.loc file> <output .map file> <window size>\n";
}

my ($mapfile, $locfile, $outputmap, $outputloc, $window);
my $fill_in_missing_data;
my %missing_h_counts;
my %genetic_data;
my %marker_pos;
my $filtered_markers = "";
my @list_of_filtered_markers;
my @fm_data;

# assigns variables depending on the inputs given
if (@ARGV == 5){
	($mapfile, $locfile, $outputmap, $outputloc, $window) = @ARGV;
	$fill_in_missing_data = "yes";
} elsif (@ARGV == 4){
	($mapfile, $locfile, $outputmap, $window) = @ARGV;
	$fill_in_missing_data = "no";
}

# checks to see if window value is valid
die "Window value must be greater than 0\n" unless $window > 0;

# opens the file with genetic data
open (file1, "<", $locfile) or die "Cannot open $locfile\n";

my $num_data_points;
my $first = 1;

# gets a count of the missing data and heterozygote data for each marker
while (<file1>){
	if ($first){ # skips the header line
		$first = 0;
	} else {
		chomp $_;
		my @line = split("\t", $_);

		$num_data_points = scalar @line;

		my $marker = $line[0];
		my $missing_counts = grep(/-/, @line);
		my $h_counts = grep(/H/, @line);

		$missing_h_counts{$marker}{missing_counts} = $missing_counts;
		$missing_h_counts{$marker}{h_counts} = $h_counts;

		# stores the genetic data into a hash
		for (my $i = 1; $i < scalar(@line); $i++){
			$genetic_data{$marker}{$i} = $line[$i];
		}
	}
}

close(file1);





# opens the file with the map data
open (file2, "<", $mapfile) or die "Cannot open $mapfile\n";

my ($temp_line, $temp_marker, $temp_pos);
my ($prev_line, $prev_marker, $prev_pos, $prev_lower, $prev_upper);
my ($divide, $lower, $upper);
my $floor;

my @filelines = <file2>;
my $length_lines = scalar @filelines;


# compares the missing data and possibly heterozygote data for each marker at the same cM
for (my $i = 0; $i < $length_lines; $i++){
	chomp $filelines[$i];
	my (undef, $marker, $pos, undef) = split("\t", $filelines[$i]);

	# figures out the window the marker lies in
	$divide = $pos / $window;
	$lower = floor($divide) * $window;
	if ($divide == 0) {$upper = $window;}
	else {$upper = ceil($divide) * $window;}

	# adds the markers into a hash, based on the centimorgan that they are at
	if (exists $marker_pos{"$lower, $upper"}){
		push @{ $marker_pos{"$lower, $upper"} }, $marker;
	} else {
		$marker_pos{"$lower, $upper"} = [$marker];
	}

	if ($i == 0){
		$temp_line = $filelines[$i];
		$temp_marker = $marker;
		$temp_pos = $pos;
	} else { # goes ahead and compares for all other lines
		if ($pos >= $prev_lower and $pos < $prev_upper){ # compares the missing data first
			if ($missing_h_counts{$marker}{missing_counts} < $missing_h_counts{$prev_marker}{missing_counts}){
				$temp_line = $filelines[$i];
				$temp_marker = $marker;
				$temp_pos = $pos;
			} elsif ($missing_h_counts{$prev_marker}{missing_counts} < $missing_h_counts{$marker}{missing_counts}){
				$temp_line = $prev_line;
				$temp_marker = $prev_marker;
				$temp_pos = $prev_pos;
			} else { # equal missing data, so compare heterozygote data
				if ($missing_h_counts{$marker}{h_counts} < $missing_h_counts{$prev_marker}{h_counts}){
					$temp_line = $filelines[$i];
					$temp_marker = $marker;
					$temp_pos = $pos;
				} elsif ($missing_h_counts{$prev_marker}{h_counts} < $missing_h_counts{$marker}{h_counts}){
					$temp_line = $prev_line;
					$temp_marker = $prev_marker;
					$temp_pos = $prev_pos;
				} else { # equal number of missing data and heterozygote data, so choose the first one
					$temp_line = $prev_line;
					$temp_marker = $prev_marker;
					$temp_pos = $prev_pos;
				}
			}
		} else { # different cM
			$filtered_markers .= "$temp_line\n";
			push @list_of_filtered_markers, $temp_marker;
			$temp_line = $filelines[$i];
			$temp_marker = $marker;
			$temp_pos = $pos;
			if ($i == $length_lines - 1){ # if the last line and 2nd to last line are on different cM, then add it to the printed list
				$filtered_markers .= "$temp_line";
				push @list_of_filtered_markers, $temp_marker;
			}
		}
	}

	# saves the info from this loop for the next loop
	$prev_line = $filelines[$i];
	$prev_marker = $marker;
	$prev_pos = $pos;
	$prev_lower = $lower;
	$prev_upper = $upper;
}

close(file2);





# prints the filtered markers to an output file
open (file3, ">", $outputmap) or die "Cannot open $outputmap\n";
print file3 "$filtered_markers";
close(file3);










# only continues if an output loc file was given
if ($fill_in_missing_data eq "yes"){

	# opens the original .loc file
	open (file1, "<", $locfile) or die "Cannot open $locfile\n";

	$first = 1;

	# gets a count of the missing data and heterozygote data for each marker
	while (<file1>){
		if ($first){ # prints the header line
			chomp;
			my @line = split("\t", $_);
			push @fm_data, [ @line ];
			$first = 0;
		} else {
			chomp;
			my @line = split("\t", $_);
			my $marker = $line[0];

			if (grep {$_ eq $marker} @list_of_filtered_markers){ #only prints the line it is a filtered marker
				push @fm_data, [ @line ];
			}
		}
	}
	close(file1);





	# fills in the missing data for the filtered markers
	open (file3, "<", $outputmap) or die "Cannot open $outputmap\n";

	my @filtered_filelines = <file3>;
	my $num_lines = scalar @filtered_filelines;

	for (my $i = 0; $i < $num_lines; $i++){ # looping through the list of kept markers
		my (undef, $marker, $pos, undef) = split("\t", $filtered_filelines[$i]);
		
		$divide = $pos / $window;
		$lower = floor($divide) * $window;
		if ($divide == 0) {$upper = $window;}
		else {$upper = ceil($divide) * $window;}

		for (my $j = 1; $j < $num_data_points; $j++){ # looping through each data point for each marker
			if ($genetic_data{$marker}{$j} eq "-"){ # if there is missing data...
				my @same_pos_markers = @{ $marker_pos{"$lower, $upper"} };
				my $num_markers = scalar @same_pos_markers; # number of markers at the same cM

				# gets the values for that allele
				my @allele_list;
				for (my $k = 0; $k < $num_markers; $k++){
					my $compared_to_marker = $same_pos_markers[$k];
					my $other_allele = $genetic_data{$compared_to_marker}{$j};
					push @allele_list, $other_allele;
				}

				# compares the values at that allele
				if ((grep {$_ eq "A"} @allele_list) and  (grep {$_ eq "B"} @allele_list)){
					# do nothing
				} elsif (grep {$_ eq "A"} @allele_list){
					$fm_data[$i + 1][$j] = "A"; # +1 because of headers in data file
				} elsif (grep {$_ eq "B"} @allele_list){
					$fm_data[$i + 1][$j] = "B";
				}
			}
		}	
	}
	close(file3);




	# prints the genetic data (filled in) of the filtered markers to an output file
	open (file4, ">", $outputloc) or die "Cannot open $outputloc\n";
	for my $array ( @fm_data ){
		for (my $i = 0; $i < $num_data_points; $i++){
			if ($i == 0){
				print file4 "\n@$array[$i]";
			} else{
				print file4 "\t@$array[$i]";
			}
		}
	}
	close(file4);

	# print Dumper \%genetic_data;
	# print Dumper \%marker_pos;
}