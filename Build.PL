#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;


# Build the script
my $build = Module::Build->new(
	build_class       => 'Module::Build',
	module_name       => 'Bio::ToolBox::Legacy',
	license           => 'artistic_2',
	dist_version_from => 'lib/Bio/ToolBox/Legacy.pm',
	dist_author       => 'Timothy Parnell <parnell.tj@gmail.com>',
	configure_requires => {
		'Module::Build'           => 0,
	},
	requires          => {
		'Bio::ToolBox'            => '1.66',
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

$build->create_build_script;
exit 0;

