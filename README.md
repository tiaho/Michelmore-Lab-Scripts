README.md
###Description of the files

**add_ltr_types.pl**

* adds classification for the LTRs

**add_repeat_types.pl**

* adds classification for the repeats

**build_calibrate_cm_infernal.pl**

* builds and calibrates covariance models in infernal for multiple alignments

**coge_filter.pl**

* runs other scripts that filters the CoGe condensed.txt files
* also extracts the chromosome range for the genomes in comparison

**dn_ds_calculator.pl**

* calculates the divergence of a set of sequences by kn/ks

**extract_coge_stats.pl**

* extracts some summary statistics from CoGe analyses

**extract_predicted_protein_domains.pl**

* extracts the predicted protein domains predicted by HMMER3

**extract_sequences_run_clustal.pl**

* extracts sequences needed for multiple sequence alignments, then runs clustal

**filter_markers.pl**

* filters markers for a certain window size and fills in missing data

**filtering_for_circos.pl**

* filters output files from dag_mergeBlock_getLinks_v4.pl to prepare for plotting with Circos

**find_chr_range_coge.pl**

* finds the chromosome ranges of the two genomes in CoGe comparison files

**gff_items_windows.pl**

* determines the number of items in a gff file that are in a particular window size across a genome

**ltr_to_gff3_parser.pl**

* parses the Domains_Ages.txt and FinalClusters.Annotations.txt.classified.txt files to a gff3 file

**ortholog_finder.pl**

* finds the reciprocal best hits and prints the lines they are in

**parse_codeml_output.pl**

* parses the codeml output into 5 files: main table, stats table, and 3 matrices (dN/dS, dN, dS)

**parse_infernal_output.pl**

* parses the infernal output into a gff file

**parse_infernal_output2.pl**

* parses the infernal output into a gff file, also outputs a table

**parse_rfam_file.pl**

* parses the Rfam.seed file from rfam into separate files, based on the type

**split_alingments.pl**

* splits a protein alignment by half, and splits the nucleotide sequence based on the number of amino acids/gaps present

**repeatmasker.out_parser.pl**

* parses the .out file for RepeatMasker
