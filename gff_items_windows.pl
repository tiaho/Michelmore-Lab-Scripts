#!usr/bin/perl
#gff_items_windows.pl

# determines the number of items in a gff file that are in a particular window size across a genome

use strict;
use warnings;
use POSIX;

die "Usage: <gff file> <window size in bp>" unless @ARGV == 2;

my ($gff, $window_size) = @ARGV;

# extracts the last line out of the file to get the last bp the items in the file spans
my %max_bp;
open (my $gff_file, "<", $gff) or die "Cannot open $gff";
while (<$gff_file>){
	chomp;
	my @split_line = split("\t", $_);
	my $sequence = $split_line[0];
	my $end = $split_line[4];
	if (exists $max_bp{$sequence}{max_bp}){
		if ($end > $max_bp{$sequence}{max_bp}){
			$max_bp{$sequence}{max_bp} = $end;
		}
	} else {
		$max_bp{$sequence}{max_bp} = $end;
	}
}
close($gff_file);

# creates the windows
my %windows;
for my $sequence (keys %max_bp){
	for (my $i = 1; $i <= ceil($max_bp{$sequence}{max_bp}/$window_size); $i++){
		my $open = 1 + (($i - 1) * $window_size);
		my $close = $i * $window_size;
		$windows{$sequence}{$open}{$close} = 1; # adds the window to a hash, by sequence
	}
}

# reads through the gff file and puts the items into windows
my %window_count;
open (my $gff_file, "<", $gff) or die "Cannot open $gff";
while (<$gff_file>){
	chomp;
	my ($sequence, undef, undef, $start, $stop, undef, undef, undef, undef) = split("\t", $_);
	for my $open (sort { $a <=> $b } keys $windows{$sequence}){
		for my $close (keys $windows{$sequence}{$open}){
			if (($start >= $open and $start <= $close) or ($stop >= $open and $stop <= $close) or ($start <= $open and $stop >= $close)){
				if (exists $window_count{$sequence}{$open}{$close}){
					$window_count{$sequence}{$open}{$close}++;
				} else {
					$window_count{$sequence}{$open}{$close} = 1;
				}
			}
		}
	}
}
close($gff_file);

# prints the sequence, windows, and counts
for my $sequence (sort keys %window_count){
	for my $open (sort { $a <=> $b } keys $window_count{$sequence}){
		for my $close (keys $window_count{$sequence}{$open}){
			print "$sequence\t$open\t$close\t$window_count{$sequence}{$open}{$close}\n";
		}
	}
	print "\n";
}