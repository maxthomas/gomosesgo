#! /usr/bin/perl

$| = 1;
use strict;
use warnings;
use Benchmark;
use MADA::MADATools;
use File::Spec;


#######################################################################
# MADA+TOKAN.pl
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
# This is a superscript that runs the MADA preprocessor, MADA and TOKAN 
# on an input file, according to the configuration specified.
#
# Usage: MADA+TOKAN.pl config=<config file> file=<text>
#
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

my $outputdir = "";
if( exists $cmdline->{OUTPUTDIR} ) {
    $outputdir = File::Spec->rel2abs( $cmdline->{OUTPUTDIR} );
    if( ! -d $outputdir ) {
	&printUsage();
	die "$0: Error - Specified output directory does not exist \n";
    }
}


##################################################################################
#####  READ CONFIGURATION FILE, LOAD VARIABLES #####

my $home;
my $configfile = $cmdline->{CONFIG};
my $file = $cmdline->{FILE};

# Read configuration file
my %configs = %{ &MADATools::readConfig($configfile) }; 
# Overwrite config file with whatever might have been entered 
#    on the commandline
foreach( keys %{$cmdline} ) {
    $configs{$_} = $cmdline->{$_};
}


# Get the MADA_HOME directory
if ( ! exists $configs{MADA_HOME} ) {
    die "$0: Error - MADA_HOME installation directory unspecified in configuration file and/or command line.\n";
}
$configs{MADA_HOME} =~ s/\/+$//; # Strip off trailing '/' characters if present
$home = $configs{MADA_HOME};


my $runPre;
if( exists $configs{RUN_PREPROCESSOR} ) {
    $runPre = lc( $configs{RUN_PREPROCESSOR} );
}
if( $runPre =~ /^no$/ ) { 
    $runPre = 0;
} elsif( $runPre =~ /^yes$/ ) {
    $runPre = 1;
} else { 
    $runPre = 1; 
    &MADATools::report("Whether to run Preprocesor unspecified in configuration file and command line.  Assuming Preprocessor is to be run.", "warn", $quiet);
}
$configs{RUN_PREPROCESSOR} = $runPre;

my $runMADA;
if( exists $configs{RUN_MADA} ) {
    $runMADA = lc( $configs{RUN_MADA} );
}
if( $runMADA =~ /^no$/ ) {
    $runMADA = 0;
} elsif( $runMADA =~ /^yes$/ ) {
    $runMADA = 1;
} else { 
    $runMADA = 1; 
    &MADATools::report("Whether to run MADA unspecified in configuration file and command line.  Assuming MADA is to be run.", "warn", $quiet);
}
$configs{RUN_MADA} = $runMADA;



my $runTOKAN;
if( exists $configs{RUN_TOKAN} ) {
    $runTOKAN = lc( $configs{RUN_TOKAN} );
}
if( $runTOKAN =~ /^yes$/ ) {
    $runTOKAN = 1;
} elsif( $runTOKAN =~ /^no$/ ) {
    $runTOKAN = 0;
} else { 
    $runTOKAN = 0; 
    &MADATools::report("Whether to run TOKAN unspecified in configuration file and command line.  Assuming TOKAN is not to be run.", "warn", $quiet);
}
$configs{RUN_TOKAN} = $runTOKAN;


my $compressOuts;
if( exists $configs{COMPRESS_OUTPUTS} ) {
    $compressOuts = lc( $configs{COMPRESS_OUTPUTS} );
 }
if( $compressOuts =~ /^yes$/ ) {
    $compressOuts = 1;
} elsif ( $compressOuts =~ /^no$/ ) {
    $compressOuts = 0;
} else {
    $compressOuts = 0;
    &MADATools::report("Whether to compress output files unspecified in configuration file and command line.  Outputs will not be compressed.", "warn", $quiet);
}
$configs{COMPRESS_OUTPUTS} = $compressOuts;


##################################################################################
#####  VERIFY THAT REQUIRED INSTALLATION FILES ARE PRESENT  #####

if( $runMADA || $runTOKAN ) {
    my $almordb = $configs{ALMOR_DATABASE};
    my $ngramdir = $configs{NGRAM_LM_DIRECTORY};
    my $modeldir = $configs{MODEL_DIR};

    if( defined $almordb ) {
	$almordb = $home . "/MADA/$almordb";
	if( ! -e $almordb ) {
	    die "$0: Error - Unable to locate specified ALMOR Database file.\n";
	}
    } else {
	die "$0: Error - ALMOR_DATABASE configuration variable undefined. \n";
    }

    if( defined $ngramdir ) {
	$ngramdir = "$home/$ngramdir";
	if( ! -e "$ngramdir/MADA-train.diacs.5.lm" || 
	    ! -e "$ngramdir/MADA-train.lexes.5.lm" ||
	    ! -e "$ngramdir/MADA-train.normlexes.5.lm" ||
	    ! -e "$ngramdir/MADA-train.analyses.1.kn-interpolated.lm" ) {
	    die "$0: Error - Missing some language model files from $ngramdir -- check your MADA installation and configuration.\n";
	}
    } else {
	die "$0: Error - NGRAM_LM_DIRECTORY configuration variable undefined.\n";
    }

    if( defined $modeldir ) {
	$modeldir = "$home/$modeldir";
	if( ! -e "$modeldir/DefaultBackLexFeatureOrders" || 
	    ! -e "$modeldir/asp.DICT"   || ! -e "$modeldir/cas.DICT" ||
	    ! -e "$modeldir/enc0.DICT"  || ! -e "$modeldir/gen.DICT" ||
	    ! -e "$modeldir/vox.DICT"   || ! -e "$modeldir/mod.DICT" ||
	    ! -e "$modeldir/num.DICT"   || ! -e "$modeldir/per.DICT" ||
	    ! -e "$modeldir/pos.DICT"   || ! -e "$modeldir/prc0.DICT" ||
	    ! -e "$modeldir/prc1.DICT"  || ! -e "$modeldir/prc2.DICT" ||
	    ! -e "$modeldir/prc3.DICT"  || ! -e "$modeldir/stt.DICT" ) {

	    die "$0: Error - Missing some of the SVM model files from $modeldir -- check your MADA installation and configuration.\n";
	}

    } else {
	die "$0: Error - MODEL_DIR configuration variable undefined.\n";
    }

}

##################################################################################
#####  IF OUTPUT DIRECTORY SPECIFIED, ADJUST INPUT FILE  #####

my $origfile = File::Spec->rel2abs($file);
my $linkfile= "";
if( $outputdir ne "" ) {
    my( $vol, $dir, $basefile) = File::Spec->splitpath($file);    
    $file = "$outputdir" . "/$basefile";
    system("ln -sf $origfile $file");
    $linkfile = $file;
}


##################################################################################
#####  GENERATE COMMAND LINE ARGUMENTS FOR EACH SCRIPT  #####


my @outputs = ();

#print STDERR "File 0 = $file\n";
my $args0 = "config=$configfile file=$file";      # For MADA-preprocess (UTF8->Formatted BW)
if( $runPre ) {
    $file =~ s/\.gz$//;
    if( $file !~ /\.bw$/ ) {
	$file = "$file.bw";
    }

    push @outputs, $file;  ## Record to compress later

}


#print STDERR "File 1 = $file\n";
my $args1 = "config=$configfile file=$file";      # For MADA-SVMTOOLS
my $args2;                                        # For TOKAN

if( $runMADA ) {
    $file =~ s/\.gz$//;
 
    push @outputs, "$file.ma\.";   ## Record to compress later (temp files)
    push @outputs, "$file.ma";       ## Record to compress later (temp files)

    if( $file !~ /\.mada$/ ) {
	$file = "$file.mada";
    }
    $args2 = "config=$configfile file=$file"; 

    push @outputs, "$file";    ## Record to compress later, this should grab any TOKAN output too.

}
else {
    $args2 = "config=$configfile file=$file"; 
    #print STDERR "NO MADA $args2\n";
    my $g = $file;
    $g =~ s/\.gz//;
    push @outputs, "$g\.";    ## Record to compress later, this should grab any TOKAN output too.
} 


my ($arg, $var, $val);

##  Add commandline variables to argument lists for subscripts
foreach $arg ( @ARGV ) { 
    if( $arg !~ /^(config\=|file\=|quiet)/i ) {
	$arg =~ /^([^\=]+\=)(.+)$/;
	$var = $1;
	$val = $2;
	if( $val =~ /\s/ ) { $val = "\"$val\""; } # Add quotes if needed
	$args1 .= " $var" . $val; 
	$args2 .= " $var" . $val;
	$args0 .= " $var" . $val;
    }
}

if( $quiet ) {
   $args0 .= " quiet";
    $args1 .= " quiet";
    $args2 .= " quiet";
}



##################################################################################
#####  RUN SCRIPTS  #####




my $runfile = $file;

my $starttime = Benchmark->new;
my ($stime, $etime);


##  Run requested preprocessor steps 
if( $runPre ) {
    if( ! $quiet ) {
	print STDERR "\n===========\n\n";
	print STDERR "Running Preprocessor\n\n";
	$stime = Benchmark->new;
    }
    system("perl $home/MADA-preprocess.pl $args0");
    if( ! $quiet ) {	
	$etime = Benchmark->new;
	print STDERR "Finished preprocessing. Time : ", timestr(timediff($etime, $stime));
	print STDERR "\n";
    }
}


##  Run MADA
if( $runMADA ) {
    if( ! $quiet ) {
	print STDERR "\n===========\n\n";
	print STDERR "Running MADA\n";
    }
    system("perl $home/MADA-SVMTOOLS.pl $args1");
    $runfile = $runfile . ".mada";
}


## Run TOKAN
if( $runTOKAN ) {
    if( ! $quiet ) {
	print STDERR "===========\n\n";
	print STDERR "Running TOKAN\n\n";
	$stime = Benchmark->new;
    }
    system("perl $home/TOKAN.pl $args2");
    if( ! $quiet ) {
	$etime = Benchmark->new;
	print STDERR "Finished TOKAN. Time: ", timestr(timediff($etime,$stime));
	print STDERR "\n";
    }
}

##################################################################################
#####  CLEAN UP  #####

if( $linkfile ne "" ) {
    unlink( $linkfile );  ## Delete the softlink copy of the original file in the outputdir
}

## Compress Outputs?
if( $compressOuts ) {
    if( ! $quiet ) {
	print STDERR "\n===========\n";
	print STDERR "Compressing Output files...\n";
    }
    foreach my $f ( @outputs ) {
	#print STDERR "COMPRESS LIST = $f\n";
	my @temps = glob("$f*");
	foreach my $g ( @temps ) {
	    if( $g !~ /\.gz$/ ) {
		if( ! $quiet ) {
		    print STDERR "   Compressing $g ...\n";
		}
		system("gzip -qf $g");  # Quiet, rewrite existing .gz file if present
	    }
	}
    }

}


if( ! $quiet ) {
    $etime = Benchmark->new;
    print STDERR "\n===========\n\n";
    print STDERR "Finished All of MADA+TOKAN.  Final Total Time: ", timestr(timediff($etime,$starttime));
    if( $outputdir ne "" ) {
	print STDERR "\n All output files can be found under $outputdir\n";
    }
    print STDERR "\n===========\n\n";
}




sub printUsage() {
    print "\nUsage: $0 config=<.madaconfig file> file=<text file> [outputdir=<directory location for output files> ] [quiet] [other variables]\n\n";
    print "  Final output is placed in file.mada and/or \n";
    print "  file[.mada]?.tok; other files may also be produced.\n";
    print "  Both the config file and the text file must be specified.\n\n";

    print "  If an outputdir is specified on the command line, all files MADA+TOKAN produces\n";
    print "    will be placed in that directory.  If outputdir is not specified, all output\n";
    print "    files will be placed in the same directory as the input file.\n\n";

    print "  If quiet is included on the command line, all informational and warning messages will be\n";
    print "   repressed.\n\n";

    print "  The other variables are optional and are passed to the appropriate scripts\n";
    print "  when necessary. They can be any of the following, specified in VARIABLE=VALUE format:\n\n";

    print "  Used in this script:\n";
    print "    PERL_EXECUTABLE=<the location of the perl executable to use when running SVMTools -- please use 5.8.8 (5.10.0 is not supported by SVMTools\n"; 
    print "    RUN_PREPROCESSOR=[YES|NO]\n";
    print "    RUN_MADA=[YES|NO]\n";   
    print "    RUN_TOKAN=[YES|NO]\n\n";

    print "  Used in MADA-preprocess.pl:\n";
    print "    MADA_HOME=<directory location of MADA installation>\n";
    print "    INPUT_ENCODING = [UTF8|UTF-8|Buckwalter|BW]\n";
    print "    SEPARATEPUNCT = [YES|NO]\n";
    print "    SENTENCE_IDS=[YES|NO]\n\n";

    print "  Used in MADA-morphananalyis.pl:\n";
    print "    MADA_HOME=<directory location of MADA installation>\n";
    print "    ALMOR_DATABASE=<name of database file located in MADA_HOME/MADA/>\n";  
    print "    SENTENCE_IDS=[YES|NO]\n";
    print "    MORPH_BACKOFF = [NONE|NOAN-PROP|ADD-PROP|NOAN-ALL|ADD-ALL]\n\n";


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
    print "    NGRAM_LM_DIRECTORY=<location of the directory containing the ngram language models, relative to MADA_HOME>\n";
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


    print "  Used in TOKAN.pl:\n";
    print "    TOKAN_SCHEME=\"instructions for TOKAN operation and output, separated by spaces and in quotes\"\n";
    print "    ALMOR_DATABASE=<name of database file located in MADA_HOME/MADA/>\n\n";  

    

    print "  If any of the above options is specified on the command line, the\n";
    print "  command line value will be used instead of the value indicated in the\n";
    print "  .madaconfig file. All other options will be ignored. For a more\n";
    print "  detailed description of each variable, consult your .madaconfig file.\n\n";



}
