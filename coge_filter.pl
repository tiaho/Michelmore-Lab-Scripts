#!usr/bin/perl
#coge_filter.pl

# runs other scripts that filters the CoGe condensed.txt files
# also extracts the chromosome range for the genomes in comparison

use strict;
use warnings;

die "Enter the directory in which the CoGe comparisons are stored in" unless @ARGV == 1;

my $directory = $ARGV[0];

chdir($directory); # now works in the directory in which the comparisons are stored in

# my $count = 1;
opendir(my $maindir, $directory) or die "Cannot open $directory\n"; # opens the folder that contains the folders for the comparisons
while (my $directory2 = readdir($maindir)){ 
	if (-d $directory2){ # only continues if it is a folder
		opendir(my $seconddir, $directory2) or die "Cannot open $directory2\n"; # opens the folders for each comparison
		next if ($directory2 eq "." and $directory2 ne ".."); # skip the . and .. folders
		while (my $file = readdir($seconddir)){
			if ($file =~ /condensed\.txt/){

				my $filepath = $directory . $directory2 . "/" . $file;
				# print "$filepath\n";
				$filepath =~ /(\S+)\.txt/;
				my $prefix = $1;
				my $less_redundant_filepath = $prefix . ".LessRedundant.txt";

				system`perl /home/tiaho/scripts/find_chr_range_coge.pl $filepath`; # gets the chr range for the genomes
				# print "done 1\n";
				system`perl /home/sreyesch/scripts/CoGeTools/CoGe_dag_mergedBlocks_parser.pl $filepath`; # parses the CoGe condensed.txt output
				# print "done 2\n";
				# system `/home/ckyled/scripts/gene_block_work/Redundant_Blocks_Remover.py $filepath > tmpfile`; # removes redundant blocks
				# print "done 3\n";
				# system`perl /home/sreyesch/scripts/CoGeTools/CoGe_dag_mergedBlocks_parser.pl $less_redundant_filepath`; # runs the parser on the less redundant file
				# print "done 4\n";
				
				# $count++;
				# die "test done" if ($count == 2);
			}
		}
		closedir($seconddir);
	}
}
closedir($maindir);