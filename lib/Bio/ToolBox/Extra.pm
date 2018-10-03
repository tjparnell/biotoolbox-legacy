package Bio::ToolBox::Extra;

### modules
require Exporter;
use strict;
use Carp qw(carp cluck croak confess);
use Bio::ToolBox::Data;
use Bio::ToolBox::legacy_helper qw(
	open_to_write_fh
	verify_data_structure
	find_column_index
);
our $CLASS = 'Bio::ToolBox::Data';


our $VERSION = '1.62';


### Variables
# Export
our @ISA = qw(Exporter);
our @EXPORT = qw(
);
our @EXPORT_OK = qw(
	convert_genome_data_2_gff_data 
	convert_and_write_to_gff_file
	index_data_table
);

### The True Statement
1; 



#### Convert a data table into GFF format
sub convert_genome_data_2_gff_data {
	# a subroutine to convert the data table format from genomic bins or
	# windows to a gff format for writing as a gff file
	
	# get passed arguments
	my %args = @_; 
	unless (%args) {
		cluck "no arguments passed!";
		return;
	}
	
	# check data structure
	$args{'data'} ||= undef;
	my $data = $args{'data'};
	unless (verify_data_structure($data) ) {
		cluck "bad data structure!";
		return;
	}
	
	
	### Establish general gff variables
	
	# chromosome
	my $chr_index;
	if (
		exists $args{'chromo'} and 
		$args{'chromo'} =~ /^\d+$/ and
		exists $data->{ $args{'chromo'} }
	) {
		$chr_index = $args{'chromo'};
	}
	else {
		$chr_index = find_column_index($data, '^chr|seq|refseq');
	}
		
	# start position
	my $start_index;
	if (
		exists $args{'start'} and 
		$args{'start'} =~ /^\d+$/ and
		exists $data->{ $args{'start'} }
	) {
		$start_index = $args{'start'};
	}
	else {
		$start_index = find_column_index($data, 'start');
	}
		
	# stop position
	my $stop_index;
	if (
		exists $args{'stop'} and 
		$args{'stop'} =~ /^\d+$/ and
		exists $data->{ $args{'stop'} }
	) {
		$stop_index = $args{'stop'};
	}
	else {
		$stop_index = find_column_index($data, 'stop|end');
	}
	
	
	# check that we have required coordinates
	unless ( defined $chr_index ) {
		cluck " unable to identify chromosome index!";
		return;
	}
	unless ( defined $start_index ) {
		cluck " unable to identify start index!";
		return;
	}
	
	# score
	my $score_index;
	if (
		exists $args{'score'} and 
		$args{'score'} =~ /^\d+$/ and
		exists $data->{ $args{'score'} }
	) {
		$score_index = $args{'score'};
	}
	
	# name
	my $name;
	my $name_index;
	if (exists $args{'name'} and $args{'name'} ne q()) {
		if (
			$args{'name'} =~ /^\d+$/ and
			exists $data->{ $args{'name'} }
		) {
			# name is a single digit, most likely a index
			$name_index = $args{'name'};
		}
		else {
			# name is likely a string
			$name = _escape( $args{'name'} );
		}
	}
	
	# strand
	my $strand_index;
	if (
		exists $args{'strand'} and 
		$args{'strand'} =~ /^\d+$/ and
		exists $data->{ $args{'strand'} }
	) {
		$strand_index = $args{'strand'};
	}
	
	# set gff version, default is 3
	my $gff_version = $args{'version'} || 3;
	
	
	# get array of tag indices
	my @tag_indices;
	if (exists $args{'tags'}) {
		@tag_indices = @{ $args{'tags'} };
	}
	
	# identify the unique ID index
	my $id_index;
	if (
		exists $args{'id'} and 
		$args{'id'} =~ /^\d+$/ and
		exists $data->{ $args{'id'} }
	) {
		$id_index = $args{'id'} ;
	}
	
	# reference to the data table
	my $data_table = $data->{'data_table'};
	
	
	### Identify default values
	
	# gff source tag
	my ($source, $source_index);
	if (exists $args{'source'} and $args{'source'} ne q() ) {
		# defined in passed arguments
		if (
			$args{'source'} =~ /^\d+$/ and 
			exists $data->{ $args{'source'} }
		) {
			# looks like an index
			$source_index = $args{'source'};
		}
		else {
			# a text string
			$source = $args{'source'};
		}
	}
	else {
		# the default is data
		$source = 'data';
	}
	
	# gff method or type column
	my ($method, $method_index);
	if (exists $args{'method'} and $args{'method'} ne q() ) {
		# defined in passed arguments
		if (
			$args{'method'} =~ /^\d+$/ and
			exists $data->{ $args{'method'} }
		) {
			# the method looks like a single digit, most likely an index value
			$method_index = $args{'method'};
		}
		else {
			# explicit method string
			$method = $args{'method'};
		}
	}
	elsif (exists $args{'type'} and $args{'type'} ne q() ) {
		# defined in passed arguments, alternate name
		if (
			$args{'type'} =~ /^\d+$/ and
			exists $data->{ $args{'type'} }
		) {
			# the method looks like a single digit, most likely an index value
			$method_index = $args{'type'};
		}
		else {
			# explicit method string
			$method = $args{'type'};
		}
	}
	elsif (defined $name) {
		# the name provided
		$method = $name;
	}
	elsif (defined $name_index) {
		# the name of the dataset for the features' name
		$method = $data->{$name_index}{'name'};
	}
	elsif (defined $score_index) {
		# the name of the dataset for the score
		$method = $data->{$score_index}{'name'};
	}
	else {
		$method = 'Experiment';
	}
	
	# fix method and source if necessary
	# replace any whitespace or dashes with underscores
	$source =~ s/[\s\-]/_/g if defined $source;
	$method =~ s/[\s\-]/_/g if defined $method;
	
	
	### Other processing
	# convert the start postion to 1-based from 0-based
	my $convert_zero_base = $args{'zero'} || 0;
	
	
	### Reorganize the data table
		# NOTE: this will destroy any information that may be here and not
		# included in the gff data
		# since we're working with referenced data, you better hope that you
		# don't want this data later....
	
	# relabel the data table headers
	$data_table->[0] = [ 
		qw( Chromosome Source Type Start Stop Score Strand Phase Group) 
	];
	
	# re-write the data table
	for my $row (1..$data->{'last_row'}) {
		
		# collect coordinate information
		my $refseq = $data_table->[$row][$chr_index];
		my $start = $data_table->[$row][$start_index];
		my $stop;
		if (defined $stop_index) {
			$stop = $data_table->[$row][$stop_index];
		}
		else {
			$stop = $start;
		}
		if ($convert_zero_base) {
			# coordinates are 0-based, shift the start postion
			$start += 1;
		}
		if ($args{'midpoint'} and $start != $stop) {
			# if the midpoint is requested, then assign the midpoint to both
			# start and stop
			my $position = sprintf "%.0f", ( ($start + $stop) / 2 );
			$start = $position;
			$stop = $position;
		}
		
		# collect strand information
		my $strand;
		if (defined $strand_index) {
			my $value = $data_table->[$row][$strand_index];
			if ($value =~ m/\A [f \+ 1 w]/xi) {
				# forward, plus, one, watson
				$strand = '+';
			}
			elsif ($value =~ m/\A [r \- c]/xi) {
				# reverse, minus, crick
				$strand = '-';
			}
			elsif ($value =~ m/\A [0 \.]/xi) {
				# zero, period
				$strand = '.';
			}
			else {
				# unidentified, assume it's non-stranded
				$strand = '.';
			}
		}
		else {
			# no strand information
			$strand = '.';
		}
		
		# collect gff method/type name
		my $gff_method;
		if (defined $method_index) {
			# variable method, index was defined
			$gff_method = $data_table->[$row][$method_index];
		}
		else {
			# explicit method
			$gff_method = $method;
		}
		
		# collect source tag
		my $gff_source;
		if (defined $source_index) {
			# variable source tag
			$gff_source = $data_table->[$row][$source_index];
		}
		else {
			# static source tag
			$gff_source = $source;
		}
		
		# collect score information
		my $score;
		if (defined $score_index) {
			$score = $data_table->[$row][$score_index];
		}
		else {
			$score = '.';
		}
		
		# collect group information
		my $group;
		if ($gff_version == 3) {
			
			# define and record GFF ID
			if (defined $id_index) {
				# this assumes that the $id_index values are all unique
				# user's responsibility to fix it otherwise
				$group = 'ID=' . $data_table->[$row][$id_index] . ';';
			}
			
			# define and record the GFF Name
			if (defined $name_index) {
				# a name is provided for each feature
				$group .= 'Name=' . _escape( 
					$data_table->[$row][$name_index] );
			}
			elsif (defined $name) {
				# a name string was explicitly defined
				$group .= "Name=$name";
			}
			else {
				# use the method as the name
				$group .= "Name=$gff_method";
			}
		}
		else { 
			# gff_version 2
			if (defined $name_index) {
				$group = "$gff_method \"" . $data_table->[$row][$name_index] . "\"";
			}
			else {
				$group = "Experiment $gff_method";
			}
		}
		
		# add group tag information if present
		foreach (@tag_indices) {
			unless ($data_table->[$row][$_] eq '.') {
				# no tag if null value
				$group .= ';' . lc($data->{$_}{name}) . '=' . 
					_escape( $data_table->[$row][$_] );
			}
		}
		
		# rewrite in gff format
		$data_table->[$row] = [ (
			$refseq,
			$gff_source, 
			$gff_method,
			$start,
			$stop,
			$score,
			$strand, 
			'.', # phase, this generally isn't used
			$group
		) ];
	}
	
	
	
	### Reorganize metadata
	# there may be some useful metadata in the current data hash that 
	# will be pertinant to the re-generated gff data
	# we need to keep this metadata, toss the rest, and re-write new
	
	# from the Bio::ToolBox::db_helper, get_new_genome_list() only really has useful
	# metadata from the start column, index 1
	# also keep any metadata from the score and name columns, if defined
	
	# keep some current metadata
	my $start_metadata_ref = $data->{$start_index};
	my $score_metadata_ref; # new empty hashes
	my $group_metadata_ref;
	if (defined $score_index) {
		$score_metadata_ref = $data->{$score_index};
	}
	if (defined $name_index) {
		$group_metadata_ref = $data->{$name_index};
	}
	
	# delete old metadata
	for (my $i = 0; $i < $data->{'number_columns'}; $i++) {
		# delete the existing metadata hashes
		# they will be replaced with new ones
		delete $data->{$i};
	}
	
	# define new metadata
	$data->{0} = {
		'name'  => 'Chromosome',
		'index' => 0,
		'AUTO'  => 3,
	};
	$data->{1} = {
		'name'  => 'Source',
		'index' => 1,
		'AUTO'  => 3,
	};
	$data->{2} = {
		'name'  => 'Type',
		'index' => 2,
		'AUTO'  => 3,
	};
	$data->{3} = $start_metadata_ref;
	$data->{3}{'name'} = 'Start';
	$data->{3}{'index'} = 3;
	if (keys %{ $data->{3} } == 2) {
		$data->{3}{'AUTO'} = 3;
	}
	$data->{4} = {
		'name'  => 'Stop',
		'index' => 4,
		'AUTO'  => 3,
	};
	$data->{5} = $score_metadata_ref;
	$data->{5}{'name'} = 'Score';
	$data->{5}{'index'} = 5;
	if (keys %{ $data->{5} } == 2) {
		$data->{5}{'AUTO'} = 3;
	}
	$data->{6} = {
		'name'  => 'Strand',
		'index' => 6,
		'AUTO'  => 3,
	};
	$data->{7} = {
		'name'  => 'Phase',
		'index' => 7,
		'AUTO'  => 3,
	};
	$data->{8} = $group_metadata_ref;
	$data->{8}{'name'} = 'Group';
	$data->{8}{'index'} = 8;
	if (keys %{ $data->{8} } == 2) {
		$data->{8}{'AUTO'} = 3;
	}
	
	# reset the number of columns
	$data->{'number_columns'} = 9;
	
	# set the gff metadata to write a gff file
	$data->{'gff'} = $gff_version;
	
	# reset feature
	$data->{'feature'} = 'region';
	
	# set headers to false
	$data->{'headers'} = 0;
	
	# success
	return 1;
}


#### Export a data table to GFF file
sub convert_and_write_to_gff_file {
	# a subroutine to export the data table format from genomic bins or
	# windows to a gff file
	
	# get passed arguments
	my %args = @_; 
	unless (%args) {
		cluck "no arguments passed!";
		return;
	}
	
	# check data structure
	$args{'data'} ||= undef;
	my $data = $args{'data'};
	unless (verify_data_structure($data) ) {
		cluck "bad data structure!";
		return;
	}
	my $data_table = $data->{'data_table'};
	
	
	## Establish general variables
	
	# chromosome
	my $chr_index;
	if (
		exists $args{'chromo'} and 
		$args{'chromo'} =~ /^\d+$/ and
		exists $data->{ $args{'chromo'} }
	) {
		$chr_index = $args{'chromo'};
	}
	else {
		$chr_index = find_column_index($data, '^chr|seq|refseq');
	}
		
	# start position
	my $start_index;
	if (
		exists $args{'start'} and 
		$args{'start'} =~ /^\d+$/ and
		exists $data->{ $args{'start'} }
	) {
		$start_index = $args{'start'};
	}
	else {
		$start_index = find_column_index($data, 'start');
	}
		
	# stop position
	my $stop_index;
	if (
		exists $args{'stop'} and 
		$args{'stop'} =~ /^\d+$/ and
		exists $data->{ $args{'stop'} }
	) {
		$stop_index = $args{'stop'};
	}
	else {
		$stop_index = find_column_index($data, 'stop|end');
	}
	
	# check that we have coordinates
	unless ( defined $chr_index ) {
		cluck " unable to identify chromosome index!";
		return;
	}
	unless ( defined $start_index ) {
		cluck " unable to identify start index!";
		return;
	}
	
	# score
	my $score_index;
	if (
		exists $args{'score'} and 
		$args{'score'} =~ /^\d+$/ and
		exists $data->{ $args{'score'} }
	) {
		$score_index = $args{'score'};
	}
	
	# name
	my $name;
	my $name_index;
	if (exists $args{'name'} and $args{'name'} ne q()) {
		if (
			$args{'name'} =~ /^\d+$/ and
			exists $data->{ $args{'name'} }
		) {
			# name is a single digit, most likely a index
			$name_index = $args{'name'};
		}
		else {
			# name is likely a string
			$name = _escape( $args{'name'} );
		}
	}
	
	# strand
	my $strand_index;
	if (
		exists $args{'strand'} and 
		$args{'strand'} =~ /^\d+$/ and
		exists $data->{ $args{'strand'} }
	) {
		$strand_index = $args{'strand'};
	}
	
	# GFF file version, default is 3
	my $gff_version = $args{'version'} || 3;
	
	# get array of tag indices
	my @tag_indices;
	if (exists $args{'tags'}) {
		@tag_indices = @{ $args{'tags'} };
	}
	
	# identify the unique ID index
	my $id_index;
	if (
		exists $args{'id'} and 
		$args{'id'} =~ /^\d+$/ and
		exists $data->{ $args{'id'} }
	) {
		$id_index = $args{'id'} ;
	}
	
	
	
	## Set default gff data variables
	
	# gff source tag
	my ($source, $source_index);
	if (exists $args{'source'} and $args{'source'} ne q() ) {
		# defined in passed arguments
		if (
			$args{'source'} =~ /^\d+$/ and 
			exists $data->{ $args{'source'} }
		) {
			# looks like an index
			$source_index = $args{'source'};
		}
		else {
			# a text string
			$source = $args{'source'};
		}
	}
	else {
		# the default is data
		$source = 'data';
	}
	
	# gff method or type column
	my ($method, $method_index);
	if (exists $args{'method'} and $args{'method'} ne q() ) {
		# defined in passed arguments
		if (
			$args{'method'} =~ /^\d+$/ and
			exists $data->{ $args{'method'} }
		) {
			# the method looks like a single digit, most likely an index value
			$method_index = $args{'method'};
		}
		else {
			# explicit method string
			$method = $args{'method'};
		}
	}
	elsif (exists $args{'type'} and $args{'type'} ne q() ) {
		# defined in passed arguments, alternate name
		if (
			$args{'type'} =~ /^\d+$/ and
			exists $data->{ $args{'type'} }
		) {
			# the method looks like a single digit, most likely an index value
			$method_index = $args{'type'};
		}
		else {
			# explicit method string
			$method = $args{'type'};
		}
	}
	elsif (defined $name) {
		# the name provided
		$method = $name;
	}
	elsif (defined $name_index) {
		# the name of the dataset for the features' name
		$method = $data->{$name_index}{'name'};
	}
	elsif (defined $score_index) {
		# the name of the dataset for the score
		$method = $data->{$score_index}{'name'};
	}
	else {
		$method = 'Experiment';
	}
	# fix method and source if necessary
	# replace any whitespace or dashes with underscores
	$source =~ s/[\s\-]/_/g if defined $source;
	$method =~ s/[\s\-]/_/g if defined $method;
	
	
	## Open output file
	# get the filename
	my $filename;
	if ( $args{'filename'} ne q() ) {
		$filename = $args{'filename'};
		# remove unnecessary extensions
		$filename =~ s/\.gz$//;
		$filename =~ s/\.txt$//;
		unless ($filename =~ /\.gff$/) {
			# add extension if necessary
			$filename .= '.gff';
		}
	}
	elsif (defined $name) {
		# specific name provided
		$filename = $name . '.gff';
	}
	elsif (defined $method and $method ne 'Experiment') {
		# use the method name, so long as it is not the default Experiment
		$filename = $method . '.gff';
	}
	elsif (defined $data->{'basename'}) {
		# use the base file name for lack of a better name
		$filename = $data->{'basename'} . '.gff';
	}
	else {
		# what, still no name!!!????
		$filename = 'your_stupid_output_gff_file_with_no_name.gff';
	}
	if ($gff_version == 3) {
		$filename .= '3'; # make extension gff3
	}
	
	# open the file for writing 
	my $gz = $args{'gz'};
	my $output_gff = open_to_write_fh($filename, $gz);
	
	# write basic headers
	print {$output_gff} "##gff-version $gff_version\n";
	if (exists $data->{'filename'}) {
		# record the original file name for reference
		print {$output_gff} "# Exported from file '", 
			$data->{'filename'}, "'\n";
	}
	
	
	### Write the column metadata headers
	# write the metadata lines only if there is useful information
	# and only for the pertinent columns (chr, start, score)
	# we will check the relavent columns for extra information beyond
	# that of name and index
	# we will write the metadata then for that dataset that is being used
	# substituting the column name and index appropriate for a gff file
	
	# check the chromosome metadata
	if (scalar( keys %{ $data->{$chr_index} } ) > 2) {
		# chromosome has extra keys of info
		print {$output_gff} "# Column_0 ";
		my @pairs;
		foreach (sort {$a cmp $b} keys %{ $data->{$chr_index} } ) {
			if ($_ eq 'index') {
				next;
			}
			elsif ($_ eq 'name') {
				push @pairs, "name=Chromosome";
			}
			else {
				push @pairs,  $_ . '=' . $data->{$chr_index}{$_};
			}
		}
		print {$output_gff} join(";", @pairs), "\n";
	}
	
	# check the start metadata
	if (scalar( keys %{ $data->{$start_index} } ) > 2) {
		# start has extra keys of info
		print {$output_gff} "# Column_3 ";
		my @pairs;
		foreach (sort {$a cmp $b} keys %{ $data->{$start_index} } ) {
			if ($_ eq 'index') {
				next;
			}
			elsif ($_ eq 'name') {
				push @pairs, "name=Start";
			}
			else {
				push @pairs,  $_ . '=' . $data->{$start_index}{$_};
			}
		}
		print {$output_gff} join(";", @pairs), "\n";
	}
	
	# check the score metadata
	if (
		defined $score_index and
		scalar( keys %{ $data->{$score_index} } ) > 2
	) {
		# score has extra keys of info
		print {$output_gff} "# Column_5 ";
		my @pairs;
		foreach (sort {$a cmp $b} keys %{ $data->{$score_index} } ) {
			if ($_ eq 'index') {
				next;
			}
			elsif ($_ eq 'name') {
				push @pairs, "name=Score";
			}
			else {
				push @pairs,  $_ . '=' . $data->{$score_index}{$_};
			}
		}
		print {$output_gff} join(";", @pairs), "\n";
	}
	
	# check the name metadata
	if (
		defined $name_index and
		scalar( keys %{ $data->{$name_index} } ) > 2
	) {
		# score has extra keys of info
		print {$output_gff} "# Column_8 ";
		my @pairs;
		foreach (sort {$a cmp $b} keys %{ $data->{$name_index} } ) {
			if ($_ eq 'index') {
				next;
			}
			elsif ($_ eq 'name') {
				push @pairs, "name=Group";
			}
			else {
				push @pairs,  $_ . '=' . $data->{$name_index}{$_};
			}
		}
		print {$output_gff} join(";", @pairs), "\n";
	}
	
			
	
	### Write the gff features
	for my $row (1..$data->{'last_row'}) {
		
		# collect coordinate information
		my $refseq = $data_table->[$row][$chr_index];
		my $start = $data_table->[$row][$start_index];
		my $stop;
		if (defined $stop_index) {
			$stop = $data_table->[$row][$stop_index];
		}
		else {
			$stop = $start;
		}
		if ($args{'midpoint'} and $stop != $stop) {
			# if the midpoint is requested, then assign the midpoint to both
			# start and stop
			my $position = sprintf "%.0f", ($start + $stop)/2;
			$start = $position;
			$stop = $position;
		}
		
		# collect score information
		my $score;
		if (defined $score_index) {
			$score = $data_table->[$row][$score_index];
		}
		else {
			$score = '.';
		}
		
		# collect strand information
		my $strand;
		if (defined $strand_index) {
			my $value = $data_table->[$row][$strand_index];
			if ($value =~ m/\A [f \+ 1 w]/xi) {
				# forward, plus, one, watson
				$strand = '+';
			}
			elsif ($value =~ m/\A [r \- c]/xi) {
				# reverse, minus, crick
				$strand = '-';
			}
			elsif ($value =~ m/\A [0 \.]/xi) {
				# zero, period
				$strand = '.';
			}
			else {
				# unidentified, assume it's non-stranded
				$strand = '.';
			}
		}
		else {
			# no strand information
			$strand = '.';
		}
		
		# collect gff method/type name
		my $gff_method;
		if (defined $method_index) {
			# variable method, index was defined
			$gff_method = $data_table->[$row][$method_index];
		}
		else {
			# explicit method
			$gff_method = $method;
		}
		
		# collect source tag
		my $gff_source;
		if (defined $source_index) {
			# variable source tag
			$gff_source = $data_table->[$row][$source_index];
		}
		else {
			# static source tag
			$gff_source = $source;
		}
		
		# collect group information based on version
		my $group;
		if ($gff_version == 3) {
			
			# define and record GFF ID
			if (defined $id_index) {
				# this assumes that the $id_index values are all unique
				# user's responsibility to fix it otherwise
				$group = 'ID=' . $data_table->[$row][$id_index] . ';';
			}
			
			# define and record the GFF Name
			if (defined $name_index) {
				# a name is provided for each feature
				$group .= 'Name=' . _escape( 
					$data_table->[$row][$name_index] );
			}
			elsif (defined $name) {
				# a name string was explicitly defined
				$group .= "Name=$name";
			}
			else {
				# use the method as the name
				$group .= "Name=$gff_method";
			}
		}
		else {
			# gff version 2
			if (defined $name) {
				$group = "$gff_method \"$name\"";
			}
			elsif (defined $name_index) {
				$group = "$gff_method \"" . $data_table->[$row][$name_index] . "\"";
			}
			else {
				# really generic
				$group = "Experiment \"$gff_method\"";
			}
		}
		
		# add group tag information if present
		foreach (@tag_indices) {
			unless ($data_table->[$row][$_] eq '.') {
				# no tag if null value
				$group .= ';' . lc($data->{$_}{name}) . '=' . 
					_escape( $data_table->[$row][$_] );
			}
		}
		
		# Write gff feature
		print {$output_gff} join("\t", (
			$refseq,
			$gff_source, 
			$gff_method,
			$start,
			$stop,
			$score,
			$strand, 
			'.', # phase, this generally isn't used
			$group
		) ), "\n";
		
	}
	
	# success
	$output_gff->close;
	return $filename;
}



### Internal subroutine to escape special characters for GFF3 files
sub _escape {
	my $string = shift;
	# this magic incantation was borrowed from Bio::Tools::GFF
	$string =~ s/([\t\n\r%&\=;, ])/sprintf("%%%X",ord($1))/ge;
	return $string;
}



#### Index a data table
sub index_data_table {
	
	# get the arguements
	my ($Data, $increment) = @_;
	
	# check data structure
	unless (defined $Data) {
		carp " No data structure passed!";
		return;
	}
	unless (ref($Data) eq $CLASS) {
		# try an impromptu blessing and hope this works!
		bless($Data, $CLASS);
	}
	
	unless ( $Data->verify ) {
		return;
	}
	if (exists $Data->{'index'}) {
		warn " data structure is already indexed!\n";
		return 1;
	}
	
	# check column indices
	my $chr_index = $Data->find_column('^chr|seq|refseq');
	my $start_index = $Data->find_column('^start');
	unless (defined $chr_index and $start_index) {
		carp " unable to find chromosome and start dataset indices!\n";
		return;
	}
	
	# define increment value
	unless (defined $increment) {
		# calculate default value
		$increment = $Data->metadata($start_index, 'win');
		if (defined $increment) {
			# in genome datasets, window size metadata is stored with the 
			# start position
			# increment is window size x 20
			# seems like a reasonable compromise between index size and efficiency
			$increment *= 20;
		}
		else {
			# use some random made-up default value that could be totally 
			# inappropriate, maybe we should carp a warning instead
			$increment = 100;
		}
	}
	$Data->{'index_increment'} = $increment;
	
	# generate index
	my %index;
	for (my $row = 1; $row <= $Data->last_row; $row++) {
		
		# the index will consist of a complex hash structure
		# the first key will be the chromosome name
		# the first value will be the second key, and is the integer of 
		# the start position divided by the increment
		# the second value will be the row index number 
		
		# calculate the index value
		my $start = $Data->value($row, $start_index);
		my $chr   = $Data->value($row, $chr_index);
		my $index_value = int( $start / $increment );
		
		# check and insert the index value
		unless (exists $index{ $chr }{ $index_value} ) {
			# insert the current row, which should be the first occurence
			$index{$chr}{ $index_value } = $row;
		}
	}
	
	# associate the index hash
	$Data->{'index'} = \%index;
	
	# success
	return 1;
}



__END__

=head1 NAME

Bio::ToolBox::Extra - Esoteric scripts and functions for BioToolBox

=head1 DESCRIPTION

These are additional subroutines that used to be part 
of L<Bio::ToolBox::file_helper> before being expunged in version 1.26.
They are required by a number of old, specialized, esoteric, and/or 
outdate perl scripts that used to be part of the BioToolBox package 
before being expunged and relegated to a separate distribution. 

Most of these scripts are too old or not worthy of being rewritten 
to use the more modern OO API of L<Bio::ToolBox::Data>. So they 
still use the original functions exported from file_helper and 
db_helper, with the hopes that they won't break too much. 

The functions in this module allow the data structure to be exported 
as a GFF file. This was useful back in the day when I was using the 
L<Bio::DB::GFF> database for everything, including microarray data. 
Nowadays, these functions are not used in the main BioToolBox 
package and scripts, hence their expulsion to this lowly module to 
support these old scripts that may still be useful to someone someday.

=head1 USAGE

Call the module at the beginning of your perl script and pass a list of the 
desired modules to import. None are imported by default.
  
  use Bio::ToolBox::Extra qw(load_data_file convert_genome_data_2_gff_data);
  

=over

=item convert_genome_data_2_gff_data()

This subroutine will convert an existing data hash structure as described above
and convert it to a defined gff data structure, i.e. one that has the nine 
defined columns. Once converted, a gff data file may then be written using the
write_data_file() subroutine. To convert and write the gff file in one 
step, see the following subroutine, convert_and_write_gff_file();

NOTE: This method is DESTRUCTIVE!!!!
Since the data table will be completely reorganized, any extraneous data 
in the data table will be discarded. Since referenced data is being 
used, any data loss may be significant and unexpected. A normal data file
should be written first to preserve extraneous data, and the conversion to
gff data be the last operation done.

Since the gff data structure requires genomic coordinates, this data must be 
present as identifiable datasets in the data table and metadata. It looks 
specifically for datasets labeled 'Chromosome', 'Start', and 'Stop' or 'End'. 
Failure to identify these datasets will simply return nothing. A dataset 
generated with get_new_genome_list() in Bio::ToolBox::db_helper will generate these
datasets. 

The subroutine must be passed a reference to an anonymous hash with the 
arguments. The keys include

  Required:
  data     => A scalar reference to the data hash. The data hash 
              should be as described in this module.
  Optional: 
  chromo   => The index of the column in the data table that contains
              the chromosome or reference name. By default it 
              searches for the first column with a name that begins 
              with 'chr' or 'refseq' or 'seq'.
  start    => The index of the column with the start position. By 
              default it searches for the first column with a name 
              that contains 'start'.
  stop     => The index of the column with the stop position. By 
              default it searches for the first column with a name 
              that contains 'stop' or 'end'.
  score    => The index of the dataset in the data table to be used 
              as the score column in the gff data.
  name     => The name to be used for the GFF features. Pass either 
              the index of the dataset in the data table that 
              contains the unique name for each gff feature, or a 
              text string to be used as the name for all of the 
              features. This information will be used in the 
              'group' column.
  strand   => The index of the dataset in the data table to be used
              for strand information. Accepted values might include
              any of the following 'f(orward), r(everse), w(atson),
              c(rick), +, -, 1, -1, 0, .).
  source   => A scalar value representing either the index of the 
              column containing values, or a text string to 
              be used as the GFF source value. Default is 'data'.
  type     => A scalar value representing either the index of the 
              column containing values, or a text string to 
              be used as the GFF type or method value. If not 
              defined, it will use the column name of the dataset 
              used for either the 'score' or 'name' column, if 
              defined. As a last resort, it will use the most 
              creative method of 'Experiment'.
  method   => Alias for "type".
  midpoint => A boolean (1 or 0) value to indicate whether the 
              midpoint between the actual 'start' and 'stop' values
              should be used instead of the actual values. Default 
              is false.
  zero     => The coordinates are 0-based (interbase). Convert to 
              1-based format (bioperl conventions).
  tags     => Provide an anonymous array of indices to be added as 
              tags in the Group field of the GFF feature. The tag's 
              key will be the column's name. As many tags may be 
              added as desired.
  id       => Provide the index of the column containing unique 
              values which will be used in generating the GFF ID 
              in v.3 GFF files. If not provided, the ID is 
              automatically generated from the name.
  version  => The GFF version (2 or 3) to be written. The default is 
              version 3.

The subroutine will return true if the conversion was successful, otherwise it
will return nothing.

Example

	my $data_ref = load_data_file($filename);
	...
	my $success = convert_genome_data_2_gff_data(
		'data'     => $data_ref,
		'score'    => 3,
		'midpoint' => 1,
	);
	if ($success) {
		# write a gff file
		my $success_write = write_data_file(
			'data'     => $data_ref,
			'filename' => $filename,
		);
		if ($success_write) {
			print "wrote $success_write!";
		}
	}


=item convert_and_write_to_gff_file()

This subroutine will convert a BioToolBox data structure as described above into 
GFF format and write the file. It will preserve the current data structure 
and convert the data on the fly as the file is written, unlike the 
destructive subroutine convert_genome_data_2_gff_data(). 

Either a v.2 or v.3 GFF file may be written. The only metadata written 
is the original data's filename (if present) and any dataset (column) 
metadata that contains more than the basics (name and index).

Since the gff data structure requires genomic coordinates, this data must be 
present as identifiable datasets in the data table and metadata. It looks 
specifically for datasets labeled 'Chromosome', 'Start', and optionally 
'Stop' or 'End'. Failure to identify these datasets will simply return 
nothing. A dataset generated with get_new_genome_list() in 
Bio::ToolBox::db_helper will generate these coordinate datasets. 

If successful, the subroutine will return the name of the output gff file
written.

The subroutine must be passed a reference to an anonymous hash with the 
arguments. The keys include

  Required:
  data     => A scalar reference to the data hash. The data hash 
              should be as described in this module.
  Optional: 
  filename => The name of the output GFF file. If not specified, 
              the default value is, in order, the method, name of 
              the indicated 'name' dataset, name of the indicated 
              'score' dataset, or the originating file basename.
  version  => The version of GFF file to write. Acceptable values 
              include '2' or '3'. For v.3 GFF files, unique ID 
              values will be auto generated, unless provided with a 
              'name' dataset index. Default is to write v.3 files.
  chromo   => The index of the column in the data table that contains
              the chromosome or reference name. By default it 
              searches for the first column with a name that begins 
              with 'chr' or 'refseq' or 'seq'.
  start    => The index of the column with the start position. By 
              default it searches for the first column with a name 
              that contains 'start'.
  stop     => The index of the column with the stop position. By 
              default it searches for the first column with a name 
              that contains 'stop' or 'end'.
  score    => The index of the dataset in the data table to be used 
              as the score column in the gff data.
  name     => The name to be used for the GFF features. Pass either 
              the index of the dataset in the data table that 
              contains the unique name for each gff feature, or a 
              text string to be used as the name for all of the 
              features. This information will be used in the 
              'group' column.
  strand   => The index of the dataset in the data table to be used
              for strand information. Accepted values might include
              any of the following 'f(orward), r(everse), w(atson),
              c(rick), +, -, 1, -1, 0, .).
  source   => A scalar value representing either the index of the 
              column containing values, or a text string to 
              be used as the GFF source value. Default is 'data'.
  type     => A scalar value representing either the index of the 
              column containing values, or a text string to 
              be used as the GFF type or method value. If not 
              defined, it will use the column name of the dataset 
              used for either the 'score' or 'name' column, if 
              defined. As a last resort, it will use the most 
              creative method of 'Experiment'.
  method   => Alias for "type".
  midpoint => A boolean (1 or 0) value to indicate whether the 
              midpoint between the actual 'start' and 'stop' values
              should be used instead of the actual values. Default 
              is false.
  tags     => Provide an anonymous array of indices to be added as 
              tags in the Group field of the GFF feature. The tag's 
              key will be the column's name. As many tags may be 
              added as desired.
  id       => Provide the index of the column containing unique 
              values which will be used in generating the GFF ID 
              in v.3 GFF files. If not provided, the ID is 
              automatically generated from the name.

Example

	my $data_ref = load_data_file($filename);
	...
	my $success = convert_and_write_to_gff_file(
		'data'     => $data_ref,
		'score'    => 3,
		'midpoint' => 1,
		'filename' => "$filename.gff",
		'version'  => 2,
	);
	if ($success) {
		print "wrote file '$success'!";
	}
	
=item index_data_table()

This function creates an index hash for genomic bin features in the 
data table. Rather than stepping through an entire data table of 
genomic coordinates looking for a specific chromosome and start 
feature (or data row), an index may be generated to speed up the 
search, such that only a tiny portion of the data_table needs to be 
stepped through to identify the correct feature.

This function generates two additional keys in the data structure 
described above, C</index> and C</index_increment>. Please refer to 
those items in L<Bio::ToolBox::data_helper> for their description.

Pass this subroutine one or two arguments. The first is the reference 
to the data structure. The optional second argument is an integer 
value to be used as the index_increment value. This value determines 
the size and efficiency of the index; small values generate a larger 
but more efficient index, while large values do the opposite. A 
balance should be struck between memory consumption and speed. The 
default value is 20 x the feature window size (determined from the 
metadata). Therefore, finding the specific genomic coordinate 
feature should take no more than 20 steps from the indexed position. 
If successful, the subroutine returns a true value.

Example

	my $main_data = load_data_file($filename);
	index_data_table($main_data) or 
		die " unable to index data table!\n";
	...
	my $chr = 'chr9';
	my $start = 123456;
	my $index_value = 
		int( $start / $main_data->{index_increment} ); 
	my $starting_row = $main_data->{index}{$chr}{$index_value};
	for (
		my $row = $starting_row;
		$row <= $main_data->{last_row};
		$row++
	) {
		if (
			$main_data->{data_table}->[$row][0] eq $chr and
			$main_data->{data_table}->[$row][1] <= $start and
			$main_data->{data_table}->[$row][2] >= $start
		) {
			# do something
			# you could stop here, but what if you had overlapping
			# genomic bins for some odd reason?
		} elsif (
			$main_data->{data_table}->[$row][0] ne $chr
		) {
			# no longer on same chromosome, stop the loop
			last;
		} elsif (
			$main_data->{data_table}->[$row][1] > $start
		) {
			# moved beyond the window, stop the loop
			last;
		}
	}
		
=back

=head1 AUTHOR

 Timothy J. Parnell, PhD
 Howard Hughes Medical Institute
 Dept of Oncological Sciences
 Huntsman Cancer Institute
 University of Utah
 Salt Lake City, UT, 84112

This package is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.  
