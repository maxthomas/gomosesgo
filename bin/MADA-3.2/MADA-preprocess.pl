#! /usr/bin/perl

$| = 1;
use strict;
use warnings;
use MADA::MADATools;

########################################################################
# MADA-preprocess.pl
# Copyright (c) 2009-2012 Columbia University in 
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
########################################################################
#  This script will take a file of UTF8 characters, clean the unicode,
#  tag Latin words, separate Punctuation, and then convert the file to 
#  Buckwalter. It can also be configured to selectively choose which of
#  these steps to take. Output is placed in a new file named <file>.bw
#######################################################################

##################################################################################
##### READ COMMAND LINE  #####

if( scalar( @ARGV ) < 2 ) {
    &printUsage();
    die "$0: Error - Invalid command line \n";
}

my $cmdline = &MADATools::readCommandLine( @ARGV );

if( ! exists $cmdline->{CONFIG} ) {
    &printUsage();
    die "$0: Error - configuration file not specified in command line \n";
}
if( ! exists $cmdline->{FILE} ) {
    &printUsage();
    die "$0: Error - UTF-8 file to process not specified in command line \n";
}

my $quiet = 0;
if( exists $cmdline->{QUIET} ) {
    $quiet = 1;
}

my $inputfile = $cmdline->{FILE};  


my $configfile = $cmdline->{CONFIG};
my %configs = %{ &MADATools::readConfig($configfile) }; 
# Overwrite config file with whatever might have been entered 
#  on the commandline
foreach( keys %{$cmdline} ) {
    $configs{$_} = $cmdline->{$_};
}

if ( ! exists $configs{MADA_HOME} ) {
    die "$0: Error - MADA_HOME installation directory unspecified in configuration file and/or command line.\n";
}
$configs{MADA_HOME} =~ s/\/+$//; # Strip off trailing '/' characters if present
my $home = $configs{MADA_HOME};


my $sentID="no";
if( exists $configs{SENTENCE_IDS} ) {
    $sentID = lc( $configs{SENTENCE_IDS} );
}
if( $sentID !~ /^(yes|no)$/ ) { $sentID = "no"; }
$configs{SENTENCE_IDS} = $sentID;


my $seppunct="no";
if( exists $configs{SEPARATEPUNCT} ) {
    $seppunct = lc( $configs{SEPARATEPUNCT} );
}
if( $seppunct !~ /^(yes|no)$/ ) { $seppunct = "no"; }
$configs{SEPARATEPUNCT} = $seppunct;


my $inputencode="utf8";
if( exists $configs{INPUT_ENCODING} ) {
    $inputencode = lc( $configs{INPUT_ENCODING} );
}
if( $inputencode !~ /^(bw|buckwalter|utf8|utf-8)$/ ) { 
    $inputencode = "utf8";
    &MADATools::report("Input encoding not specified in configuration file or command line.  Assuming UTF-8 Encoding.  This will cause any Buckwalter input to be tagged incorrectly, so double-check the output.", "warn", $quiet);
}
$configs{INPUT_ENCODING} = $inputencode;






##################################################################################
#####  Open Input and Output Files #####

my $outputfile = $inputfile;
$outputfile =~ s/\.gz$//;
$outputfile .= ".bw";



my $inFH = *IN;
$inFH = *IN; # This is to prevent a pointless warning message
if( ! &MADATools::openReadFile( $inFH, $inputfile ) ) {
    die "$0:  Error - Unable to open UTF-8 text file $inputfile\n"; 
}

open (OUT,">","$outputfile") || die "$0: Error - Unable to open output file $outputfile\n";
binmode OUT, ":utf8";
binmode $inFH, ":utf8";


##################################################################################
#####  Read in clean Map #####

my $map;
my $result;

if( $inputencode =~ /^utf-?8/ ) {
    if( ! $quiet ) {
	print STDERR " Reading UTF-8 cleaning map\n";
    }
    $map = "$home/common-tasks/clean-utf8-MAP";
    $result = &MADATools::readUTF8CleanMap($map);

    if( $result != 1 ) {
	die "$0: Error - Unable to read UTF-8 cleaning map file $map\n";
    }
}


##################################################################################
##  Read and clean,tag,convert input file

if( ! $quiet ) {
    print STDERR " Cleaning, tagging, punctuation separating and converting input as necessary\n";
}
my $line;
my $out;
my $linecount = 0;

while( $line = <$inFH> ) {

    chomp $line;
    $linecount++;
    if( ! $quiet ) {
	print STDERR "[" . $linecount/1000000 . "M]" if (($linecount % 50000) == 0);
	print STDERR "\n"       if (($linecount % 500000) == 0);
    }

    $out = $line;

    if( $inputencode =~ /^utf-?8/ ) {
	# Clean
	#print STDERR " Cleaning UTF8...\n";
	($result,$out) =  &MADATools::cleanUTF8String($out);

	if( $result != 1 ) {
	    die "$0: Error - Empty UTF8 cleaning map file discovered.\n";
	}
	
	#print STDERR " Tagging latin characters...\n";
	if( $sentID eq "yes" ) {
	    $out = &MADATools::tagEnglishInString($out,"tag","id");
	}
	else {
	    $out = &MADATools::tagEnglishInString($out,"tag","noid");
	}
    }



    if( $seppunct eq "yes" ) {
	#print STDERR " Separating punctuation and numbers from other text...\n";
	$out = &MADATools::separatePunctuationAndNumbers($out,$inputencode,$sentID);
    }


    if( $inputencode =~ /^utf-?8/ ) {
	#print STDERR " Converting UTF8 to Buckwalter for use in MADA...\n";
	$out = &MADATools::convertUTF8ToBuckwalter($out); 
    }

    print OUT "$out\n";

}


close($inFH);
close(OUT);

if( ! $quiet ) {
    print STDERR " Finished creating processed Buckwalter file $outputfile -- $linecount lines total\n\n";
}

##################################################################################

sub printUsage {

    print "\nUsage: $0 config=<MADA configuration file> file=<UTF8 input file> [quiet] [other variables]\n";
    print "  Output is produced in <file>.bw\n\n";

    print "  If quiet is included on the command line, all informational and warning messages will be\n";
    print "   repressed.\n\n";

    print "  The other variables are optional, and can be any of the following,\n";
    print "  specified in VARIABLE=VALUE format:\n\n";
    print "    MADA_HOME=<directory location of MADA installation>\n";
    print "    INPUT_ENCODING = [UTF8|UTF-8|Buckwalter|BW]\n";
    print "    SEPARATEPUNCT = [YES|NO]\n";
    print "    SENTENCE_IDS=[YES|NO]\n\n";


}






