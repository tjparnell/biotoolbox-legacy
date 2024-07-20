# NAME

Bio::ToolBox::Legacy - Esoteric scripts and functions for BioToolBox

# DESCRIPTION

This is a collections of old, esoteric, specialized, and/or outdated 
scripts and library functions that used to be part of the 
[Bio::ToolBox](https://github.com/tjparnell/biotoolbox) package before being 
expunged from the main distribution. These scripts are kept for 
historical purposes. Some are still useful, some may be useful, and 
others are best left to the dustbins of history. Many are specialized 
scripts for personal research purposes, but could be useful to 
someone, somewhere.

Most of these scripts do not use the modern object-oriented API of 
the current [Bio::ToolBox::Data](https://metacpan.org/pod/Bio::ToolBox::Data) module, 
relying instead on old exported functions from previous versions that are 
now moved into Bio::ToolBox::Legacy. These functions have now been 
superseded by the object oriented API of Bio::ToolBox::Data, replaced with 
updated functions with new names, or just plain abandoned. 

# REQUIREMENTS

These are Perl modules and scripts. They require Perl and a unix-like 
command-line environment. They have been developed and tested on Mac 
OS X and linux; Microsoft Windows compatability is not tested nor 
guaranteed.

These scripts require the installation of 
[Bio::ToolBox](https://github.com/tjparnell/biotoolbox), 
and all the requirements therein. There are advanced installation instructions 
on the BioToolBox page. **NOTE**: This requires Bio::ToolBox version 1.69; it
is incompatible with the latest versions.

# INSTALLATION

Installation is simple with the standard Perl incantation.

    perl ./Build.PL
    ./Build installdeps     # if necessary
    ./Build
    ./Build install

# AUTHOR

	Timothy J. Parnell, PhD
	Huntsman Cancer Institute
	University of Utah
	Salt Lake City, UT, 84112

# LICENSE

This package is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0. For details, see the
full text of the license in the file LICENSE.

This package is distributed in the hope that it will be useful, but it
is provided "as is" and without any express or implied warranties. For
details, see the full text of the license in the file LICENSE.




