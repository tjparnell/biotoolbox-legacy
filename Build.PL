#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;



# Initial build options
my $options = get_base_options();

# Build the script
my $build = Module::Build->new(%$options);
$build->create_build_script;
exit 0;


###### subroutines to assist in building ########


sub get_base_options {
	my %options = (
		build_class       => 'Module::Build',
		module_name       => 'Bio::ToolBox::Extra',
		license           => 'perl',
		dist_version_from => 'lib/Bio/ToolBox/Extra.pm',
		dist_author       => 'Timothy Parnell <parnell.tj@gmail.com>',
		dist_abstract     => 'Esoteric scripts and functions for BioToolBox',
		configure_requires => {
			'Module::Build'           => 0,
		},
		requires          => {
			'Bio::ToolBox'            => '1.62',
		},
		recommends        => {
		},
		script_files => [
			'scripts/bam2gff_bed.pl',
			'scripts/bar2wig.pl',
			'scripts/big_file2gff3.pl',
			'scripts/bin_genomic_data.pl',
			'scripts/change_chr_prefix.pl',
			'scripts/compare_subfeature_scores.pl',
			'scripts/convert_yeast_genome_version.pl',
			'scripts/find_enriched_regions.pl',
			'scripts/get_bam_seq_stats.pl',
			'scripts/intersect_SNPs.pl',
			'scripts/locate_SNPs.pl',
			'scripts/map_oligo_data2gff.pl',
			'scripts/map_transcripts.pl',
			'scripts/novo_wrapper.pl',
			'scripts/process_microarray.pl',
			'scripts/split_bam_by_isize.pl',
			'scripts/ucsc_cytoband2gff3.pl',
		],
	);
	return \%options;
}


