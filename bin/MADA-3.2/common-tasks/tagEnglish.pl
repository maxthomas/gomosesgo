#!/usr/bin/perl 

## NOTE:  THE FUNCTIONALITY OF THIS CODE IS ALSO PRESENT IN THE MADATools.pm LIBRARY

#######################################################################
# tagEnglish.pl
# Copyright (c) 2005,2006,2007,2008,2009,2010 Columbia University in 
#               the City of New York
#
# Please do not distribute to anyone else without written permission
# from authors.  If you know someone who can use this software, please 
# direct them to http://www1.ccls.columbia.edu/~cadim/MADA, where they
# may freely obtain the software.  Doing this helps us to understand how
# our software is being used, and to make future improvements tailored to
# the needs of users.
#
# MADA, TOKAN and ALMOR are distributed in the hope that they will be 
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
#
#
# For more information, bug reports, fixes, contact:
#    Nizar Habash, Owen Rambow and Ryan Roth
#    Center for Computational Learning Systems
#    Columbia University
#    New York, NY 10115
#    USA
#    habash@cs.columbia.edu
#    ryanr@ccls.columbia.edu
#
############################################################
#   Tag ASCII words in a document with a "@@LAT@@" prefix.
#   Will affect any word containing A-Z, a-z, and so should
#   also tag things like urls, emails, etc.
#
#   Usage:  cat file | perl tagEnglish > file.tagged
#
#   If the input has a sentence ID as the first word, you
#   can instruct the script to refrain from tagging it,
#   even if it has A-Z characters, like so:
#
#   cat file-with-ids | perl tagEnglish 1 > file-with-ids.tagged
#
#######################################################################

my $sentid = $ARGV[0];  ## If 1, will not tag first element of line (sent id)
my $i;

while (my $line=<STDIN>) {

    chomp $line;

    my @w = split(/\s+/,$line );

    if( $sentid != 1 ) { $sentid = 0; }

    for($i=$sentid;$i<=$#w;$i++) {
	
	if( $w[$i] =~ /[a-zA-Z]/ && $w[$i] !~ /^\@\@/ ) {
	    $w[$i] = '@@LAT@@' . $w[$i];

	}
    }

    $line = join(' ', @w);
    $line =~ s/\s+/ /g;
    $line =~ s/^\s+|\s+$//g;

    print "$line\n";    

}



