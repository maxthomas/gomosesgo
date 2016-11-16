#! /usr/bin/perl

$| = 1;
use strict;
use warnings;
use MADA::MADATools;
use Benchmark;

#######################################################################
# MADA-SVMTOOLS.pl
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
# This is a wrapper script that calls the MADA components in sequence,
# collecting the final, disambiguated output into a *.mada file.
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
    die "$0: Error - text file to process not specified in command line \n";
}

my $quiet = 0;
if( exists $cmdline->{QUIET} ) {
    $quiet = 1;
}

##################################################################################
#####  READ CONFIGURATION FILE, LOAD VARIABLES #####

my $home;
my $configfile = $cmdline->{CONFIG};
my $file = $cmdline->{FILE};
my $mafile = $file;
$mafile =~ s/\.gz$//;
$mafile .= ".ma";

# Read configuration file
my %configs = %{ &MADATools::readConfig($configfile) }; 

# Overwrite config file with whatever might have been 
#   entered on the commandline
foreach( keys %{$cmdline} ) {
    $configs{$_} = $cmdline->{$_};
}

# Get the MADA_HOME directory
if ( ! exists $configs{MADA_HOME} ) {
    die "$0: Error - MADA_HOME installation directory unspecified in configuration file and/or command line.\n";
}
$configs{MADA_HOME} =~ s/\/+$//; # Strip off trailing '/' characters if present
$home = $configs{MADA_HOME};


##################################################################################
#####  GENERATE COMMAND LINE ARGUMENTS FOR EACH SCRIPT  #####

my $args1 = "config=$configfile file=$file";
my $args2 = "config=$configfile file=$mafile";
my ($arg, $var, $val);

foreach $arg ( @ARGV ) { 
    if( $arg !~ /^(config\=|file\=|quiet)/i ) {
	$arg =~ /^([^\=]+\=)(.+)$/;
	$var = $1;
	$val = $2;
	if( $val =~ /\s/ ) { $val = "\"$val\""; } # Add quotes if needed
	$args1 .= " $var" . $val; 
	$args2 .= " $var" . $val; 
    }
}

if( $quiet ) {
    $args1 .= " quiet";
    $args2 .= " quiet";
}



##################################################################################
#####  RUN SCRIPTS  #####

my $starttime = Benchmark->new;
my ($stime, $etime);

my $cmd;
if( ! $quiet ) {
    print STDERR "\nRunning Morphological Analysis...\n";
    $stime = Benchmark->new;
}
$cmd = "perl $home/MADA-morphanalysis.pl $args1";
#print STDERR "   $cmd\n";
system($cmd);
if( ! $quiet ) {
    $etime = Benchmark->new;
    print STDERR "-- Finished Morphological Analysis.  Time: ", timestr(timediff($etime,$stime));
    print STDERR "\n===========\n\n";

    print STDERR "Generating SVMTool files and Ngram file format...\n";
    $stime = Benchmark->new;
}

$cmd = "perl $home/MADA-generate-SVM+ngram-files.pl $args2";
#print STDERR "   $cmd\n";
system($cmd);
if( ! $quiet ) {
    $etime = Benchmark->new;
    print STDERR "-- Finished file generation.  Time: ", timestr(timediff($etime,$stime));
    print STDERR "\n===========\n\n";

    print STDERR "Running SVMTools SVMTagger to classify...\n";
    $stime = Benchmark->new;

}
$cmd = "perl $home/MADA-runSVMTOOLS.pl $args2";
#print STDERR "   $cmd\n";
system($cmd);

if( ! $quiet ) {
    $etime = Benchmark->new;
    print STDERR "-- Finished SVM tagging.  Time: ", timestr(timediff($etime,$stime));
    print STDERR "\n===========\n\n";
}

my $madafile = $mafile . "da";
if( ! $quiet ) {
    print STDERR "Selecting Analysis...\n";
    $stime = Benchmark->new;
}
$cmd = "perl $home/MADA-selectMA.pl $args2 > $madafile";
#print STDERR "   $cmd\n";
system($cmd);
if( ! $quiet ) {
    $etime = Benchmark->new;
    print STDERR "-- Finished Analysis Selection.  Time: ", timestr(timediff($etime,$stime));
    print STDERR "\n===========\n\n";


    $etime = Benchmark->new;

    print STDERR "-- Finished MADA. Total Time: ", timestr(timediff($etime,$starttime));
    print STDERR "\n\n";
}



sub printUsage {

    print "\nUsage: $0 config=<.madaconfig file> file=<text file> [quiet] [other variables]\n\n";
    print "  Final output is placed in file.mada; other files are also produced.\n";
    print "  Both the config file and the text file must be specified.\n\n";

    print "  If quiet is included on the command line, all informational and warning messages will be\n";
    print "   repressed.\n\n";

    print "  The other variables are optional and are passed to the appropriate scripts\n";
    print "  when necessary. They can be any of the following, specified in VARIABLE=VALUE format:\n\n";

    print "  Used in this script:\n";
    print "    PERL_EXECUTABLE=<the location of the perl executable to use for running SVMTools -- please use 5.8.8 (5.10.0 is not supported by SVMTools\n\n";

    print "  Used in MADA-morphananalyis.pl:\n";
    print "    MADA_HOME=<directory location of MADA installation>\n";
    print "    ALMOR_DATABASE=<database file in MADA_HOME/MADA/>\n";
    print "    SENTENCE_IDS=[YES|NO]\n";
    print "    MORPH_BACKOFF=[NONE|NOAN-PROP|ADD-PROP|NOAN-ALL|ADD-ALL]\n\n";

    print "  Used in MADA-generate-SVM+ngrams-files.pl:\n";
    print "    MADA_HOME=<directory location of MADA installation>\n";
    print "    MODEL_DIR=<directory location of the MADA SVM models, relative to MADA_HOME>\n";
    print "    CLASSIFIERS=\"list of classifers, separated by spaces, in quotes\"\n";
    print "    LEXEME_TYPE=[BAMA|NORM]\n";
    print "    LEX_NGRAM_ORDER=[1|2|3|4|5]\n";
    print "    DIAC_NGRAM_ORDER=[1|2|3|4|5]\n";
    print "    SRI_NGRAM_TOOL=<absolute location of SRI's disambig executable>\n";
    print "    REMOVE_TEMP_LEX_NGRAM_FILES=[YES|NO]\n";
    print "    NGRAM_LM_DIRECTORY=<location of the directory containing the ngram language models, relative to MADA_HOME>\n";
    print "    OTHER_FEATURES=\"quoted, space-separated list of other features used in scoring analyses\"\n\n";

    print "  Used in MADA-runSVMTools.pl:\n";
    print "    MADA_HOME=<directory location of MADA installation>\n";
    print "    PERL_EXECUTABLE=<the location of the perl executable to use -- please use 5.8.8 (5.10.0 is not supported by SVMTools\n";
    print "    CLASSIFIERS=\"list of classifers, separated by spaces, in quotes\"\n";
    print "    SVM_TAGGER=<absolute location of the SVMTagger executable>\n";
    print "    REMOVE_BACKLEX_FILES=[YES|NO]\n";
    print "    MODEL_DIR=<directory location of the MADA SVM models, relative to MADA_HOME>\n\n";
    
    print "  Used in MADA-selectMA.pl:\n";
    print "    MADA_HOME=<directory location of MADA installation>\n";
    print "    SVMT_CLASSIFIED=<.svmt.classifed file to use; default is <.ma file>.svmt.classifed>\n";
    print "    NGRAM_FILE=<.ngram file to use; default is <.ma file>.ngram>\n";
    print "    CLASSIFIERS=\"list of classifers, separated by spaces, in quotes\"\n";
    print "    OTHER_FEATURES=\"quoted, space-separated list of other features used in scoring analyses\"\n";
    print "    SORT_COMBINER_OUTPUT=[YES|NO]\n";
    print "    ARBITRARY_TIE_BREAKING=[YES|NO]\n";
    print "    REMOVE_MA_FILE=[YES|NO]\n";
    print "    LEXEME_TYPE=[BAMA|NORM]\n";
    print "    PRINT_ANALYSES=[all|stars|<number>]\n";
    print "    FEATURE_WEIGHT_SET=[NORMAL|ORIGINAL|LEXEME|POS|CUSTOM]\n";
    print "    CUSTOM_FEATURE_WEIGHT_FILE=<file containing weights to use when FEATURE_WEIGHT_SET is set to CUSTOM>\n\n";

    print "  If any of the above options is specified on the command line, the\n";
    print "  command line value will be used instead of the value indicated in the\n";
    print "  .madaconfig file. All other options will be ignored. For a more\n";
    print "  detailed description of each variable, consult your .madaconfig file.\n\n";
	
}
