package Bio::ToolBox::legacy_helper;
our $VERSION = '1.60';

=head1 NAME

Bio::ToolBox::legacy_helper - exported methods to support legacy API

=head1 DESCRIPTION

These are legacy methods that used to be provided by Bio::ToolBox::data_helper 
and Bio::ToolBox::file_helper, but have now been superseded by the object 
oriented API of L<Bio::ToolBox::Data>. All new scripts should use the 
L<Bio::ToolBox::Data> API and NOT these methods. 

=cut

use strict;
require Exporter;
use Carp qw(carp cluck croak confess);
use Bio::ToolBox::Data 1.60;
use Bio::ToolBox::db_helper qw(
	open_db_connection
	get_db_feature
	get_segment_score
);
use Bio::ToolBox::db_helper::constants;


our @ISA = qw(Exporter);
our @EXPORT = qw(
	generate_data_structure
	verify_data_structure
	find_column_index
	open_data_file 
	load_data_file
	write_data_file 
	open_to_read_fh
	open_to_write_fh
	write_summary_data
	check_file
	get_region_dataset_hash
	get_chromo_region_score
);
our $CLASS = 'Bio::ToolBox::Data';

1;

sub generate_data_structure {
	# Collect the feature
	my $feature = shift;
	
	# Collect the array of dataset headers
	my @datasets = @_;
	
	# Initialize the hash structure
	my $Data = $CLASS->new(
		feature     => $feature,
		datasets    => \@datasets,
	);
	
	# the old libraries used a data structure remarkably similar
	# to the Data object, so even though we are returning a blessed object, 
	# the old programs will access the underlying data structure just as before and 
	# should work in the same manner, more or less
	return $Data;
}

sub verify_data_structure {
	my $Data = shift;
	
	unless (ref($Data) eq $CLASS) {
		# try an impromptu blessing and hope this works!
		bless($Data, $CLASS);
	}
	return $Data->verify;
}

sub find_column_index {
	my ($Data, $name) = @_;
	
	unless (ref($Data) eq $CLASS) {
		# try an impromptu blessing and hope this works!
		bless($Data, $CLASS);
	}
	return $Data->find_column($name);
}

sub open_data_file {
	my $file = shift;
	my $Data = $CLASS->new();
	my $filename = $Data->check_file($file);
	$Data->add_file_metadata($filename);
	my $fh = $Data->open_to_read_fh or return;
	$Data->{fh} = $fh;
	$Data->parse_headers;
	return ($Data->{fh}, $Data);
}

sub load_data_file {
	my $file = shift;
	my $Data = $CLASS->new(file => $file);
	return $Data;
}

sub write_data_file {
	my %args = @_; 
	$args{'data'}     ||= undef;
	$args{'filename'} ||= undef;
	$args{'format'}   ||= undef;
	unless (exists $args{'gz'}) {$args{'gz'} = undef} 
	my $Data = $args{data};
	return unless $Data;
	unless (ref($Data) eq $CLASS) {
		# try an impromptu blessing and hope this works!
		bless($Data, $CLASS);
	}
	return $Data->write_file(
		filename    => $args{'filename'},
		'format'    => $args{'format'},
		'gz'        => $args{gz},
	);
}

sub open_to_read_fh {
	my $filename = shift;
	return unless defined $filename;
	return $CLASS->open_to_read_fh($filename);
}

sub open_to_write_fh {
	my ($filename, $gz, $append) = @_;
	return unless defined $filename;
	return $CLASS->open_to_write_fh($filename, $gz, $append);
}

sub write_summary_data {
	my %args = @_; 
	my $Data = $args{data} || undef;
	return unless defined $Data;
	unless (ref($Data) eq $CLASS) {
		# try an impromptu blessing and hope this works!
		bless($Data, $CLASS);
	}
	delete $args{data};
	return $Data->summary_file(%args);
}

sub check_file {
	my $filename = shift;
	return $CLASS->check_file($filename);
}


sub get_chromo_region_score {
	# this was extracted from Bio::ToolBox::db_helper version 1.45
	# and updated to work with Bio::ToolBox::db_helper version 1.62
	
	# retrieve passed values
	my %args = @_; 
	
	# check the data source
	unless ($args{'dataset'}) {
		confess " no dataset requested!";
	}
	
	# Open a db connection 
	$args{'db'} ||= $args{'ddb'} || undef;
	unless ($args{'db'} or $args{'dataset'} =~ /^(?:file|http|ftp)/) {
		# database is only really necessary if we are not using an indexed file dataset
		confess "no database provided!";
	}
	my $db;
	if ($args{'db'}) {
		$db = open_db_connection( $args{'db'} ) or 
			confess "cannot open database!";
	}
	
	# establish coordinates
	$args{'chromo'} ||= $args{'seq'} || $args{'seq_id'} || undef;
	return '.' unless $args{'chromo'}; # null value
	$args{'start'}    = exists $args{'start'} ? $args{'start'} : 1;
	$args{'start'}    = 1 if ($args{'start'} <= 0);
	$args{'stop'}   ||= $args{'end'};
	$args{'strand'}   = exists $args{'strand'} ? $args{'strand'} : 0;
	if ($args{'stop'} < $args{'start'}) {
		# coordinates are flipped, reverse strand
		return '.' if ($args{'stop'} <= 0);
		my $stop = $args{'start'};
		$args{'start'} = $args{'stop'};
		$args{'stop'}  = $stop;
		$args{'strand'} = -1;
	}
	
	# define default values as necessary
	$args{'value'}    ||= 'score';
	$args{'stranded'} ||= 'all';
	
	# check for unsupported options
	if (exists $args{'rpm_sum'} and defined $args{'rpm_sum'}) {
		confess "get_chromo_region_score() option 'rpm_sum' is no longer supported! ";
	}
	if ($args{'value'} ne 'score') {
		confess "get_chromo_region_score() option 'value' is no longer supported! Only scores are collected. ";
	}
	
	# get the scores for the region
	my @params;
	$params[CHR]   = $args{chromo};
	$params[STRT]  = $args{start};
	$params[STOP]  = $args{stop};
	$params[STR]   = $args{strand};
	$params[STND]  = $args{'stranded'};
	$params[METH]  = $args{'method'};
	$params[RETT]  = 0; # return score immediately 
	$params[DB]    = $db;
	$params[DATA]  = $args{'dataset'};
	return get_segment_score(@params);
}



sub get_region_dataset_hash {
	# this was extracted from Bio::ToolBox::db_helper version 1.45
	# and updated to work with Bio::ToolBox::db_helper version 1.62
	
	# retrieve passed values
	my %args = @_; 
	
	### Initialize parameters
	
	# check the data source
	$args{'dataset'} ||= undef;
	unless ($args{'dataset'}) {
		confess " no dataset requested!";
	}
	
	# Open a db connection 
	$args{'db'} ||= undef;
	my $db;
	if ($args{'db'}) {
		$db = open_db_connection( $args{'db'} ) or 
			confess "cannot open database!";
	}
	
	# Open the data database if provided
	$args{'ddb'} ||= undef;
	my $ddb;
	if ($args{'ddb'}) {
		$ddb = open_db_connection( $args{'ddb'} ) or
			confess "requested data database could not be opened!\n";
	}
	else {
		# reuse something else
		if ($db) {
			$ddb = $db;
		}
		elsif ($args{'dataset'} =~ /^(?:file|http|ftp)/) {
			$ddb = $args{'dataset'};
		}
		else {
			confess "no database or indexed dataset supplied!";
		}
	}
	
	# confirm options and check we have what we need 
	$args{'name'}   ||= undef;
	$args{'type'}   ||= undef;
	$args{'id'}     ||= undef;
	$args{'chromo'} ||= $args{'seq'} || $args{'seq_id'} || undef;
	$args{'start'}    = exists $args{'start'} ? $args{'start'} : 1;
	$args{'stop'}   ||= $args{'end'};
	$args{'strand'}   = exists $args{'strand'} ? $args{'strand'} : undef;
	unless (
		(defined $args{'name'} and defined $args{'type'}) or 
		(defined $args{'chromo'} and $args{'start'} and $args{'stop'})
	) {
		return;
	};
	if (
		(defined $args{'stop'} and defined $args{'start'}) and 
		($args{'stop'} < $args{'start'})
	) {
		# coordinates are flipped, reverse strand
		return '.' if $args{'stop'} < 0;
		my $stop = $args{'start'};
		$args{'start'} = $args{'stop'};
		$args{'stop'}  = $stop;
		$args{'strand'} = -1;
	}
	
	# assign other defaults
	$args{'stranded'} ||= 'all';
	$args{'value'}    ||= 'score';
	$args{'position'} ||= 5;
	$args{'extend'}   ||= 0;
	$args{'absolute'} ||= 0;
	
	# avoid feature types
	if (exists $args{'avoid'} and defined $args{'avoid'}) {
		if (ref $args{'avoid'} eq 'ARRAY') {
			# we have types, presume they're ok
		}
		elsif ($args{'avoid'} eq '1') {
			# old style boolean value
			if (defined $args{'type'}) {
				$args{'avoid'} = [ $args{'type'} ];
			}
			else {
				# no type provided, we can't avoid that which is not defined! 
				# this is an error, but won't complain as we never did before
				$args{'avoid'} = undef;
			}
		}
		elsif ($args{'avoid'} =~ /w+/i) {
			# someone passed a string, a feature type perhaps?
			$args{'avoid'} = [ $args{'avoid'} ];
		}
		else {
			# huh?
			$args{'avoid'} = undef;
		}
	}
	else {
		$args{'avoid'} = undef;
	}
	
	
	
	# the final coordinates
	my $fref_pos; # to remember the feature reference position
	my $fchromo;
	my $fstart;
	my $fstop;
	my $fstrand;
	my $primary; # database ID to be used when matching overlapping features
	
	
	
	### Define the chromosomal region segment
	# we will use the primary database to establish the intitial feature
	# and determine the chromosome, start and stop
	
	# Extend a named database feature
	if (
		( $args{'id'} or ( $args{'name'} and $args{'type'} ) ) and 
		$args{'extend'}
	) {
		
		# first define the feature to get endpoints
		confess "database required to use named features" unless $db;
		my $feature = get_db_feature(
			'db'    => $db,
			'id'    => $args{'id'},
			'name'  => $args{'name'},
			'type'  => $args{'type'},
		) or return; 
		$primary = $feature->primary_id;
		
		# determine the strand
		$fstrand   = defined $args{'strand'} ? $args{'strand'} : $feature->strand;
		
		# record the feature reference position and strand
		if ($args{'position'} == 5 and $fstrand >= 0) {
			$fref_pos = $feature->start;
		}
		elsif ($args{'position'} == 3 and $fstrand >= 0) {
			$fref_pos = $feature->end;
		}
		elsif ($args{'position'} == 5 and $fstrand < 0) {
			$fref_pos = $feature->end;
		}
		elsif ($args{'position'} == 3 and $fstrand < 0) {
			$fref_pos = $feature->start;
		}
		elsif ($args{'position'} == 4) {
			# strand doesn't matter here
			$fref_pos = $feature->start + int(($feature->length / 2) + 0.5);
		}
		
		# record final coordinates
		$fchromo = $feature->seq_id;
		$fstart  = $feature->start - $args{'extend'};
		$fstop   = $feature->end + $args{'extend'};
	} 
		
	# Specific start and stop coordinates of a named database feature
	elsif (
		( $args{'id'} or ( $args{'name'} and $args{'type'} ) ) and 
		$args{'start'} and $args{'stop'}
	) {
		# first define the feature to get endpoints
		confess "database required to use named features" unless $db;
		my $feature = get_db_feature(
			'db'    => $db,
			'id'    => $args{'id'},
			'name'  => $args{'name'},
			'type'  => $args{'type'},
		) or return; 
		$primary = $feature->primary_id;
		
		# determine the strand
		$fstrand   = defined $args{'strand'} ? $args{'strand'} : $feature->strand;
		
		# determine the cooridnates based on the identified feature
		if ($args{'position'} == 5 and $fstrand >= 0) {
			# feature is on forward, top, watson strand
			# set segment relative to the 5' end
			
			# record final coordinates
			$fref_pos  = $feature->start;
			$fchromo   = $feature->seq_id;
			$fstart    = $feature->start + $args{'start'};
			$fstop     = $feature->start + $args{'stop'};
		}
		
		elsif ($args{'position'} == 5 and $fstrand < 0) {
			# feature is on reverse, bottom, crick strand
			# set segment relative to the 5' end
			
			# record final coordinates
			$fref_pos  = $feature->end;
			$fchromo   = $feature->seq_id;
			$fstart    = $feature->end - $args{'stop'};
			$fstop     = $feature->end - $args{'start'};
		}
		
		elsif ($args{'position'} == 3 and $fstrand >= 0) {
			# feature is on forward, top, watson strand
			# set segment relative to the 3' end
			
			# record final coordinates
			$fref_pos = $feature->end;
			$fchromo   = $feature->seq_id;
			$fstart    = $feature->end + $args{'start'};
			$fstop     = $feature->end + $args{'stop'};
		}
		
		elsif ($args{'position'} == 3 and $fstrand < 0) {
			# feature is on reverse, bottom, crick strand
			# set segment relative to the 3' end
			
			# record final coordinates
			$fref_pos = $feature->start;
			$fchromo   = $feature->seq_id;
			$fstart    = $feature->start - $args{'stop'};
			$fstop     = $feature->start - $args{'start'};
		}
		
		elsif ($args{'position'} == 4) {
			# feature can be on any strand
			# set segment relative to the feature middle
			
			# record final coordinates
			$fref_pos = $feature->start + int(($feature->length / 2) + 0.5);
			$fchromo   = $feature->seq_id;
			$fstart    = $fref_pos + $args{'start'};
			$fstop     = $fref_pos + $args{'stop'};
		}
	}
	
	# an entire named database feature
	elsif ( $args{'id'} or ( $args{'name'} and $args{'type'} ) ) {
		
		# first define the feature to get endpoints
		confess "database required to use named features" unless $db;
		my $feature = get_db_feature(
			'db'    => $db,
			'id'    => $args{'id'},
			'name'  => $args{'name'},
			'type'  => $args{'type'},
		) or return; 
		$primary = $feature->primary_id;
		
		# determine the strand
		$fstrand   = defined $args{'strand'} ? $args{'strand'} : $feature->strand;
		
		# record the feature reference position and strand
		if ($args{'position'} == 5 and $fstrand >= 0) {
			$fref_pos = $feature->start;
		}
		elsif ($args{'position'} == 3 and $fstrand >= 0) {
			$fref_pos = $feature->end;
		}
		elsif ($args{'position'} == 5 and $fstrand < 0) {
			$fref_pos = $feature->end;
		}
		elsif ($args{'position'} == 3 and $fstrand < 0) {
			$fref_pos = $feature->start;
		}
		elsif ($args{'position'} == 4) {
			# strand doesn't matter here
			$fref_pos = $feature->start + int(($feature->length / 2) + 0.5);
		}
		
		# record final coordinates
		$fchromo   = $feature->seq_id;
		$fstart    = $feature->start;
		$fstop     = $feature->end;
	}
	
	# a genomic region
	elsif ( $args{'chromo'} and defined $args{'start'} and defined $args{'stop'} ) {
		# coordinates are easy
		
		$fchromo   = $args{'chromo'};
		if ($args{'extend'}) {
			# user wants to extend
			$fstart    = $args{'start'} - $args{'extend'};
			$fstop     = $args{'stop'}  + $args{'extend'};
		}
		else {
			$fstart    = $args{'start'};
			$fstop     = $args{'stop'};
		}
		$fstart = 1 if $fstart <= 0;
		
		# determine the strand
		$fstrand   = defined $args{'strand'} ? $args{'strand'} : 0; # default is no strand
		
		# record the feature reference position and strand
		if ($args{'position'} == 5 and $fstrand >= 0) {
			$fref_pos = $args{'start'};
		}
		elsif ($args{'position'} == 3 and $fstrand >= 0) {
			$fref_pos = $args{'stop'};
		}
		elsif ($args{'position'} == 5 and $fstrand < 0) {
			$fref_pos = $args{'stop'};
		}
		elsif ($args{'position'} == 3 and $fstrand < 0) {
			$fref_pos = $args{'start'};
		}
		elsif ($args{'position'} == 4) {
			# strand doesn't matter here
			$fref_pos = $args{'start'} + 
				int( ( ($args{'stop'} - $args{'start'} + 1) / 2) + 0.5);
		}
	}
	
	# or else something is wrong
	else {
		confess " programming error! not enough information provided to" .
			" identify database feature!\n";
	}
	
	# sanity check for $fstart
	$fstart = 1 if $fstart < 1;
	
	### Data collection
	my @params;
	$params[CHR]   = $fchromo;
	$params[STRT]  = $fstart;
	$params[STOP]  = $fstop;
	$params[STR]   = $fstrand;
	$params[STND]  = $args{'stranded'};
	$params[RETT]  = 2; # indexed method
	$params[DB]    = $ddb;
	$params[DATA]  = $args{'dataset'};
	my $datahash = get_segment_score(@params);
	
	### Check for conflicting features
	if (defined $args{'avoid'}) {
		# we need to look for any potential overlapping features of the 
		# provided type and remove those scores
		
		# get the overlapping features of the same type
		my @overlap_features = $db->features(
			-seq_id  => $fchromo,
			-start   => $fstart,
			-end     => $fstop,
			-type    => $args{'avoid'},
		);
		if (@overlap_features) {
			# there are one or more feature of the type in this region
			# one of them is likely the one we're working with
			# but not necessarily - user may be looking outside original feature
			# the others are not what we want and therefore need to be 
			# avoided
			foreach my $feat (@overlap_features) {
				# skip the one we want
				next if ($feat->primary_id eq $primary);
				# now eliminate those scores which overlap this feature
				my $start = $feat->start;
				my $stop  = $feat->end;
				foreach my $position (keys %$datahash) {
					# delete the scored position if it overlaps with 
					# the offending feature
					if (
						$position >= $start and
						$position <= $stop
					) {
						delete $datahash->{$position};
					}
				}
			}
		}
		
	}
	
	
	
	### Convert the coordinates to relative positions
		# previous versions of this function that used Bio::DB::GFF returned 
		# the coordinates as relative positions, e.g. -200..200
		# to maintain this compatibility we will convert the coordinates to 
		# relative positions
		# most downstream applications of this function expect this, and it's
		# a little easier to work with. Just a little bit, though....
	if ($args{'absolute'}) {
		# do not convert to relative positions
		return %$datahash;
	}
	else {
		my %relative_datahash;
		if ($fstrand >= 0) {
			# forward strand
			foreach my $position (keys %$datahash) {
				# relative position is real position - reference
				$relative_datahash{ $position - $fref_pos } = $datahash->{$position};
			}
		}
		elsif ($fstrand < 0) {
			# reverse strand
			foreach my $position (keys %$datahash) {
				# the relative position is -(real position - reference)
				$relative_datahash{ $fref_pos - $position } = $datahash->{$position};
			}
		}
		
		# return the collected dataset hash
		return %relative_datahash;
	}
}


__END__

=head1 AUTHOR

 Timothy J. Parnell, PhD
 Dept of Oncological Sciences
 Huntsman Cancer Institute
 University of Utah
 Salt Lake City, UT, 84112

This package is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.  

