package Bio::ToolBox::legacy_helper;
our $VERSION = '1.60';

=head1 NAME

Bio::ToolBox::legacy_helper - exported methods to support legacy API

=head1 DESCRIPTION

These are legacy functions that used to be provided by Bio::ToolBox::data_helper, 
Bio::ToolBox::file_helper, and even L<Bio::ToolBox::db_helper>, but have now been 
superseded by the object oriented API of L<Bio::ToolBox::Data>, replaced with 
updated functions with new names, or just plain abandoned. 

=head1 USAGE

B<NOTE:> All new scripts should use the L<Bio::ToolBox::Data> API and B<NOT> these methods. 
These are for supporting old legacy scripts, primarily included in this package, 
that I am too lazy to rewrite, but crazy enough to provide these old legacy wrap-around 
functions just so that they may kind of still work. Don't be surprised if something breaks. 
I won't. I'm just amazed they still work at all.

Call the module at the beginning of your perl script and pass a list of the 
desired modules to import. None are imported by default.
  
  use Bio::ToolBox::Legacy qw(load_data_file convert_genome_data_2_gff_data);
  
The following descriptions are lifted over from previous version PODs and are here 
as reference only. The documentation and API should be mostly stable, but the 
documentation may not be from I<exactly> the version that the code was lifted. 
(It was done separately, in piece meal. Sorry.)

=over

=item generate_data_structure()

As the name implies, this generates a new empty data structure as described 
above. Populating the data table and metadata is the responsibility of the 
end user.

Pass the module an array. The first element should be the name of the features 
in the data table. This is an arbitrary, but required, value. The remainder 
of the array should be the name(s) of the columns (datasets). A rudimentary 
metadata hash for each dataset is generated (consisting only of name and 
index). The name is also entered into the first row of the data table (row 0, 
the header row).

It will return the reference to the data structure.

Example
	
	my $main_data = generate_data_structure(qw(
		genomic_intevals
		Chromo
		Start
		Stop
	));

=item verify_data_structure()

This subroutine verifies the data structure. It checks items such as the
presence of the data table array, the number of columns in the data table
and metadata, the metadata index of the last row, the presence of basic
metadata, and verification of dataset names for each column. For data 
structures with the GFF or BED tags set to true, it will verify the 
format, including column number and column names; if a check fails, it 
will reset the GFF or BED key to false. It will automatically correct 
some simple errors, and complain about others.

Pass the data structure reference. It will return 1 if successfully 
verified, or false if not.

=item find_column_index()

This subroutine helps to find the index number of a dataset or column given 
only the name. This is useful if the file contents are not in a standard 
order, for example a typical data text file instead of a GFF or BED file.

Pass the subroutine two arguments: 1) The reference to the data structure, and 
2) a scalar text string that represents the name. The string will be used in 
regular expression pattern, so Perl REGEX notation may be used. The search 
is performed with the case insensitive flag. The index position of the first 
match is returned.

Example

	my $main_data = load_data_file($filename);
	my $chromo_index = find_column_index($main_data, "^chr|seq");
	

=item load_data_file()

This is a newer, updated file loader and parser for BioToolBox data files. It will
completely parse and load the file contents into the described data structure 
in memory. Files with metadata lines (described in BioToolBox data format) will 
have the metadata lines loaded. Files without metadata lines will have basic 
metadata (column name and index) automatically generated. The first 
non-header line should contain the column (dataset) name. Recognized file 
formats without headers, including GFF, BED, and SGR, will have the columns 
automatically named.

This subroutine uses the open_data_file() subroutine and completes the 
loading of the file into memory.

BED and BedGraph style files, recognized by .bed or .bdg file extensions, 
have their start coordinate adjusted by +1 to convert from 0-based interbase 
numbering system to 1-based numbering format, the convention used by BioPerl. 
A metadata attribute is applied informing the user of the change. When writing 
a valid Bed or BedGraph file, converted start positions are changed back to 
interbase format.

Strand information is parsed from recognizable symbols, including "+, -, 1, 
-1, f, r, w, c, 0, .",  to the BioPerl convention of 1, 0, and -1. Valid 
BED and GFF files are changed back when writing these files. 

Pass the module the filename. The file may be compressed with gzip, recognized
by the .gz extension.

The subroutine will return a scalar reference to the hash, described above. 
Failure to read or parse the file will return an empty value.

Example:
	
	my $filename = 'my_data.txt.gz';
	my $data_ref = load_data_file($filename);
	
=item open_data_file()

This is a file opener and metadata parser for data files, including BioToolBox 
data formatted files and other recognized data formats (gff, bed, sgr). It 
will open the file, parse the metadata, and return an open file handle 
ready for reading. It will NOT load the entire file contents into memory. 
This is to allow for processing those gigantic data files that will break 
Perl with malloc errors. 

The subroutine will open the file, parse the header lines (marked with
a # prefix) into a metadata hash as described above, parse the data column 
names (the first row in the table), set the file pointer to the first row of
data in the table, and return the open file handle along with a scalar 
reference to the metadata hash. The calling program may then process the file 
through the filehandle line by line as appropriate.

The data column names may be found in an array in the data hash under the 
key 'column_names';

Pass the module the filename. The file may be compressed with gzip, recognized
by the .gz extension.

The subroutine will return two items: a scalar reference to the file handle,
and a scalar reference to the data hash, described as above. The file handle
is an L<IO::Handle> object and may be manipulated as such.
Failure to read or parse the file will return an empty value.

Example:
	
	my $filename = 'my_data.txt.gz';
	my ($fh, $metadata_ref) = open_data_file($filename);
	while (my $line = $fh->getline) {
		...
	}
	$fh->close;



=item write_data_file()

This subroutine will write out a data file formatted for BioToolBox data files. 
Please refer to L<FORMAT OF BIOTOOLBOX DATA TEXT FILE> for more 
information regarding the file format. If the 'gff' key is true in the data 
hash, then a gff file will be written.

The subroutine is passed a reference to an anonymous hash containing the 
arguments. The keys include

  Required:
  data     => A scalar reference to the data structure ad described
              in L<Bio::ToolBox::data_helper>. 
  Optional: 
  filename => A scalar value containing the name of the file to 
              write. This value is required for new data files and 
              optional for overwriting existing files (the filename 
              stored in the metadata is used). Appropriate extensions 
              are added (e.g, .txt, .gz, etc) as neccessary. 
  format   => A string to indicate the file format to be written.
              Acceptable values include 'text', and 'simple'.
              Text files are text in nature, include all metadata, and
              usually have '.txt' extensions. Simple files are
              tab-delimited text files without metadata, useful for
              exporting data. If the format is not specified, the
              extension of the passed filename will be used as a
              guide. The default behavior is to write standard text
              files.
  gz       => A boolean value (1 or 0) indicating whether the file 
              should be written through a gzip filter to compress. If 
              this value is undefined, then the file name is checked 
              for the presence of the '.gz' extension and the value 
              set appropriately. Default is false.
  simple   => A boolean value (1 or 0) indicating whether a simple 
              tab-delimited text data file should be written. This is 
              an old alias for setting 'format' to 'simple'.

The subroutine will return true if the write was successful, otherwise it will
return undef. The true value is the name of the file written, including any 
changes to the extension if necessary. 

Note that by explicitly providing the filename extension, some of these 
options may be set without providing the arguments to the subroutine. 
The arguments always take precendence over the filename extensions, however.

Example

	my $filename = 'my_data.txt.gz';
	my $data_ref = load_data_file($filename);
	...
	my $success_write = write_data_file(
		'data'     => $data_ref,
		'filename' => $filename,
		'format'   => 'simple',
	);
	if ($success_write) {
		print "wrote $success_write!";
	}


=item open_to_read_fh()

This subroutine will open a file for reading. If the passed filename has
a '.gz' extension, it will appropriately open the file through a gunzip 
filter.

Pass the subroutine the filename. It will return a scalar reference to the
open filehandle. The filehandle is an IO::Handle object and may be manipulated
as such.

Example
	
	my $filename = 'my_data.txt.gz';
	my $fh = open_to_read_fh($filename);
	while (my $line = $fh->getline) {
		# do something
	}
	$fh->close;
	

=item open_to_write_fh()

This subroutine will open a file for writing. If the passed filename has
a '.gz' extension, it will appropriately open the file through a gzip 
filter.

Pass the subroutine three values: the filename, a boolean value indicating
whether the file should be compressed with gzip, and a boolean value 
indicating that the file should be appended. The gzip and append values are
optional. The compression status may be determined automatically by the 
presence or absence of the passed filename extension; the default is no 
compression. The default is also to write a new file and not to append.

If gzip compression is requested, but the filename does not have a '.gz' 
extension, it will be automatically added. However, the change in file name 
is not passed back to the originating program; beware!

The subroutine will return a scalar reference to the open filehandle. The 
filehandle is an IO::Handle object and may be manipulated as such.

Example
	
	my $filename = 'my_data.txt.gz';
	my $gz = 1; # compress output file with gzip
	my $fh = open_to_write_fh($filename, $gz);
	# write to new compressed file
	$fh->print("something interesting\n");
	$fh->close;
	

=item write_summary_data()

This subroutine will summarize the data in a data file, generating mean values
for all the values in each dataset (column), and writing an output file with
the summarized data. This is useful for data collected in windows across a 
feature, for example, microarray data values across the body of genes, and 
then generating a composite or average gene occupancy.

The output file is a BioToolBox data tab-delimited file as described above with three
columns: The Name of the window, the Midpoint of the window (calculated as the
mean of the start and stop points for the window), and the mean value. The 
table is essentially rotated 90º from the original table; the averages of each
column dataset becomes rows of data.

Pass the subroutine an anonymous hash of arguments. These include:

  Required:
  data        => A scalar reference to the data hash. The data hash 
                 should be as described in this module.
  filename    => The base filename for the file. This will be 
                 appended with '_summed' to differentiate from the 
                 original data file. This may be automatically  
                 obtained from the metadata of an opened file if 
                 not specified, otherwise it will not work.
  Optional: 
  startcolumn => The index of the beginning dataset containing the 
                 data to summarized. This may be automatically 
                 calculated by taking the leftmost column without
                 a known feature-description name (using examples 
                 from Bio::ToolBox::db_helper).
  stopcolumn  => The index of the last dataset containing the 
                 data to summarized. This may be automatically 
                 calculated by taking the rightmost column. 
  dataset     => The name of the original dataset used in 
                 collecting the data. It may be obtained from the 
                 metadata for the startcolumn.
  log         => The data is in log2 space. It may be obtained 
                 from the metadata for the startcolumn.

Example

	my $main_data_ref = load_data_file($filename);
	...
	my $summary_success = write_summary_data(
		'data'         => $main_data_ref,
		'filename'     => $outfile,
		'startcolumn'  => 4,
	);


=item check_file

This subroutine confirms the existance of a passed filename. If not 
immediately found, it will attempt to append common file extensions 
and verifiy its existence. This allows the user to pass only the base 
file name and not worry about missing the extension. This may be useful 
in shell scripts.

=item get_feature

This subroutine will retrieve a specific feature from a Bio::DB::SeqFeature::Store 
database for subsequent analysis, manipulation, and/or score retrieval using the 
get_chromo_region_score() or get_region_dataset_hash() methods. It relies upon 
unique information to pull out a single, unique feature.

Several attributes may be used to pull out the feature, including the feature's 
unique database primary ID, name and/or aliases, and GFF type (primary_tag and/or 
source). The get_new_feature_list() subroutine will generate a list of features 
with their unique identifiers. 

The primary_id attribute is preferentially used as it provides the best 
performance. However, it is not portable between databases or even re-loading. 
In that case, the display_name and type are used to identify potential features. 
Note that the display_name may not be unique in the database. In this case, the 
addition of aliases may help. If all else fails, a new feature list should be 
generated. 

To get a feature, pass an array of arguments.
The keys include

  Required:
  db       => The name of the Bio::DB::SeqFeature::Store database or 
              a reference to an established database object. 
  id       => Provide the primary_id tag. In the 
              Bio::DB::SeqFeature::Store database schema this is a 
              (usually) non-portable, unique identifier specific to a 
              database. It provides the fastest lookup.
  name     => A scalar value representing the feature display_name. 
              Aliases may be appended with semicolon delimiters. 
  type     => Provide the feature type, which is typically expressed 
              as primary_tag:source. Alternatively, provide just the 
              primary_tag only.

While it is possible to identify features with any two attributes 
(or possibly just name or ID), the best performance is obtained with 
all three together.

The first SeqFeature object is returned if found.

=item get_chromo_region_score 

This subroutine will retrieve a dataset value for a single specified 
region in the genome. The region is specified with chromosomal coordinates:
chromosome name, start, and stop. It will collect all dataset values within the
window, combine them with the specified method, and return the single value.

The subroutine is passed an array containing the arguments. 
The keys include

  Required:
  db       => The name of the database or a reference to an 
              established database object. Optional if an 
              indexed dataset file (Bam, BigWig, etc.) is provided.
  dataset  => The name of the dataset in the database to be 
              collected. The name should correspond to a feature 
              type in the database, either as type or type:source. 
              The name should be verified using the 
              subroutine verify_or_request_feature_types() prior to passing.
              Multiple datasets may be given, joined by '&', with no
              spaces. Alternatively, specify a data file name. 
              A local file should be prefixed with 'file:', while 
              a remote file should be prefixed with the transfer 
              protocol (ftp: or http:).
  method   => The method used to combine the dataset values found
              in the defined region. Acceptable values include 
              sum, mean, median, range, stddev, min, max, rpm, 
              rpkm, and scores. See _get_segment_score() 
              documentation for more info.
  chromo   => The name of the chromosome (reference sequence)
  start    => The start position of the region on the chromosome
  stop     => The stop position of the region on the chromosome
  end      => Alias for stop
  
  Optional:
  strand   => The strand of the region (-1, 0, or 1) on the 
              chromosome. The default is 0, or unstranded.
  value    => Specify the type of value to collect. Acceptable 
              values include score, count, or length. The default 
              value type is score. 
  log      => Boolean value (1 or 0) indicating whether the dataset 
              values are in log2 space or not. If undefined, the 
              dataset name will be checked for the presence of the 
              phrase 'log2' and set accordingly. This argument is
              critical for accurately mathematically combining 
              dataset values in the region.
  stranded => Indicate whether the dataset values from a specific 
              strand relative to the feature should be collected. 
              Acceptable values include sense, antisense, or all.
              Default is 'all'.
  rpm_sum  => When collecting rpm or rpkm values, the total number  
              of alignments may be provided here. Especially 
              useful when collecting via parallel forked processes, 
              otherwise each fork will sum the number of alignments 
              independently, an expensive proposition. 
         	  
The subroutine will return the region score if successful.

Examples

	my $db = open_db_connection('cerevisiae');
	my $score = get_chromo_region_score(
		'db'      => $db,
		'method'  => 'mean',
		'dataset' => $dataset,
		'chr'     => $chromo,
		'start'   => $startposition,
		'stop'    => $stopposition,
		'log'     => 1,
	);
	

=item get_region_dataset_hash 

This subroutine will retrieve dataset values or feature attributes from
features located within a defined region and return them as a hash.
The (start) positions will be the hash keys, and the corresponding dataset 
values or attributes will be the hash values. The region is defined based on 
a genomic feature in the database. The region corresponding to the entire 
feature is selected by default. Alternatively, it may be adjusted by passing 
appropriate arguments.

Different dataset values may be collected. The default is to collect 
score values of the dataset features found within the region (e.g. 
microarray values). Alternatively, a count of found dataset features
may be returned, or the lengths of the found dataset features. When
lengths are used, the midpoint position of the feature is used in the
returned hash rather than the start position.

The returned hash is keyed by relative coordinates and their scores. For 
example, requesting a region from -200 to +200 of a feature (using the 
start and stop options, below) will return a hash whose keys are relative 
to the feature start position, i.e. the keys will >= -200 and <= 200. 
Absolute coordinates relative to the reference sequence or chromosome 
may be optionally returned instead.

The subroutine is passed an array containing the arguments. 
The keys include

  Required:
  db       => The name of the annotation database or a reference to 
              an established database object. 
  dataset  => The name of the dataset in the database to be 
              collected. The name should correspond to a feature 
              type in the database, either as type or type:source. 
              The name should be verified using the 
              subroutine verify_or_request_feature_types() prior to passing.
              Multiple datasets may be given, joined by '&', with no
              spaces. Alternatively, specify a data file name. 
              A local file should be prefixed with 'file:', while 
              a remote file should be prefixed with the transfer 
              protocol (ftp: or http:).
  Required for database features:
  id       => The Primary ID of the genomic feature. This is 
              database specific and may be used alone to identify 
              a genomic feature, or in conjunction with name and type.
  name     => The name of the genomic feature. Required if the Primary 
              ID is not provided. 
  type     => The type of the genomic feature. Required if the Primary 
              ID is not provided. 
  Required for coordinate positions:
  chromo   => The chromosome or sequence name (seq_id). This may be 
              used instead of name and type to specify a genomic 
              segment. This must be used with start and stop options, 
              and optionally strand options.
  Optional:
  start    => Indicate an integer value representing the start  
              position of the region relative to the feature start.
              Use a negative value to begin upstream of the feature.
              Must be combined with "stop".
  stop|end => Indicate an integer value representing the stop  
              position of the region relative to the feature start.
              Use a negative value to begin upstream of the feature.
              Must be combined with "start".
  ddb      => The name of the data-specific database or a reference 
              to an established database. Use when the data and 
              annotation are in separate databases.
  extend   => Indicate an integer value representing the number of 
              bp the feature's region should be extended on both
              sides.
  position => Indicate the relative position of the feature from 
              which the "start" and "stop" positions are calculated.
              Three values are accepted: "5", which denotes the 
              5' end of the feature, "3" which denotes the 
              3' end of the feature, or "4" which denotes the 
              middle of the feature. This option is only used in 
              conjunction with "start" and "stop" options. The 
              default value is "5".
  strand   => For those features or regions that are NOT 
              inherently stranded (strand 0), artificially set the 
              strand. Three values are accepted: -1, 0, 1. This 
              will overwrite any pre-existing value (it will not, 
              however, migrate back to the database).
  stranded => Indicate whether the dataset values from a specific 
              strand relative to the feature should be collected. 
              Acceptable values include sense, antisense, or all.
              Default is all.
  value    => Indicate which attribute will be returned. Acceptable 
              values include "score", "count", or "length". The  
              default behavior will be to return the score values.
  avoid    => Provide an array reference of database feature types 
              that should be avoided. Any positioned scores which 
              overlap the other feature(s) are not returned. The 
              default is to return all values. A boolean value of 
              1 can also be passed, in which case the same type 
              of feature as the search feature will be used. This
              was the original implementation (v1.35 and below). 
  absolute => Boolean value to indicate that absolute coordinates 
              should be returned, instead of transforming to 
              relative coordinates, which is the default.
          	  
The subroutine will return the hash if successful.

Example

	my $db = open_db_connection('cerevisiae');
	my %region_scores = get_region_dataset_hash(
		'db'      => $db,
		'dataset' => $dataset,
		'name'    => $name,
		'type'    => $type,
	);
	

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

=head1 FORMAT OF BIOTOOLBOX DATA TEXT FILE

The BioToolBox data file format is not indicated by a special file extension. 
Rather, a generic '.txt' extension is used to preserve functionality with
other text processing programs. The file is essentially a simple tab 
delimited text file representing rows (lines) and columns (demarcated by the
tabs). 

What makes it unique are the metadata header lines, each prefixed by a '# '.
These metadata lines describe the data within the table with regards to its
type, source, methodology, history, and processing. The metadata is designed
to be read by both human and computer. Opening files without this metadata 
will result in basic default metadata assigned to each column. Special files
recognized by their extension (e.g. GFF or BED) will have appropriate 
metadata assigned.

The specific metadata lines that are specifically recognized are listed below.

=over 4

=item Feature

The Feature describes the types of features represented on each row in the 
data table. These can include gene, transcript, genome, etc.

=item Database

The name of the database used in generation of the feature table. This 
is often also the database used in collecting the data, unless the dataset
metadata specifies otherwise.

=item Program

The name of the program generating the data table and file. It usually 
includes the whole path of the executable.

=item Column

The next header lines include column specific metadata. Each column 
will have a separate header line, specified initially by the word 
'Column', followed by an underscore and the column number (0-based). 
Following this is a series of 'key=value' pairs separated by ';'. 
Spaces are generally not allowed. Obviously '=' or ';' are not 
allowed or they will interfere with the parsing. The metadata 
describes how and where the data was collected. Additionally, any 
modifications performed on the data are also recorded here. The only 
key that is required is 'name'. 
If the file being read does not contain metadata, then it will be auto 
generated with basic metadata.

=back

A list of standard column header keys is below, but is not exhaustive. 

=over

=item name

The name of the column. This should be identical to the table header.

=item database

Included if different from the main database indicated above.

=item window

The size of the window for genome datasets

=item step

The step size of the window for genome datasets

=item dataset

The name of the dataset(s) from which data is collected. Comma delimited.

=item start

The starting point for the feature in collecting values

=item stop

The stopping point of the feature in collecting values

=item extend

The extension of the region in collecting values

=item strand

The strandedness of the data collecte. Values include 'sense',
'antisense', or 'none'

=item method

The method of collecting values

=item log2

boolean indicating the values are in log2 space or not

=back

Finally, the data table follows the metadata. The table consists of 
tab-delimited data. The same number of fields should be present in each 
row. Each row represents a genomic feature or landmark, and each column 
contains either identifying information or a collected dataset. 
The first row will always contain the column names, except in special
cases such as the GFF format where the columns are strictly defined.
The column name should be the same as defined in the column's metadata.
When loading GFF files, the header names and metadata are automatically
generated for conveniance. 

=head1 DATA STRUCTURE

The data structure is a complex data structure that is commonly used 
throughout the biotoolbox scripts, thus simplifying data input/output and 
manipulation. The primary structure is a hash with numerous keys. The actual 
data table is represented as an array of arrays.  Metadata for the columns 
(datasets) are stored as hashes. 

The description of the primary keys in the data structure are described 
here.

=over 4

=item program

This includes the scalar value from the Program header
line and represents the name of the program that generated the
data file.

=item db

This includes the scalar value from the Database header
line and is the name of the database from which the file data
was generated.

=item feature

This includes the scalar value from the Feature header
line and describes the type of features in the data file.

=item gff

This includes a scalar value of the source GFF file version, obtained 
from either the GFF file pragma or the file extension. 
The default value is 0 (not a GFF file). As such, it may be treated 
as a boolean value.

=item bed

If the source file is a BED file, then this tag value is set to the 
number of columns in the original BED file, an integer of 3 to 12. 
The default value is 0 (not a BED file). As such, it may be treated 
as a boolean value.

=item number_columns

This includes an integer representing the total 
number of columns in the data table. It is automatically calculated
from the data table and updated each time a column is added.

=item last_row

This represents the integer for the index number (0-based) of the last
row in the data table. It is calculated automatically from the data 
table.

=item other

This key points to an anonymous array of additional, unrecognized 
header lines in the parsed file. For example, metadata from older 
file formats or general comments not suitable for other locations. 
The entire line is added to the array, and is rewritten before the 
column metadata is written. The line ending character is automatically 
stripped when it is added to this array upon file loading, and 
automatically added when writing out to a text file.

=item filename

The original path and filename of the file opened and parsed. (Just in 
case you forgot ;) Joking aside, missing extensions may have been added 
to the filename by the different functions upon opening (a convenience for 
users) in the case that they weren't initially provided. The actual 
complete name will be found here.

=item basename

The base name of the original file name, minus the extension(s). 
Useful when needing to assign a new file name based on the current 
file name.

=item extension

The known extension(s) of the original file name. Known extensions 
currently include '.txt, .gff, .gff3, .bed, .sgr' as well as 
their gzip equivalents.

=item path

The parent directories of the original file. The full filename can be 
regenerated by concatenating the path, basename, and extension.

=item headers

A boolean flag (1 or 0) to indicate whether headers are present or not. 
Some file formats, e.g. BED, GFF, etc., do not explicitly have column 
headers; the headers flag should be set to false in this case. Standard 
data formatted text files should be set to true.

=item <column_index_number>

Each column will have a metadata index. Usually this is read from 
the column's metadata line. The key will be the index number (0-based) 
of the column. The value will be an anonymous hash consisting of 
the column metadata. For metadata header lines from a parsed file, these
will be the key=value pairs listed in the line. There should always 
be two mandatory keys, 'name' and 'index'. 

=item data_table

This key will point to an anonymous array of arrays, representing the
tab-delimited data table in the file. The primary array 
will be row, representing each feature. The secondary array will be 
the column, representing the descriptive and data elements for each 
feature. Any value can be looked up by 
$data_structure_ref->{'data_table'}->[$row][$column]. The first row
should always contain the column (dataset) names, regardless whether 
the original data file had dataset names (e.g. GFF or BED files).

=back

=cut

use strict;
require Exporter;
use Carp qw(carp cluck croak confess);
use Bio::ToolBox::Data 1.62;
use Bio::ToolBox::db_helper qw(
	open_db_connection
	get_db_feature
	get_segment_score
);
use Bio::ToolBox::db_helper::constants;


our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw(
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
	get_feature
	get_region_dataset_hash
	get_chromo_region_score
	convert_genome_data_2_gff_data 
	convert_and_write_to_gff_file
	index_data_table
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

sub get_feature {
	return get_db_feature(@_);
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

=head1 AUTHOR

 Timothy J. Parnell, PhD
 Dept of Oncological Sciences
 Huntsman Cancer Institute
 University of Utah
 Salt Lake City, UT, 84112

This package is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.  

