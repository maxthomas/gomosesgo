#! /usr/bin/perl

$| = 1;
use strict;
use warnings;
use MADA::MADATools;
use MADA::MADAWord;
use MADA::ALMOR3;
use MADA::TOKAN;
use FileHandle;
 

#######################################################################
# TOKAN.pl -- General tokenizer updated to work with ALMOR3
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
#
# This script, given a TOKAN_SCHEME configuration and a *.mada file,
# produces one or more output files, each containing a specified 
# tokenization of the input.  Multiple tokenizations can be generated
# through use of the TOKAN_SCHEME_FILE configuration variable and
# and additional TOKAN.schemes file.
#
#######################################################################

################################################################################
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
    die "$0: Error - MADA output file to process not specified in command line \n";
}

my $madafile = $cmdline->{FILE};

my $quiet = 0;
if( exists $cmdline->{QUIET} ) {
    $quiet = 1;
}

##################################################################################
#####  READ CONFIGURATION FILE, LOAD VARIABLES #####


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


if ( ! exists $configs{ALMOR_DATABASE} ) {
    die "$0: Error - ALMOR Morphology database unspecified in configuration file and/or command line.\n";
}
$configs{ALMOR_DATABASE} =~ s/\/+$//; # Strip off trailing '/' characters if present
my $ALMOR_DB = "$configs{MADA_HOME}/MADA/$configs{ALMOR_DATABASE}";


my $sentID=0;
if( exists $configs{SENTENCE_IDS} ) {
    $sentID = lc( $configs{SENTENCE_IDS} );
    if( $sentID =~ /^yes$/ ) { $sentID = 1; }
    else { $sentID = 0; }
}
$configs{SENTENCE_IDS} = $sentID;



my @scheme= (""); 
if( exists $configs{TOKAN_SCHEME} ) {
    $scheme[0] = $configs{TOKAN_SCHEME};
    if( $sentID && $scheme[0] !~ /SENT_ID/) {
	$scheme[0] .= " SENT_ID";
    }
}
$configs{TOKAN_SCHEME} = $scheme[0];


my @extension = ("tok"); 
if( exists $configs{TOKAN_OUTPUT_EXTENSION} ) {
    $extension[0] = $configs{TOKAN_OUTPUT_EXTENSION};
}
$configs{TOKAN_OUTPUT_EXTENSION} = $extension[0];


my $tokanschemesfile = "none";
if( exists $configs{TOKAN_SCHEMES_FILE} ) {
    $tokanschemesfile = $configs{TOKAN_SCHEMES_FILE};
}
$tokanschemesfile =~ s/\/+$//;
if( $tokanschemesfile !~ /none/i && ! -e $tokanschemesfile ) {
    &MADATools::report("Specified TOKAN_SCHEME_FILE in configuration file or command line does not exist; defaulting to \"NONE\".","warn",$quiet);
    $tokanschemesfile = "none";
}


#######################################################################
# READ TOKAN SCHEME FILE IF REQUIRED
#######################################################################

my $ext;
my $sch;

if( $tokanschemesfile !~ /none/i ) {

    my $tokFH = *MY_TOKAN_TOKFILE;
    $tokFH = *MY_TOKAN_TOKFILE;
    if( ! &MADATools::openReadFile( $tokFH, $tokanschemesfile ) ) {
	&MADATools::report("Unable to open TOKAN_SCHEMES_FILE; defaulting to single scheme operation.",
			   "warn",$quiet);
    }
    else {
	@extension = ();
	@scheme = ();
	my %exts = ();
	my $line;
	while( $line = <$tokFH> ) {
	    chomp $line;
	    if( $line !~ /\S/ ) { next;  }  #Skip blank lines
	    if( $line =~ /^\s*\#/ ) { next; } #Skip comment lines

	    $line =~ /^(\S+)\s+(.+)/;
	    $ext = $1;
	    $sch = $2;

	    if( ! defined $ext ) { next; }
	    if( ! defined $sch ) { $sch = ""; }
	    
	    if( $sentID  && $sch !~ /SENT_ID/ ) {
		$sch .= " SENT_ID";
	    }

	    if( ! exists $exts{$ext} ) {  ## Make sure extensions in file are unique
		push @extension, $ext;
		push @scheme, $sch;
		$exts{$ext} = 1;
	    }
	    else {
		&MADATools::report("Extension $ext used more than once in TOKAN_SCHEMES_FILE; using only the first such line in the file.","warn",$quiet);
	    }

	}
	
	close($tokFH);
    }

}


#######################################################################
# INITIALIZE AND PARSE TOKAN_SCHEME
#######################################################################

my @PARAM=();
my $ALMOR3DB;

#  load up POS tag conversion in memory;  initializes the TOKAN::POSTAGS()
#   in the TOKAN.pm module, where it is only used by TOKAN.pm subroutine

&TOKAN::initialize_POSTAGS();


#Load parse tokenization definitions 
my $loadalmor = 0;
if( ! $quiet ) {
    print STDERR "Parsing TOKAN scheme(s)...\n";
}
foreach $sch ( @scheme ) {
     
    push @PARAM, &TOKAN::parse_scheme( $sch, $quiet);
    if( ! $loadalmor ) {
	if( $PARAM[-1]->{"load-almor"} ) {
	    $loadalmor = 1;
	}
    }

    #%PARAM = %{ &TOKAN::parse_scheme($scheme) };
}

#
#  Below prints out elements resulting from above parsing for debugging purposes
#
#foreach my $param (sort keys %{$PARAM[0]}) {
#    if(ref($PARAM[0]->{$param}) eq 'ARRAY'){
#	print STDERR "# $param = (@{$PARAM[0]->{$param}})\n";
#    }else{
#	print STDERR "# $param = $PARAM[0]->{$param}\n";
#    }
#}


## Load the ALMOR database if any of the given TOKAN SCHEMES require it (probably all do in practice)
if ( $loadalmor ){
    $ALMOR3DB=&ALMOR3::initialize($ALMOR_DB,"generation",$quiet);
    if( ! $quiet ) {
	print STDERR "...Finished loading ALMOR database\n";
    }
}



#######################################################################
#  OPEN MADA INPUT FILE AND TOKAN OUTPUT FILE(S)
#######################################################################

my $inFH = *IN;
$inFH = *IN; # This is to prevent a pointless warning message

#Using the below function will allow users to give a gzipped $madafile as input
if( ! &MADATools::openReadFile( $inFH, $madafile ) ) {
    die "$0:  Error - Unable to open .mada input file $madafile\n"; 
}



#  Old-style
#my $tokoutput = $madafile . ".$extension";
#open (OUT,">$tokoutput") || die "$0: Error - Unable to open output file $tokoutput\n";



#  Open file handle for each TOKAN SCHEME
my %outFH = ();
my $filebase = $madafile;
$filebase =~ s/\.gz//;

foreach $ext ( @extension ) {

    $outFH{$ext} = new FileHandle;
    $outFH{$ext}->open(">$filebase.$ext") || die "$0: Error - Unable to open output file $madafile.$ext\n";
    ## EGH 3 FEB 2012 - commenting this line allows for UTF8 sent_ids to pass correctly
    ## binmode $outFH{$ext}, ":utf8";

}



#######################################################################
# MAIN
#######################################################################


my @TOKANMEM=();
my @sentence=();
foreach ( @PARAM ) {
    push @TOKANMEM, {};
    push @sentence, [];
}

my $allwords=0;

my $current_SENT_ID="";
my $inputword="";
my $i;
my $blankline = 0;

my $mword = MADAWord->new();

if( ! $quiet ) {
    print STDERR "Reading MADA file to tokenize...\n";
}
while( $mword->readMADAStars($inFH) ) {


    if( $mword->isSentenceBreak() ) {

	if( ! $blankline ) {  # Don't print an additional newline after a blankline
	    for( $i=0; $i<=$#PARAM; $i++ ) {
		my $sentence = join(" ",@{ $sentence[$i] });	

		if ($PARAM[$i]->{"SENT_ID"} && $current_SENT_ID ne ""){
		    #print OUT "$current_SENT_ID ";
		    $outFH{$extension[$i]}->print("$current_SENT_ID ");
		}
		#print OUT "$sentence\n";
		$outFH{$extension[$i]}->print("$sentence\n");
		
		$sentence[$i]=[];
	    }
	}
	$blankline = 0;

    }
    elsif( $mword->isBlankLine() ) {
	
	## Get current sentence id if included
	my $com = $mword->getComment("SENTENCE_ID");
	if( $com ne "" ) { 
	    $current_SENT_ID = $com; 
	    $current_SENT_ID =~ s/^;;; SENTENCE_ID\s*//; ## Strip off the leading comment
	} else {
	    $current_SENT_ID = "";
	}

	for( $i=0; $i<=$#PARAM; $i++ ) {
	    my $sentence = "";	

	    if ($PARAM[$i]->{"SENT_ID"} && $current_SENT_ID ne ""){
		$outFH{$extension[$i]}->print("$current_SENT_ID ");
	    }

	    $outFH{$extension[$i]}->print("$sentence\n");
		
	    $sentence[$i]=[];
	}
	$blankline = 1;
    }
    else {

	$allwords++;
	if( ! $quiet ) {
	    print STDERR "[", $allwords/1000000, "M]" if (($allwords % 50000) == 0);
	    print STDERR "\n"       if (($allwords % 500000) == 0);
	}
	$inputword = $mword->getWord();


	## Get current sentence id if attached to this word
	my $com = $mword->getComment("SENTENCE_ID");
	if( $com ne "" ) { 
	    $current_SENT_ID = $com; 
	    $current_SENT_ID =~ s/^;;; SENTENCE_ID\s*//; ## Strip off the leading comment
	}


	if( $mword->isPass() ) {
	    ## This is mainly to handle @@LAT@@ words; the following causes 
	    ## the @@LAT@@ to have the same number of forms as the other words.
	    ## @@LAT@@ words are assumed to have a noun.
	    for( $i=0; $i<=$#PARAM; $i++ ) {
		if( $PARAM[$i]->{"PASS_AT_AT"} ) {
		    my @forms = ();
		    for (my $f=0; $f<=$PARAM[$i]->{"MAXFORM"}; $f++){			
			$forms[$f] = $inputword;
			if( $PARAM[$i]->{"FORM$f BASE"} =~ /^COPY(\d+)$/){
			    $forms[$f] = $forms[$1];
			} elsif ( $PARAM[$i]->{"FORM$f BASE"} =~ /^POS:(ALMOR|MADA)$/ ) {
			    $forms[$f] = "@@" . "noun" . "@@";
			} elsif ( $PARAM[$i]->{"FORM$f BASE"} =~ /^POS:(BW)$/ ) {
			    $forms[$f] = "@@" . "NOUN" . "@@";
			} elsif ( $PARAM[$i]->{"FORM$f BASE"} =~ /^POS:(PENN)$/ ) {
			    $forms[$f] = "@@" . "NN" . "@@";
			} elsif ( $PARAM[$i]->{"FORM$f BASE"} =~ /^POS:(CATIB)$/ ) {
			    $forms[$f] = "@@" . "NOM" . "@@";
			} 
		    }
		    my $latout = join($PARAM[$i]->{"FDELIM"},@forms);
		    push @{$sentence[$i]}, $latout;
		}
	    }
	}
	else {
	    my @feats = ();
	    my @word = ();
	    
	    if( $mword->isNoAnalysis() ) {

		for( $i=0; $i<=$#PARAM; $i++ ) {

		    if ($PARAM[$i]->{"MARK_NO_ANALYSIS"}){
			$word[$i] = "@@"."$inputword"."@@";
		    }else{
			$word[$i] = $inputword;
		    }
		    $feats[$i] = "NO-ANALYSIS";
		}

	    }
	    else {

		my $f = $mword->getOrigAnalysis(0);  #  Get first starred analysis in list
		$f =~ s/^[\*\^\_]\-?\d+\.\d*\s+//;   # Drop score
		
		$f =~ s/diac\:(\S+)\s*//;
		my $w = $1;  #Grab the diac form

		for( $i=0; $i<=$#PARAM; $i++ ) {
		   
		    $feats[$i] = $f;
		    $word[$i]  = $w;
		}

	    }

	    my $token;

	    for( $i=0; $i<=$#PARAM; $i++ ) {

		$token = &TOKAN::tokenize($PARAM[$i],$word[$i],$feats[$i],$ALMOR3DB,$TOKANMEM[$i]);
		push @{$sentence[$i]}, $token;
	    }
	    
	}

    }
	
}

foreach $ext ( @extension ) {
    $outFH{$ext}->close();
}

if( ! $quiet ) {
    print STDERR "\n";
}



sub printUsage {

    print "\nUsage: $0 config=<.madaconfig file> file=<.mada output file> [quiet] [other variables]\n\n";
    print "  Output is produced in <.madafile>.<output extension>. Both the config file and the mada\n";
    print "  file must be specified.\n\n";

    print "  If quiet is included on the command line, all informational and warning messages will be\n";
    print "   repressed.\n\n";

    print "  The other variables are optional, and can be any of the following,\n";
    print "  specified in VARIABLE=VALUE format:\n\n";
    print "    MADA_HOME=<directory location of MADA installation>\n";
    print "    SENTENCE_IDS=[YES|NO]\n";
    print "    ALMOR_DATABASE=<name of database file located in MADA_HOME/MADA/>\n";
    print "    TOKAN_SCHEME=<Quoted string specifying TOKAN form and content of output tokenization\n";
    print "    TOKAN_OUTPUT_EXTENSION=<tag applied to input file name to generate output file name; defaults to \"tok\"\n";
    print "    TOKAN_SCHEMES_FILE=<file, with full path, of TOKAN SCHEMES and corresponding output extensions, or else NONE>\n\n";
    print "  If any of the above options is specified on the command line, the\n";
    print "  command line value will be used instead of the value indicated in the\n";
    print "  .madaconfig file. All other options will be ignored. For a more\n";
    print "  detailed description of each variable, consult your .madaconfig file.\n\n";
}






