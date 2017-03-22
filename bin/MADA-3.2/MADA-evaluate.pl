#! /usr/bin/perl

use strict;
use warnings;

use MADA::MADATools;
use MADA::MADAWord;

#######################################################################
# MADA-evalute.pl
# Copyright (c) 2007,2008,2009,2010 Columbia University in the City of New York
#
# Please do not distribute to anyone else without written permission
# from authors.  If you know someone who can use this software, please 
# direct them to http://www1.ccls.columbia.edu/~cadim/MADA, where they
# may freely obtain the software.  Doing this helps us to understand how
# our software is being used, and to make future improvements tailored to
# the needs of users.
#
# MADA, TOKAN and ALMOR are distributed in the hope that they will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
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
# This script takes a .mada file and compares its entries to 
# a gold .mada file, producing accuracy information for evaluation
# purposes.  Most users will never have a need for this, however.
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
    die "$0: Error - configuration file not specified in command line. \n";
}

if( ! exists $cmdline->{FILE} ) {
    &printUsage();
    die "$0: Error - .mada file to process not specified in command line \n";
}
if( ! exists $cmdline->{GOLD} ) {
    &printUsage();
    die "$0: Error - gold file to process not specified in command line \n";
}


##################################################################################
#####  READ CONFIGURATION FILE, LOAD VARIABLES #####


my $configfile = $cmdline->{CONFIG};
my $madafile = $cmdline->{FILE};
my $goldfile = $cmdline->{GOLD};

# Read configuration file
my %configs = ();
if( $configfile ne "" ) {
    %configs = %{ &MADATools::readConfig($configfile) }; 
}

# Overwrite config file with whatever might have been entered 
#  on the commandline
foreach( keys %{$cmdline} ) {
    $configs{$_} = $cmdline->{$_};
}

my $evallist = "";
if( exists $configs{EVALUATION_FEATURES} ) {
    $evallist = $configs{EVALUATION_FEATURES};
}
else {
    die "$0: Error - No evaluation features specified in configuration file and/or command line.\n";
}


my $mapFeatToOld = "no";
if( exists $configs{MAP_TAGS} ) {
    $mapFeatToOld = lc( $configs{MAP_TAGS} );
    if( $mapFeatToOld !~ /^(yes|no)$/ ) { 
	$mapFeatToOld = "no";
	print STDERR "$0: Warning - Whether to map feature tags to old MADA set unspecified; defaulting to no mapping.\n";
    }
}


#print STDERR "EVALLIST = |$evallist|\n";
my $printerrs = "no";
if( exists $configs{PRINT_ERRORS} ) {
    $printerrs = lc( $configs{PRINT_ERRORS} );
    if( $printerrs !~ /^(yes|no)$/ ) { 
	$printerrs = "no";
	print STDERR "$0: Warning - Whether to print each discovered error is unspecified; defaulting to no printing.\n";
    }
}




##################################################################################
#####  DETERMINE WHAT TO EVALUATE ON #####


my %evalfeats = ();
my $partdiac = "no";
my $elem;


if( $evallist =~ /isstar/i ) { $evallist = "isstar"; } #Drop other feature terms

if( $evallist =~ s/partdiac// ) { $evalfeats{diac} = 1; $partdiac = "yes"; }



foreach $elem ( split(/\s+/,$evallist) ){
    $elem = lc( $elem );

    if( $elem =~ /^diac$/ && $partdiac eq "yes" ) {
	$partdiac = "no";
    }
    else {
	$evalfeats{$elem} = 1;
    }
}


my $featlist = "";
foreach( sort keys %evalfeats ) {
    $featlist .= " ($_)";
}

if( $partdiac eq "yes" ) { $featlist =~ s/diac/partdiac/; }
#print STDERR " FEATURES = $featlist\n";

# %evalfeats now has as keys all the features than need to be matched during evaluation


##################################################################################
#####  OPEN MADA AND GOLD FILES FOR READING #####

my $maFH = *MAFILE; 
$maFH = *MAFILE; # This is to prevent a pointless warning from occuring
if( ! &MADATools::openReadFile( $maFH, $madafile ) ) {
    die "$0: Error - Unable to open mada file : $madafile\n";
}

my $goldFH = *GOLDFILE; 
$goldFH = *GOLDFILE; # This is to prevent a pointless warning from occuring
if( ! &MADATools::openReadFile( $goldFH, $goldfile ) ) {
    die "$0: Error - Unable to open gold file : $goldfile\n";
}


##################################################################################
#####  EXAMINE EACH WORD IN THE TWO FILES IN TURN AND CALCUATE SCORES   #####


my $madaword = MADAWord->new();
my $goldword = MADAWord->new();
my $wordcount = 0;
my %numwords         = (gold => 0, mada => 0); 
my %numexcludedwords = (gold => 0, mada => 0);
my %numvalidwords    = (all  => 0, nopunct => 0, nosingles => 0);
my %numcorrect       = (all  => 0, nopunct => 0, nosingles => 0);

my %puncPOSTags     = (punc => 1, digit => 1);

my $f;
my $earlyexit = 0;
my $featcheck = 0;

while( $madaword->readMADAStars( $maFH ) ) {
    if( $goldword->readMADAStars( $goldFH ) != 1 ) {
	print STDERR "$0: Error - Word misalignment in files; unable to read gold while mada is read.\n";
	$earlyexit = 1;
	last;
    }

    if( $madaword->isSentenceBreak() ) {
	if( ! $goldword->isSentenceBreak() ) {
	    print STDERR "$0: Error - Sentence Break misalignment\n";
	    $earlyexit = 1;
	    last;
	}
    }
    elsif( $madaword->isBlankLine() ) {
	if( ! $goldword->isBlankLine() ) {
	    print STDERR "$0: Error - Blank Line misalignment\n";
	    $earlyexit = 1;
	    last;
	}
    }
    else {

	## Check the eval features against what feature set is contained in the gold word (once)
	##  -- drop eval features that can't be queried.
	if( $featcheck == 0 ) {

	    foreach $f ( keys %evalfeats ) {

		if( $f eq "isstar" ) { last; }

		#print STDERR "Checking Feature $f...\n";
		if( $goldword->getFeature($f,0) eq "" ) { 
		    print STDERR "$0: Warning - Feature $f doesn't seem to be in the gold file. It will be dropped from the evaluation.\n";
		    delete $evalfeats{$f};
		    $featlist =~ s/\s*\($f\)\s*/ /;
		}
	    }
	    $featcheck = 1;
	}


	$wordcount++;
	if( $wordcount % 50000 == 0 ) {
	    print STDERR "[" . $wordcount / 1000000 . "M]";
	}
	if( $wordcount % 500000 == 0 ) { print STDERR "\n"; }

	my $activeword = $goldword->getWord();

	if( $madaword->getWord() ne $activeword ) {
	    print STDERR "$0: Error - Word misalignment in word number $wordcount\n";
	    print STDERR "    MADA word = ", $madaword->getWord(), "   GOLD word = ", $goldword->getWord(), "\n";
	    $earlyexit = 1;
	    last;
	}

	$numwords{mada} += 1;
	$numwords{gold} += 1;

	my @goldstars = @{ $goldword->getStarIndices() };
	my @madastars = @{ $madaword->getStarIndices() };

	#print STDERR "$wordcount  $activeword  NumGoldStars = ", scalar( @goldstars ), "  NumMADAStars = ", scalar( @madastars ), " \n";

	my $bothstars = 1;
	
	if( scalar( @goldstars ) != 1 ) { 
	    $numexcludedwords{gold} += 1;
	    $bothstars = 0;
	}

	if( scalar( @madastars ) != 1 ) {
	    $numexcludedwords{mada} += 1;
	    $bothstars = 0;
	}

	if( $bothstars )  {

	    #Evaluate Correctness
	    my $match = 1;
	    
	    # Get features
	    
	    my $gold = $goldword->getFeatHash( $goldstars[0] );
	    my $mada = $madaword->getFeatHash( $madastars[0] );
	    
	    my $goldpos = $goldword->getFeature( "pos", $goldstars[0] );
	    my $goldnum = $goldword->getComment("TOTAL_NUMBER_OF_ANALYSES");  ## This comment is generated during readMADAStars()
	    $goldnum =~ s/^;;TOTAL_NUMBER_OF_ANALYSES = (\d+)$/$1/;


	    # Number of valid words increases
	    $numvalidwords{all} += 1;
	    if( $goldnum > 1 ) {
		$numvalidwords{nosingles} += 1;
	    }

	    if( ! exists $puncPOSTags{$goldpos} ) {
		$numvalidwords{nopunct} += 1;
	    }


	    my $failfeat  = "";
	    my $starfail  = "";
	    foreach $f ( sort keys %evalfeats ) {
		my $g = "";
		my $m = "";
		if( $f eq "isstar" ) {
		    $g = $goldword->getOrigAnalysis($goldstars[0]);
		    $m = $madaword->getOrigAnalysis($madastars[0]);
		    $g =~ s/^[\*\^\_]\-?[\d\.]+\s+//; # Drop scores, if present
		    $m =~ s/^[\*\^\_]\-?[\d\.]+\s+//; # drop scores, if present

		    ## Drop irrelevant feat line terms
		    $g =~ s/source\:(\S+)//g;
		    $g =~ s/stem\:(\S+)//g;
		    $g =~ s/stemcat\:(\S+)//g;
		    $g =~ s/rat\:(\S+)//g;

                    $m =~ s/source\:(\S+)//g;
                    $m =~ s/stem\:(\S+)//g;
                    $m =~ s/stemcat\:(\S+)//g;
                    $m =~ s/rat\:(\S+)//g;

		    ## Drop terms that would result in a harsher eval than in MADA 2.32
		    $g =~ s/bw\:(\S+)//g;
		    $g =~ s/gloss\:(\S+)//g;
		    $g =~ s/(lex\:\S+)\_\d+\b/$1/g;
		    $g =~ s/prc3\:(\S+)//g;

		    $m =~ s/bw\:(\S+)//g;
		    $m =~ s/gloss\:(\S+)//g;
		    $m =~ s/(lex\:\S+)\_\d+\b/$1/g;
		    $m =~ s/prc3\:(\S+)//g;

		    if( $mapFeatToOld eq "yes" ) { 

			##  For each feature in the line, map its value to the old set
			my @feats = split(/\s+/,$g);
			for(my $j =0; $j<=$#feats; $j++) {
			    my $elem = $feats[$j];
			    $elem=~ /^([^\:]+)\:(\S+)$/;
			    my $feat = $1;
			    my $val = $2;
			    $val = &MADATools::mapNewFeatValToOldFeatVal($feat,$val);
			    $feats[$j] = "$feat:$val";
			}
			$g = join(' ', @feats);


			@feats = split(/\s+/,$m);
			for(my $j =0; $j<=$#feats; $j++) {
			    my $elem = $feats[$j];
			    $elem=~ /^([^\:]+)\:(\S+)$/;
			    my $feat = $1;
			    my $val = $2;
			    $val = &MADATools::mapNewFeatValToOldFeatVal($feat,$val);
			    $feats[$j] = "$feat:$val";
			}
			$m = join(' ', @feats);
		    }


		    my @gsort = sort split(/\s+/,$g);
		    $g = join(' ', @gsort);

		    my @msort = sort split(/\s+/,$m);
		    $m = join(' ', @msort);
		    

		    my $p;
		    for($p=0;$p<=$#gsort;$p++) {
			if( $gsort[$p] ne $msort[$p] ) {
			    my $gf = $gsort[$p];
			    $gf =~ s/^([^\:]+)\:\S+$/$1/;
			    if( $gf eq "diac" ) {
				if( &MADATools::removeDiacriticsFromTail($gsort[$p]) ne 
				    &MADATools::removeDiacriticsFromTail($msort[$p]) ) {
				    $starfail .= " diac";
				}
				else {
				    $starfail .= " diactail";
				}
			    }
			    else {
				$starfail .= " $gf"; 
			    }
			}
		    }
		    

		}
		elsif( $f eq "diac" && $partdiac eq "yes" ) {
		    $g = &MADATools::removeDiacriticsFromTail($gold->{diac});
		    $m = &MADATools::removeDiacriticsFromTail($mada->{diac});
		}
		else{
		    $g = $gold->{$f};
		    $m = $mada->{$f};

		    if( $mapFeatToOld eq "yes" ) {
			my $ng = &MADATools::mapNewFeatValToOldFeatVal($f,$g);
			my $nm = &MADATools::mapNewFeatValToOldFeatVal($f,$m);

			if( $ng ne "" ) {
			    $g = $ng;
			}
			else { 
			    die "$0: Error - Unfamiliar $f tag encountered in Gold ($g).\n";
			}

			if( $nm ne "" ) {
			    $m = $nm;
			}
			else {
			    die "$0: Error - Unfamiliar $f tag encountered in File ($m).\n";
			}

		    }

		}
		
		if( ! defined $g || ! defined $m ) {
		    die "$0: Error - Unable to extract feature $f from word $wordcount : $activeword\n";
		}

		if( $g ne $m ) {
		    $match = 0;
		    if( $f eq "isstar" ) { $failfeat = "isstar : $starfail"; }
		    else {
			$failfeat .= " $f";
		    }
		}	
	    }

	    if( $match == 0 ) {
		if( $printerrs eq "yes" ) {
		    my $gfl = $goldword->getFeatLine( $goldstars[0] );
		    my $mfl = $madaword->getFeatLine( $madastars[0] );

		    printf "%10d\t%10s\t\tNo Match on [$failfeat ]\n\tGOLD: $gfl\n\tMADA: $mfl\n\n", $wordcount, $activeword;
		    #printf "%10d\t%15s\tNo Match on [$failfeat ]\n", $wordcount, $activeword;
		}
	    }
	    else {
		$numcorrect{all} += 1;

		if( $goldnum > 1 ) {
		    $numcorrect{nosingles} += 1;
		}

		if( ! exists $puncPOSTags{$goldpos} ) {
		    $numcorrect{nopunct} += 1;
		}

	    }
	    
	}

    }

   
}
print STDERR "\n";

close( $maFH );
close( $goldFH ); 

my  @accuracy = (0,0,0);
if( $numvalidwords{all} != 0 ){
    $accuracy[0] = 100 * $numcorrect{all} / $numvalidwords{all};
}
if( $numvalidwords{nopunct} != 0 ){
    $accuracy[1] = 100 * $numcorrect{nopunct} / $numvalidwords{nopunct};
}
if( $numvalidwords{nosingles} != 0 ){
    $accuracy[2] = 100 * $numcorrect{nosingles} / $numvalidwords{nosingles};
}

print "\n-------------------------------------------------------------------------------------------------\n\n";
print "  File Evaluated :\t\t$madafile\n";
print "  Gold Standard: \t\t$goldfile\n";
print "  This evaluation was based on the following features:\n";
print "     $featlist\n";
print "  Were Feature values mapped to their MADA-2.32 equivalents before evaluating? $mapFeatToOld\n\n";
if( $earlyexit) {
    print "  This evaluation was terminated early due to file misalignment.\n";
}

printf "     Number of words in Gold File                   = %15d\n", $numwords{gold};
printf "     Number of words in MADA File                   = %15d\n", $numwords{mada};
printf "     Number of words excluded from Gold             = %15d\n", $numexcludedwords{gold};
printf "     Number of words excluded from MADA             = %15d\n\n\n", $numexcludedwords{mada};

printf "  Considering all words:\n\n";
printf "     Number of words considered                     = %15d\n", $numvalidwords{all};
printf "     Number of correctly identified interpretations = %15d\n", $numcorrect{all};
printf "     Accuracy for all words                         = %15.3f %%\n\n", $accuracy[0];


printf "  Considering only cases that are not numbers or punctuation (in the gold standard):\n\n";
printf "     Number of non-number, punctuation cases        = %15d\n",$numvalidwords{nopunct};
printf "     Number of correctly identified interpretations = %15d\n", $numcorrect{nopunct};
printf "     Accuracy for non-punct                         = %15.3f %%\n\n", $accuracy[1];

printf "  Considering only non-trival cases (i.e., removing words with only one possible (gold) interpretation ):\n\n";
printf "     Number of non-trival cases                     = %15d\n", $numvalidwords{nosingles};
printf "     Number of correctly identified interpretations = %15d\n", $numcorrect{nosingles};
printf "     Accuracy for multiple-analysis words only      = %15.3f %%\n\n", $accuracy[2];

print "-------------------------------------------------------------------------------------------------\n\n";
print "\n\n";


########################################################################


sub printUsage {

    print "\nUsage: $0 file=<.mada file> gold=<gold .ma file> config=<evaluation .config file> [other variables]\n\n";
    print "  Output is written to STDOUT (and is often redirected to a text file).\n";
    print "  Both the gold file and the .mada file must be specified; the config file is optional.\n\n";

    print "  The other variables are optional, and can be any of the following,\n";
    print "  specified in VARIABLE=VALUE format:\n\n";

    print "    PRINT_ERRORS=(YES|NO)\n";
    print "    EVALUATION_FEATURES=\"list of features to evaluate on, separated by spaces, in quotes\"\n\n";

    print "  If any of the above options is specified on the command line, the\n";
    print "  command line value will be used instead of the value indicated in the\n";
    print "  .madaconfig file. All other options will be ignored.\n\n";
	
}



