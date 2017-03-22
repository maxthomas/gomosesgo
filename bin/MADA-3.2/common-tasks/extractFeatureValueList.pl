#! /usr/bin/perl

use strict;
use warnings;
use MADA::MADAWord;
use MADA::MADATools;

############################################################
############################################################
# extractFeatureValueList.pl
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
##  This is an example of using the MADAWord library.
##  It reads scored .mada file, and prints out a list of
##  of number of times each feature value was encountered,
##   for all analyses in the file.
##
##  This can be used to quickly see the prevalence of a
##  particular part-of-speech value (for example) in a 
##  file.
##
##  The output format is:
##
##   <feature1>   <value1>:<value1Count>   <value2>:<value2Count> ...
##   ...
##
##  Run "perl extractFeatureValueList.pl" for usage information.
##
############################################################


my $file = "";

my %features = ( asp => 1, cas => 1, enc0 => 1, 
		 gen => 1, mod => 1, num => 1, per => 1, pos => 1,
		 prc0 => 1, prc1 => 1, prc2 => 1, prc3 => 1, 
		 ##rat => 1, 
		 stt => 1, vox => 1,
    );


foreach( @ARGV ) {
    
    if( /file=(\S+)/ ) { $file = $1; }

}

if( $file eq "" ) {
    &printUsage();
    exit();
}



my $val;

my $word;
my $f;
my %featVals = ();

foreach $f ( keys %features ) {

    my %a = ();
    $featVals{$f} = \%a;

}


my $mword = MADAWord->new();         # Creates an empty MADAWord object
open(FH, '<', $file);
my $wc = 0;

while( $mword->readMADAWord(*FH) ) {

    if( $mword->isSentenceBreak() ) {

    }
    else {
	$wc++;
	print STDERR "[" . $wc/1000000 . "M]" if (($wc % 50000) == 0);
	print STDERR "\n"       if (($wc % 500000) == 0);


	foreach $f ( keys %features ) {
	    
	    my @vals = @{ $mword->getFeatureArray($f) };
	    
	    
	    foreach $val ( @vals ) {
		$featVals{$f}->{$val} += 1;
	    }


	}


    }



}
close(FH);

print STDERR "\n\n";
foreach $f ( sort keys %featVals ) {
    
    print "$f";
    foreach $val ( sort keys %{ $featVals{$f} } ) {
	print "\t$val\:$featVals{$f}->{$val}";
    }

    print "\n";

}



sub printUsage {

    print "perl $0  file=<.ma or .mada file> \n\n";


}

