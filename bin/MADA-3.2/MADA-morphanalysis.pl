#! /usr/bin/perl


use strict;
use warnings;
use MADA::MADATools;
use MADA::MADAWord;
use MADA::ALMOR3;

$| = 1;

#######################################################################
# MADA-morphanalysis.pl
# Copyright (c) 2005-2012 Columbia University in 
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
#######################################################################
# This script prepares input text to be disambiguated. It queries
# an ALMOR generated database to compose, for each input word, a list
# of possible morphological analyses (with full feature sets). This is
# the first step of the MADA proper (after preprocessing).
#
#######################################################################


###############################################################################
##### READ COMMAND LINE  #####

if( scalar( @ARGV ) < 2 ) {
    &printUsage();
    die "$0: Invalid command line \n";
}

my $cmdline = &MADATools::readCommandLine( @ARGV );
if( ! exists $cmdline->{CONFIG} ) {
    &printUsage();
    die "$0: Error - configuration file not specified in command line \n";
}
if( ! exists $cmdline->{FILE} ) {
    &printUsage();
    die "$0: Error - text file to process not specified in command line \n";
}

my $quiet = 0;
if( exists $cmdline->{QUIET} ) {
    $quiet = 1;
}

##################################################################################
#####  READ CONFIGURATION FILE, LOAD VARIABLES #####

my $configfile = $cmdline->{CONFIG};
my $text = $cmdline->{FILE};
my $mafile = $text;
$mafile =~ s/\.gz$//;
$mafile .= ".ma";
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




if ( ! exists $configs{ALMOR_DATABASE} ) {
    die "$0: Error - ALMOR Morphology database unspecified in configuration file and/or command line.\n";
}
$configs{ALMOR_DATABASE} =~ s/\/+$//; # Strip off trailing '/' characters if present
my $ALMOR_DB = "$configs{MADA_HOME}/MADA/$configs{ALMOR_DATABASE}";




my $morphBACKOFF="none"; #other options are "noan-prop", "noan-all", "add-prop" and "add-all"
if( exists $configs{MORPH_BACKOFF} ) {
    $morphBACKOFF = lc( $configs{MORPH_BACKOFF} );
}
if ($morphBACKOFF !~ /^(none|noan-prop|noan-all|add-prop|add-all)$/ ) {
    $morphBACKOFF = "none";
}
$configs{MORPH_BACKOFF} = $morphBACKOFF;



my $sentID="no";
if( exists $configs{SENTENCE_IDS} ) {
    $sentID = lc( $configs{SENTENCE_IDS} );
}
if( $sentID !~ /^(yes|no)$/ ) { $sentID = "no"; }
$configs{SENTENCE_IDS} = $sentID;




#print "SENT_ID = $sentID\n";
#print "SPunct = $separatepunct\n";
#print "SNum = $separatenumbers\n";

##################################################################################
#####  Open Input and Output Files #####

my $inFH = *IN;
$inFH = *IN; # This is to prevent a pointless warning message
if( ! &MADATools::openReadFile( $inFH, $text ) ) {
    die "$0:  Error - Unable to open text file $text\n"; 
}

open (OUT,">$mafile") || die "$0: Error - Unable to open output file $mafile\n";

if ($morphBACKOFF ne "none"){
    print OUT ";; Morphological Backoff Setting = $morphBACKOFF\n";
}


##################################################################################
#####  Process Input File, Write Output  #####



my $ALMOR_DBref = &ALMOR3::initialize($ALMOR_DB, "analysis", $quiet);
if( ! $quiet ) {
    print STDERR "...Done\n\n";
    print STDERR "Analyzing Words in $text...\n";
}

my $wordcount = 0;

while (my $line=<$inFH>) {
    chomp $line;    
    $line = &MADATools::cleanWhitespace($line);

    if ( $line =~ /\S/ && $sentID =~ /^yes$/i ){
	$line=~s/^(\S+)\s*//;
	print OUT ";;; SENTENCE_ID $1\n";

    } elsif( $sentID =~ /^yes$/i ) {
	## If the line is completely blank (no id) but IDs are expected, mark the ID as empty
	print OUT ";;; SENTENCE_ID \n";
    }

    print OUT ";;; SENTENCE $line\n";

    if($line =~ /^\s*$/ ) {
	print OUT ";;; BLANK-LINE\n";
	print OUT "--------------\n";
	print OUT "SENTENCE BREAK\n";
	print OUT "--------------\n";	
	next;
    }
    

    foreach my $word (split('\s+',$line)){
	my @out=();
	my @backoff=();

	## print progress to STDERR
	$wordcount++;
	if( ! $quiet ) {
	    print STDERR "[" . $wordcount/1000000 . "M]" if (($wordcount % 50000) == 0);
	    print STDERR "\n"       if (($wordcount % 500000) == 0);
	}
	print OUT ";;WORD $word\n";
	
	if ( $word =~ /^\@\@/ ) {  ## Skip commented out words
		print OUT ";;PASS $word\n";
	}
	else {

	    #$word = &MADATools::removeDiacritics($word);
	    my @out = @{ &ALMOR3::analyzeSolutions($word,$ALMOR_DBref,$morphBACKOFF) };

	    if( scalar( @out ) == 0 ) {
		print OUT "NO-ANALYSIS [$word]\n";

	    }else{

		#  Print out each analysis
		foreach my $out (@out){
		    print OUT "$out\n";
		}
		
	    }
	}
	print OUT "--------------\n";
    }
    
    
    print OUT "SENTENCE BREAK\n";
    print OUT "--------------\n";
}

if( ! $quiet ) {
    print STDERR "...Done. $wordcount words analyzed.\n";
}
close($inFH);
close(OUT);



##################################################################################

sub printUsage {

    print "\nUsage: $0 config=<.madaconfig file> file=<textfile> [quiet] [other variables]\n\n";
    print "  Output is produced in <textfile>.ma. Both the config file and the text\n";
    print "  file must be specified.\n\n";

    print "  If quiet is included on the command line, all informational and warning messages will be\n";
    print "   repressed.\n\n";

    print "  The other variables are optional, and can be any of the following,\n";
    print "  specified in VARIABLE=VALUE format:\n\n";
    print "    MADA_HOME=<directory location of MADA installation>\n";
    print "    ALMOR_DATABASE=<name of database file located in MADA_HOME/MADA/>\n";
    print "    SENTENCE_IDS=[YES|NO]\n";
    print "    MORPH_BACKOFF=[NONE|NOAN-PROP|ADD-PROP|NOAN-ALL|ADD-ALL]\n\n";
    print "  If any of the above options is specified on the command line, the\n";
    print "  command line value will be used instead of the value indicated in the\n";
    print "  .madaconfig file. All other options will be ignored. For a more\n";
    print "  detailed description of each variable, consult your .madaconfig file.\n\n";
	
}


