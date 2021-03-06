#!usr/bin/perl
#extract_predicted_protein_domains.pl

# extracts the predicted protein domains predicted by HMMER3
# output: domain table, extracted proteins, extracted cds

use strict;
use warnings;
use Data::Dumper;

die "Usage: <HMMER output file> < protein sequence file> <CDS file> <prefix for output files>" unless @ARGV == 4;
my ($hmm, $protein, $cds, $prefix) = @ARGV;



# goes through the HMMER output to extract information
my ($query, $name, $header);
my %info;
my %sequences;
my $count; # counts the number of domains for each sequence
my $find_header = "yes"; # finds the header or no
my $skip = "yes"; # skip line or no
my $output_table = $prefix . "_domain_table.tsv";
open(my $hmm_file, "<", $hmm) or die "Cannot open $hmm"; # goes through the hmm file and extracts needed information
open(my $outfile_table, ">", $output_table) or die "Cannot open $output_table"; # opens the output file for the table
while (<$hmm_file>){
	chomp;
	if ($_ =~ /^Query:/){ # extracts the query name
		$_ =~ /\s(\S+)\s/;
		$query = $1;
		# print "$query\n";
	}
	if ($_ =~ /^>>/){ # identifies the individual domain annotations
		$_ =~ /^>>\s(\S+)\s/;
		$name = $1;
		# print "$name\n";
		$count = 1; # resets the count for each sequence
		$skip = "no"; # no longer skips through the lines
	}
	if ($_ =~ /^\s+#/){ # extracts this table header line
		if ($find_header eq "yes"){
			$_ =~ s/^\s+//g;
			$_ =~ s/\s+/\t/g;
			$header = $_;
			my $print_header = join("\t", "Name of Protein Sequence", "Name of Protein Domain", $header);
			print $outfile_table "$print_header\n";
			$find_header = "no";
		}
		
	}
	if ($skip eq "yes"){ # skips the beginning chunk of the file before it gets to the first >>
		if ($_ !~ /^>>/){
			next;
		}
	} 
	if ($_ =~ /^\s+\d+\s(!|\?)/){ # only wants the lines in the table that starts with a number, to determine significance and extract data
		$_ =~ s/^\s+//g;
		$_ =~ s/\s+/ /g;
		my @split_line = split(" ", $_);
		if ($split_line[4] <= 0.01){ # 0.01 is cutoff for significance
			my $tab_line = "$name\t$query"; # starts off with the name and query

			foreach my $element (@split_line){ # adds the rest of the elements of split_line, separating by tabs
				$tab_line = join("\t", $tab_line, $element);
			}
			print $outfile_table "$tab_line\n";

			my $start = $split_line[9];
			my $stop = $split_line[10];
			$info{$name}{$start}{$stop}{domain} = $query;
			$info{$name}{$start}{$stop}{c_evalue} = $split_line[4];
			$count++;
		}
	}
}
close($hmm_file);
close($outfile_table);


# goes through the protein file and extracts info
my $seq;
my $desired_seq = "no";
my $output_protein = $prefix . "_extracted_proteins.fasta";
my $rna;
open (my $protein_file, "<", $protein) or die "Cannot open $protein"; # extracts the predicted protein domains
while (<$protein_file>){
	chomp;
	if ($_ =~ /^>(\S+)/){ # header line
		$seq = $1;
		if (defined $info{$seq}){ # matches a sequence we have stored in the hash
			$desired_seq = "yes"; # will work on the sequence that follows the header
		}
	} else { # sequence line
		if ($desired_seq eq "yes"){ # time to extract some protein domains!
			$desired_seq = "no"; # will not work on another sequence until a match is found in a headers
			$rna = $_;
		} else {
			$rna .= $_;
		}
		$sequences{$seq}{rna} = $rna;
	}
}
close($protein_file);


# prints the protein output
open (my $outfile_protein, ">", $output_protein) or die "Cannot open $output_protein";
for my $seq (keys %info){
	for my $start (sort { $a <=> $b } keys %{ $info{$seq} }){
		for my $stop (sort { $a <=> $b } keys %{ $info{$seq}{$start} }){
			my $rna_seq = $sequences{$seq}{rna};
			my $domain = $info{$seq}{$start}{$stop}{domain};
			my $sig = $info{$seq}{$start}{$stop}{c_evalue};

			my $domain_seq = substr($rna_seq, $start - 1, $stop - $start + 1) or print STDERR "Problem sequence is $seq\n"; # start - 1 b/c the seq starts counting at 1 and perl starts counting at 0
			my $print_protein_header = ">" . $seq . "_" . $domain . "_" . $start . "-" . $stop . " c-Evalue=" . $sig; 
			print $outfile_protein "$print_protein_header\n$domain_seq\n"; # prints the header line and sequence line to the output file
		}
	}
}
close($outfile_protein);


__END__ 

# goes through the nucleotide file to extract info
my $output_nuc = $prefix . "_extracted_cds.fasta";
my $dna;
open (my $cds_file, "<", $cds) or die "Cannot open $cds"; # extracts the nucleotide sequence for the predicted protein domains
while (<$cds_file>){
		chomp;
		# print "$_\n";
	if ($_ =~ /^>(\S+)/){ # header line
		$seq = $1;
		print "$_\n";
		if (defined $info{$seq}){ # matches a sequence we have stored in the hash
			$desired_seq = "yes"; # will work on the sequence that follows the header
		}
	} else { # sequence line
		if ($desired_seq eq "yes"){ # time to extract some protein domains!
			$desired_seq = "no"; # will not work on another sequence until a match is found in a headers
			$dna = $_;
			print "$dna\n"; ######## WAS WORKING HERE
		} else {
			$dna .= $_;
			# print "$dna\n";
		}
		$sequences{$seq}{dna} = $dna;
	}
}
close($cds_file);

# __END__

# prints the nucleotide output
open (my $outfile_nuc, ">", $output_nuc) or die "Cannot open $output_nuc";
for my $seq (keys %info){
	for my $start (sort { $a <=> $b } keys %{ $info{$seq} }){
		for my $stop (sort { $a <=> $b } keys %{ $info{$seq}{$start} }){
			
			my $dna_seq = $sequences{$seq}{dna};
			print "$dna_seq\n";
			my $domain = $info{$seq}{$start}{$stop}{domain};
			my $sig = $info{$seq}{$start}{$stop}{c_evalue};
			my $nuc_start = ($start * 3) - 2;
			my $nuc_stop = $stop * 3;
			my $length = ($stop - $start + 1) * 3;

			# my $domain_seq = substr($dna_seq, $nuc_start - 1, $length); # nuc_start - 1 b/c the seq starts counting at 1 and perl starts counting at 0
			# print "$dna_seq\n$seq\t$start\t$stop\n\n";

			my $print_nuc_header = ">" . $seq . "_" . $domain . "_" . $nuc_start . "-" . $nuc_stop . " c-Evalue=" . $sig; 
			# print $outfile_nuc "$print_nuc_header\n$domain_seq\n"; # prints the header line and sequence line to the output file
		}
	}
}
close($outfile_nuc);