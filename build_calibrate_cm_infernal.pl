#!usr/bin/perl
#build_calibrate_cm_infernal.pl

# builds and calibrates covariance models in infernal for multiple alignments
# input: directory containing the sequences to be extracted

use strict;
use warnings;

die "Usage: <directory containing the files to build covariance models for>" unless @ARGV == 1;
my $directory = $ARGV[0];

opendir(my $opendir, $directory) or die "Cannot open $directory";
while (my $file = readdir($opendir)){
	next if ($file =~ /^\./); # skips the . and .. folders
	my $cm_file = $file . ".cm";
	# print "$cm_file\n";\
	my $aln_file = $directory . $file;
	# print "$aln_file\n";
	system`/home/sreyesch/MichelmoreBin/infernal-1.1.1/bin/cmbuild --noss $cm_file $aln_file`;
	system`/home/sreyesch/MichelmoreBin/infernal-1.1.1/bin/cmcalibrate $cm_file`;
}
closedir($opendir);