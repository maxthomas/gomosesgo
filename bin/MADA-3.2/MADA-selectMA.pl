#! /usr/bin/perl
 
$| = 1;
use strict;
use warnings;
use MADA::MADATools;
use MADA::MADAWord;

my $MADAversion = "3.2";

#######################################################################
# MADA-selectMA.pl
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
# This script disambiguates the analyses in file.ma using the
# classification in file.ma.svmt.classified, and additional information. 
# Each potential feature can be weighted; the ranking is based on the
# sum of the weights of the classifiers which are in agreement with a
# particular analysis. Output is printed directly to STDOUT. 
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
    die "$0: Error - .ma file to process not specified in command line \n";
}

my $quiet = 0;
if( exists $cmdline->{QUIET} ) {
    $quiet = 1;
}

##################################################################################
#####  READ CONFIGURATION FILE, LOAD VARIABLES #####

my $configfile = $cmdline->{CONFIG};
my $mafile = $cmdline->{FILE};  
my $classifiedfile;
my $ngramfile;

if( exists $cmdline->{SVMT_CLASSIFIED} ) { $classifiedfile = $cmdline->{SVMT_CLASSIFIED}; }
else { $classifiedfile = $mafile . ".svmt.classified"; }

if( exists $cmdline->{NGRAM_FILE} ) { $ngramfile = $cmdline->{NGRAM_FILE}; }
else { $ngramfile = $mafile . ".ngram"; }

my $weightset = "normal";
my $weightfile = "";
my %classifiers;
my %otherfeatures;
my $sortanalyses = 1;
my $arbtiebreak = "";
my $lextype = "NORM";
my $listofClassifiers = "";
#my $listofIgnores = "";
my $listofOptions = "";

my $numTies = 0;

# Read configuration file
my %configs = %{ &MADATools::readConfig($configfile) }; 


# Overwrite config file with whatever might have been entered on the commandline
foreach( keys %{$cmdline} ) {
    $configs{$_} = $cmdline->{$_};
}


if ( ! exists $configs{MADA_HOME} ) {
    die "$0: Error - MADA_HOME installation directory unspecified in configuration file and/or command line.\n";
}
$configs{MADA_HOME} =~ s/\/+$//; # Strip off trailing '/' characters if present



if( exists $configs{CLASSIFIERS} ) {
    foreach( split( /\s/, $configs{CLASSIFIERS} ) ) {
	$classifiers{lc($_)} = 1;
    }
}
else { #default to using only Part-of-Speech; this is NOT recommended
    %classifiers = ( pos => 1 );
    &MADATools::report("Classifier list not specified in configuration file or command line.  Using Part-of-Speech (POS) as only classifier.","warn",$quiet);

}



if( exists $configs{OTHER_FEATURES} ) {
    foreach( split( /\s/, $configs{OTHER_FEATURES} ) ) {
	$otherfeatures{lc($_)} = 1;
    }
}
else { #default to using all other features
    %otherfeatures = ( spellmatch => 1, ngramlex => 1, ngramdiac => 1, 
		       notbackoff => 1 , partprc0 => 1, partprc1 => 1, 
		       partprc2 => 1, partprc3 => 1, partenc0 => 1, 
		       analyisset => 1);
    &MADATools::report("Other feature list not specified in configuration file or command line.  Using supplementary features.","warn",$quiet);
}




if( exists $configs{SORT_COMBINER_OUTPUT} ) {
    $sortanalyses = lc( $configs{SORT_COMBINER_OUTPUT} );
}
if( $sortanalyses =~ /^no$/ ) { $sortanalyses = 0; }
else { $sortanalyses = 1; }
$configs{SORT_COMBINER_OUTPUT} = $sortanalyses;
if( ! $sortanalyses ) { $listofOptions .= " (Do not sort analyses)"; }


if( exists $configs{TIE_BREAKING} ) {
    $arbtiebreak = lc( $configs{TIE_BREAKING} );
}
if( $arbtiebreak !~ /^(arbitrary|random|none)$/ ) { $arbtiebreak = "arbitrary"; }
$configs{TIE_BREAKING} = $arbtiebreak;
if( $arbtiebreak ne "none" ) { $listofOptions .= " (Tie Breaking is $arbtiebreak)"; }


if( exists $configs{FEATURE_WEIGHT_SET} ) {
    $weightset = lc( $configs{FEATURE_WEIGHT_SET} );
}
if( $weightset !~ /^(normal|original|pos|lexeme|custom)$/ ) { 
    $weightset = "normal"; 
    &MADATools::report("Invalid weight set specified in configuration file and/or command line.  Defaulting to weight set = NORMAL.","warn",$quiet);
    }
$configs{FEATURE_WEIGHT_SET} = $weightset;


if( $weightset eq "custom" ) {


    if( exists $configs{CUSTOM_FEATURE_WEIGHT_FILE} && -f $configs{CUSTOM_FEATURE_WEIGHT_FILE} ) {
	$weightfile = $configs{CUSTOM_FEATURE_WEIGHT_FILE};
    }
    else {
	&MADATools::report("Custom feature weight file unspecified in configuration file and/or command line.  Defaulting to normal weight file.","warn",$quiet);
	$weightset = "normal";
    }

}
else {
    $weightfile = $configs{MADA_HOME} . "/feature-weights/$weightset.weights"; 
}



if( exists $configs{LEXEME_TYPE} ) {
    $lextype = uc( $configs{LEXEME_TYPE} );
}
if( $lextype !~ /^(BAMA|NORM)$/ ) { 
    $lextype = "NORM"; 
    &MADATools::report("Invalid lexeme type specified in configuration file and/or command line.  Defaulting to lexeme type = NORM.","warn",$quiet);
    }
$configs{LEXEME_TYPE} = $lextype;



my $removeMAfile = 0;
if( exists $configs{REMOVE_MA_FILE} ) {
    $removeMAfile = lc( $configs{REMOVE_MA_FILE} );
}
if( $removeMAfile =~ /^yes$/ ) { $removeMAfile = 1; }
else { $removeMAfile = 0; }
$configs{REMOVE_MA_FILE} = $removeMAfile;


my $printanalyses = "all";
if( exists $configs{PRINT_ANALYSES} ) {
    $printanalyses = lc( $configs{PRINT_ANALYSES} );
}
if( $printanalyses !~ /^(\d+|all|stars)$/ ) {
    &MADATools::report("Invalid Print analyses option; it must be all, stars, or a positive number.  Defaulting to all.","warn",$quiet);
    $printanalyses = "all";
    $configs{PRINT_ANALYSES} = "all";
}
if( $printanalyses ne "all" ) {
    $listofOptions .= " (Print_Analyses is $printanalyses)";
}


my $ngramLMdir = "";
if( exists $otherfeatures{featsetprob} ) {
    if ( exists $configs{NGRAM_LM_DIRECTORY} ) {
	$configs{NGRAM_LM_DIRECTORY} =~ s/\/+$//; # Strip off trailing '/' characters if present
	$ngramLMdir = "$configs{MADA_HOME}/$configs{NGRAM_LM_DIRECTORY}";
    }
    else {
	&MADATools::report("Ngram langauge model directory unspecified in configuration file and/or command line.","warn",$quiet);
	delete $otherfeatures{featsetprob};
    }
}


##################################################################################
#####    INITIALIZE FEATURE WEIGHTS HASH   #####


#my %ignores = ();
my %featureweights = ();
my %partialweightfeatures = ();

foreach my $f ( keys %classifiers ) {
#    $ignores{$f} = 1;
    $featureweights{$f} = 0;
}

foreach my $f ( keys %otherfeatures ) {
    $featureweights{$f} = 0;
    if( $f =~ /^part(\S+)$/ ) {
	$partialweightfeatures{$f} = $1;
    }
}



foreach( sort keys %classifiers ) { 
    $listofClassifiers .= "($_) "; 
    #delete $ignores{$_};
}

my $numclassifiers = scalar( keys %classifiers );


##################################################################################
#####    READ IN WEIGHTS & NGRAM FILES   #####

my %weights = %{ &MADATools::readConfig($weightfile) }; 
foreach my $f ( keys %weights ) {
    my $w = $weights{$f};
    if( exists $featureweights{ lc($f) } && $w =~ /^\-?\d+\.?\d*$/ ) {   ## Only read actual numbers as weights
	$featureweights{ lc($f) } = $w;
    }
}

#my $numweights = 0;
my $maxweight = 0;
foreach ( keys %featureweights ) {
    if( $featureweights{$_} != 0 && $_ !~ /featsetprob/ ) {
	#$numweights++;
	if( $featureweights{$_} > 0 ) {
	    $maxweight += $featureweights{$_};
	}
    }
}
if( $maxweight == 0 ) { $maxweight  = 0.01; } # To avoid divide-by-zero errors during score normalization


#my %ngramlexes = ();
my $ngramFH;

if( exists $otherfeatures{ngramdiac} || exists $otherfeatures{ngramlex} ) {

    $ngramFH = *NGRAMFH; 
    $ngramFH = *NGRAMFH; # This is to prevent a pointless warning from occuring
    if( ! &MADATools::openReadFile( $ngramFH, $ngramfile ) ) {
	die "$0: Error - Unable to open ngram file : $ngramfile\n";
    }

    # Read past fixed header
    my $line = <$ngramFH>;
    $line = <$ngramFH>;
    $line = <$ngramFH>;
    $line = <$ngramFH>;
    


}



##  Read analysis set file
my %analysisProbs = ();
if( exists $otherfeatures{featsetprob} ) {
    my $analysisModel = $ngramLMdir . "/MADA-train.analyses.1.kn-interpolated.lm";
    
    if( open( AMODEL, $analysisModel ) ) {

	my $line;
	while( $line = <AMODEL> ) {

	    chomp $line;
	    if( $line =~ /^(\-?\d+\.?\d*)\s+(\S+)/ ) {
		$analysisProbs{$2} = 10 ** $1;  # File records log probs; hash has actual probs
	    }
	}
       	close AMODEL;

    }
    else {
	&MADATools::report("Unable to open analysis set model file $analysisModel; disabling the featsetprob feature\n","error",$quiet);
	delete $otherfeatures{featsetprob};
    }
    


}



##################################################################################
#####    OPEN .MA, .SVMT.CLASSIFED FILES   #####

my $maFH = *MA;
$maFH = *MA;  # This is to prevent a pointless warning from occuring
if( ! &MADATools::openReadFile($maFH, $mafile) ) {
    die "$0: Error - Unable to open .ma file specified in command line: $mafile\n";
}

my $svmtFH = *SVMT;
$svmtFH = *SVMT; # This is to prevent a pointless warning from occuring
if( ! &MADATools::openReadFile($svmtFH, $classifiedfile) ) {
    die "$0: Error - Unable to open .svmt.classified file: $classifiedfile\n";
}






##################################################################################
#####    PRINT FILE HEADER   #####

my $date = `date`;

print ";; MADA OUTPUT FILE  -- VERSION $MADAversion  --- File created on $date";
print ";; This file was produced by the command line:\n;;  perl $0 ";
foreach (@ARGV) { print "$_ "; } 
print "\n";

if($listofClassifiers ne "" ) { print ";;CLASSIFIERS CONSIDERED: $listofClassifiers \n"; }
if($listofOptions ne "" ) { print ";;OPTIONS: $listofOptions \n"; }
print ";;Feature Weights:  ";
foreach( sort keys %featureweights ) {
    print "$_ = $featureweights{$_}  ";
}

#print "\n;;Partial Weight Features:  ";
#foreach( sort keys %partialweightfeatures ) {
#    print "$_ = $partialweightfeatures{$_}  ";
#}

print "\n;;==========================================\n";  ## End of Header Line


##################################################################################
#####    PROCESS .MA FILE, PERFORM COMBINATION/SCORING   #####


my $mword = MADAWord->new();
my $wordcount=0;
my $classline;
my $ngramline;
my $nlex;
my $ndiac;

my %printoptions = ( filehandle => *STDOUT, reducedprint => $printanalyses );
if( ! $sortanalyses ) { $printoptions{nosort} = 1; }


while( $mword->readMADAWord( $maFH ) ) {

    if( $mword->isSentenceBreak() ) {
	$mword->printMADAWord(\%printoptions);
    }
    elsif( $mword->isBlankLine() ) {
	$mword->printMADAWord(\%printoptions);
	## Just print SENTENCE and BLANK-LINE comments
    }
    else {
	$wordcount++;
	if( ! $quiet) {
	    print STDERR "[" . $wordcount/1000000 . "M]" if (($wordcount % 50000) == 0);
	    print STDERR "\n"       if (($wordcount % 500000) == 0);
	}
	

	$classline = <$svmtFH>;
	chomp $classline;
	if( $classline =~ /^\s*\S*\s*$/ && $numclassifiers > 0 ) {
	    #i.e., classline is blank or just as the word with no SVM predictions
	    die "$0: Error - Found incomplete line at word # $wordcount in SVMT classifier output file; this may indicate that your SVMTools software has not been configured correctly. Exiting.\n\n";
	}

	$printoptions{featureguesses} = $classline;

	$nlex = "";
	$ndiac = "";
	if( exists $otherfeatures{ngramdiac} || exists $otherfeatures{ngramlex} ) {
	    $ngramline = <$ngramFH>;
	    my @entries = split(/\s+/, $ngramline);
	    	    
	    if( exists $otherfeatures{ngramdiac} ) {
		if( $entries[3] > 0 ) {
		    $ndiac = $entries[5];
		}
	    }

	    if( exists $otherfeatures{ngramlex} ) {
		if( $entries[2] > 0 ) {
		    $nlex = $entries[4];
		}
	    }

	    if( ! defined $nlex ) { $nlex = ""; }
	    if( ! defined $ndiac) { $ndiac = ""; }
	}
	

	if( $mword->isNoAnalysis() || $mword->isPass() ) {
	    $mword->printMADAWord(\%printoptions);
	}
	else {
	    &selectAnalysis( $wordcount, $classline, $nlex, $ndiac, $mword );
	    $mword->printMADAWord(\%printoptions);	    
	}

    }

}

close $maFH;
close $svmtFH;
if( exists $otherfeatures{ngramdiac} || exists $otherfeatures{ngramlex} ) {
    close $ngramFH;
}

# Remove .ma, .svmt.classified and .ngram files to reduce file clutter, if requested
if( $removeMAfile ) {
    unlink( $mafile );
    unlink( $classifiedfile );
    unlink( $ngramfile );
}

if( ! $quiet) {
#print STDERR "\n  Number of Tie Score cases discovered = $numTies\n";
    print STDERR "Done.\n";
}

##################################################################################
#####   SUBROUTINES   #####


#  Give scores to the analyses in this MADAWord
sub selectAnalysis {
    my ($wc, $classline, $nlex, $ndiac, $mword) = @_;

    # parse the classifier line
    my ($f, $i, $j);

    my %SVMselections = ();
    foreach $f ( keys %classifiers ) {
	if( $classline =~ /$f\:(\S+)/ ) {
	    $SVMselections{$f} = $1;
	}
	else { $SVMselections{$f} = "NO-SVM-SELECTION"; }
    }


    my @scores = ();
    my @labels = ();
    my $num = $mword->getNumAnalyses();
#    my $unword = MADATools::removeDiacritics( $mword->getWord() );


    for( $i = 0; $i<$num; $i++ ) {

	$scores[$i] = 0;
	$labels[$i] = "_";

	my $diac = $mword->getDiac($i);
	my $lex;
	if( $lextype eq "BAMA" ) { $lex = $mword->getLex($i); }
	else { $lex = $mword->getNormLex($i); }

	my $orig = $mword->getOrigAnalysis($i);

	# Add scores from prinicpal features
	foreach $f ( keys %classifiers ) {
	    
	    if( $SVMselections{$f} eq $mword->getFeature($f,$i) ) {
		# Require exact matches on other features to get full weight
		$scores[$i] += $featureweights{$f};
	    }
	}

	# Add score from isdefault, spellmatch

	if( exists $otherfeatures{notbackoff} ) {
	    if( $orig !~ /source\:backoff/ ) {
		$scores[$i] += $featureweights{notbackoff};
	    }
	}

	if( exists $otherfeatures{spellmatch} ) {
	    my $undiac = &MADATools::removeDiacritics($diac);
	    my $unword = &MADATools::removeDiacritics( $mword->getWord() );
	    
	    $undiac =~ s/Y/y/g;
	    $unword =~ s/Y/y/g;
	    
	    if( $undiac eq $unword ) {
		$scores[$i] += $featureweights{spellmatch};
	    }
	}	
	

	if( exists $otherfeatures{ngramlex} ) {
	    
	    my $l = $lex;
	    $l =~ s/\d/8/g;
	    if( $nlex eq $l ) {
		$scores[$i] += $featureweights{ngramlex};
	    }
	}

	if( exists $otherfeatures{ngramdiac} ) {

	    my $d = $diac;
	    $d =~ s/\d/8/g;
	    if( $ndiac eq $d ) {
		$scores[$i] += $featureweights{ngramdiac};
	    }
	}


	foreach $f ( keys %partialweightfeatures ) {

	    my $full = $partialweightfeatures{$f};
	    my $mf = $mword->getFeature($full,$i);
	    if( ( $SVMselections{$full} =~ /^(0|na)$/ && $mf =~ /^(0|na)$/ ) ||
		( $SVMselections{$full} !~ /^(0|na)$/ && $mf !~ /^(0|na)$/ ) ) {
		$scores[$i] += $featureweights{$f};		    
	    }	    

	}


	if( exists $otherfeatures{featsetprob} ) {
	    ## Add weight to all analyses based on the probablily their analysis tag set in the training data (smoothed)

	    my $key = $orig;

	    $key =~ s/^[\*\_\^]\-?\d+\.\d+\s+(.+)/$1/;
	    $key =~ s/diac\:\S+//;
	    $key =~ s/lex\:\S+//;
	    $key =~ s/bw\:\S+//;
	    $key =~ s/gloss\:\S+//;
	    $key =~ s/rat\:\S+//;
	    $key =~ s/source\:\S+//;
	    $key =~ s/stem\:\S+//;
	    $key =~ s/stemcat\:\S+//;	    
	    $key =~ s/^\s+|\s+$//g;
	    $key =~ s/\s+/\-/g;

	    if( exists $analysisProbs{$key} ) {
		$scores[$i] += $featureweights{featsetprob} * $analysisProbs{$key};
		#print STDERR "$diac -> $analysisProbs{$key} : $key\n";
	    }
	    else{
		$scores[$i] += $featureweights{featsetprob} * $analysisProbs{"<unk>"};		
		#print STDERR "$diac -> " . $analysisProbs{"<unk>"} . " : UNK $key\n";
	    }

	}
	

    }


    #All the analyses are scored, now find the best one(s)
    my @bestscores = ();
    my $best = -99999999999;
    for( $i = 0; $i<$num; $i++ ) {
	if( $scores[$i] > $best ) {
	    $best = $scores[$i];
	    @bestscores = ($i);
	}
	elsif( $scores[$i] == $best ) {
	    push @bestscores, $i;
	}
    }

    
    # If more than one analysis has the top score, pick the first one,
    # and give the others a "^" label.

    #  Normalize scores

    if( scalar( @bestscores ) > 1 ) { 
	#print $mword->getWord() . " Ties:  ";
	#foreach( @bestscores ) { print "$_ "; } print "\n";
	$numTies++;
	if( $arbtiebreak eq "none" ) {
	    foreach( @bestscores ) { 
		$labels[$_] = "*"; 
		if( $maxweight + 0.1 != 0 ) {
		    $scores[$_] += 0.1;
		}
		else { $scores[$_] += 0.15; }
	    }
	}
	elsif ($arbtiebreak eq "arbitrary") {
	    $labels[$bestscores[0]] = "*";
	    $scores[$bestscores[0]] += 0.1;
	    for($i = 1; $i<= $#bestscores; $i++ ) {
		$labels[$bestscores[$i]] = "^";
	    } 
	}
	elsif ($arbtiebreak eq "random" ) {
	    my $sel = int rand($#bestscores + 1);
	    for($i=0; $i<=$#bestscores; $i++ ) {
		if( $i == $sel ) {
		    $labels[$bestscores[$sel]] = "*";
		    $scores[$bestscores[$sel]] += 0.1;
		}
		else {
		    $labels[$bestscores[$i]] = "^";
		}
	    }
	}

	for( $i = 0; $i<$num; $i++) {
	    if( $maxweight + 0.1 != 0 ) {
		$scores[$i] = $scores[$i] / ($maxweight + 0.1);	    
	    }
	    else { # Avoid divide by zero errors
		$scores[$bestscores[0]] += 0.05;
		$scores[$i] = $scores[$i] / ($maxweight + 0.15);
	    }
	}
    }
    else{ 
	$labels[$bestscores[0]] = "*";
	for( $i = 0; $i<$num; $i++) {	    
	    $scores[$i] = $scores[$i] / $maxweight;
	}
    }


    # Adjust $mword, adding the score and label information

    $mword->{starlabels} = \@labels;
    $mword->{scores} = \@scores;


    return 0;
}





sub printUsage {

    print "\nUsage: $0 config=<.madaconfig file> file=<.ma file> [quiet] [other variables]\n\n";
    print "  Output is written to STDOUT (and is often redirected to a .mada file).\n";
    print "  Both the config file and the .ma file must be specified.\n\n";

    print "  If quiet is included on the command line, all informational and warning messages will be\n";
    print "   repressed.\n\n";


    print "  The other variables are optional, and can be any of the following,\n";
    print "  specified in VARIABLE=VALUE format:\n\n";

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

    print "  If any of the above options is specified on the command line, the\n";
    print "  command line value will be used instead of the value indicated in the\n";
    print "  .madaconfig file. All other options will be ignored. For a more\n";
    print "  detailed description of each variable, consult your .madaconfig file.\n\n";
	
}




