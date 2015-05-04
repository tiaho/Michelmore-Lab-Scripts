#!usr/bin/perl
# extract_coge_stats.pl

# extracts some summary statistics from CoGe analyses

use strict;
use warnings;

die "Usage: <directory in which your pairwise comparison files are stored in> <output file>\n" unless @ARGV == 2;
my ($directory, $output) = @ARGV;

chdir($directory); # now works in the directory in which your files are saved in

# extracts the values needed from the condensed stats files
my $first = 1;
my $tmp = ''; # holds the value for the first row of values
open(outfile, ">", $output) or die "Cannot open $output\n";
opendir(maindir, $directory) or die "Cannot open $directory\n"; # opens the folder that contains the folders for the comparisons
while (my $directory2 = readdir(maindir)){ 
	if (-d $directory2){ # only continues if it is a folder
		opendir(seconddir, $directory2) or die "Cannot open $directory2\n"; # opens the folders for each comparison
		if ($directory2 ne "." and $directory2 ne ".."){
			print outfile "\n$directory2" unless $first == 1; # prints the comparison
		}
		while (my $file = readdir(seconddir)){
			if ($file =~ /condensed\.stats/){
				my $filepath = $directory . "/" . $directory2 . "/" . $file;
				open(fh, "<", $filepath) or die "Cannot open $filepath\n"; # opens the condensed stats files
				while (<fh>){
					chomp;
					if ($_ =~ /(\w+\s\w+\s\w+\s\w+\s?\w*\s?\w*\s?\w*\s?\w*\s?\w*)\t(\d+\.?\d*)/){ # looks for the 7 lines that we want to extract data from
						my $cat = $1; # the category
						my $num = $2; # the numerical value
						if ($first == 1){ # only wants to print the headers once
							print outfile "\t$cat";
							$tmp = "$tmp\t$num";
						} else{
							print outfile "\t$num"; # prints the value
						}
					}
				}
				print outfile "\n$directory2\t$tmp" unless $first == 0;
				$first = 0;
				close(fh);
			}
		}
		closedir(seconddir);
	}
}
print"\n";
closedir(maindir);
close(outfile);