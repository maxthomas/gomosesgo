#! /usr/bin/perl

use strict;
use warnings;

############################################################
# extractSentenceFormFromMADAFile.pl
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
##
##  This script reads a .ma or .mada file, and prints out
##  the input sentence form that created the the file.
## 
##  Essentially, this reproduces the <file>.bw file created
##  by the MADA preprocessor (handy if you misplaced it) for
##  this particular .mada file.
##
##  The output of this script will be in Buckwalter encoding.
##
##  Usage:  "cat file.mada | perl extractSentenceFormFromMADAFile.pl > file.bw"
##
############################################################



my $line;
my $out = "";
while( $line = <> ) {

    if( $line =~ /^;;; SENTENCE_ID (\S+)/ ) {
	$out = "$1 ";
    }
    elsif( $line =~ /^;;WORD (\S+)/ ) {
	$out .= "$1 ";
    }
    elsif( $line =~ /^SENTENCE BREAK/ ) {
	$out =~ s/\s$//;
	print "$out\n";
	$out = "";
    }

}


