#! /usr/bin/perl

$| = 1;
use strict;
use warnings;
use FileHandle;
use MADA::MADATools;
use MADA::MADAWord;

#######################################################################
# MADA-generate-SVM+ngram-files.pl
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
# This script takes the output of the Morphanalysis script (a .ma file)
# and produces the input file for the SVMTools tagger, the backup
# lexica for the tagger, and an Ngram file for the input, which lists
# the ngram model choices for lexeme and surface diacritics of the
# words (if the configuration asks for them).
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
my $base = $mafile;
$base =~ s/\.gz$//;

my $svmtfile = $base . ".svmt";


my %configs = %{ &MADATools::readConfig($configfile) }; 
# Overwrite config file with whatever might have been 
#   entered on the commandline
foreach( keys %{$cmdline} ) {
    $configs{$_} = $cmdline->{$_};
}

if ( ! exists $configs{MADA_HOME} ) {
    die "$0: Error - MADA_HOME installation directory unspecified in configuration file and/or command line.\n";
}
$configs{MADA_HOME} =~ s/\/+$//; # Strip off trailing '/' characters if present


my $SVMtraindict = "";
if ( ! exists $configs{MODEL_DIR} ) {
    &MADATools::report("SVM Training Dictionary file unspecified in configuration file and/or command line.", "warn", $quiet);
}
if ( exists $configs{MODEL_DIR} )  {
    $SVMtraindict = "$configs{MADA_HOME}/$configs{MODEL_DIR}/pos.DICT";
    if( ! -e $SVMtraindict ) { 
	die "$0: Error - MODEL_DIR (SVM model directory) unspecified in configuration file and/or command line.\n";
    }
    #print STDERR "Training corpus dictionary: $SVMtraindict\n";
}


my %classifiers;
if( exists $configs{CLASSIFIERS} ) {
    foreach( split( /\s/, $configs{CLASSIFIERS} ) ) {
	$classifiers{$_} = 1;
    }
}
else { #default to using only pos as a single classifer
    %classifiers = ( pos => 1 );
    &MADATools::report("Classifier list not specified in configuration file or command line. Using Part-of-Speech (POS) as only classifier.","warn",$quiet);

}


my %otherfeatures;
if( exists $configs{OTHER_FEATURES} ) {
    foreach( split( /\s/, $configs{OTHER_FEATURES} ) ) {
	$otherfeatures{$_} = 1;
    }
}
else { #default to using all other features
    %otherfeatures = ( spellmatch => 1, ngramlex => 1, ngramdiac => 1 );
    &MADATools::report("Other feature list not specified in configuration file or command line.  Using standard supplementary features.","warn",$quiet);

}



my $ngramLMdir = "";
if ( exists $configs{NGRAM_LM_DIRECTORY} ) {
    $configs{NGRAM_LM_DIRECTORY} =~ s/\/+$//; # Strip off trailing '/' characters if present
    $ngramLMdir = "$configs{MADA_HOME}/$configs{NGRAM_LM_DIRECTORY}";
}
else {
    &MADATools::report("Ngram langauge model directory unspecified in configuration file and/or command line. A .ngrams file will not be created for this input ($mafile).","warn",$quiet);
    delete $otherfeatures{ngramlex};    
    delete $otherfeatures{ngramdiac};
}




my $SRIngramtool = "";
if( exists $otherfeatures{ngramlex} || exists $otherfeatures{ngramdiac} ) {
    if( exists $configs{SRI_NGRAM_TOOL} && -f $configs{SRI_NGRAM_TOOL} ) {
	$SRIngramtool = $configs{SRI_NGRAM_TOOL};
    }
    else {
	&MADATools::report("SRI Ngram disambiguation tool unspecified in configuration file and/or command line.  A .ngrams file will not include higher-order ngrams.","warn", $quiet);
	delete $otherfeatures{ngramlex};
	delete $otherfeatures{ngramdiac};
    }
}


my $lextype = "NORM";
if( exists $otherfeatures{ngramlex} ) {
    if( exists $configs{LEXEME_TYPE} ) {
	$lextype = uc( $configs{LEXEME_TYPE} );
    }
    if( $lextype !~ /^(BAMA|NORM)$/ ) { 
	$lextype = "NORM"; 
	&MADATools::report("Invalid lexeme type specified in configuration file and/or command line. Defaulting to lexeme type = NORM.", "warn", $quiet);
	}
    $configs{LEXEME_TYPE} = $lextype;
}


my $lexorder = 4;
if( exists $otherfeatures{ngramlex} ) {
    if( exists $configs{LEX_NGRAM_ORDER} ) {
	$lexorder = $configs{LEX_NGRAM_ORDER} ;
    }
    if( $lexorder !~ /^\s*(1|2|3|4|5)\s*$/ ) { 
	$lexorder = 4; 
	&MADATools::report("Invalid lexeme ngram order specified in configuration file and/or command line.  Defaulting to lexeme ngram order = 4.","warn",$quiet);
    }
    $configs{LEX_NGRAM_ORDER} = $lexorder;
}


my $diacorder = 1;
if( exists $otherfeatures{ngramdiac} ) {
    if( exists $configs{DIAC_NGRAM_ORDER} ) {
	$diacorder = $configs{DIAC_NGRAM_ORDER} ;
    }
    if( $diacorder !~ /^\s*(1|2|3|4|5)\s*$/ ) { 
	$diacorder = 1; 
	&MADATools::report("Invalid diac ngram order specified in configuration file and/or command line.  Defaulting to diac ngram order = 1.","warn",$quiet);
    }
    $configs{DIAC_NGRAM_ORDER} = $diacorder;
}

my $removetempngramfiles = "yes";
if( exists $otherfeatures{ngramlex} || exists $otherfeatures{ngramdiac} ) {

    if( exists $configs{REMOVE_TEMP_NGRAM_FILES} ) {
	$removetempngramfiles = lc( $configs{REMOVE_TEMP_NGRAM_FILES} );
    }
    if( $removetempngramfiles !~ /^(yes|no)$/ ) { $removetempngramfiles = "yes"; }
    $configs{REMOVE_TEMP_NGRAM_FILES} = $removetempngramfiles;

}

#########################################################################################
#####    INITIALIZE BACKLEX FILE HANDLES, TRAINING DICT, FEATURE VALUE STATISTICS   #####

my ($f, $v); # iterators

my %FH    = ();  # File handles for the backup lexica
my %trainVocab = ();  # words found in training dictionary

if ($SVMtraindict ne ""){

    foreach $f (keys %classifiers){
	$FH{$f}=new FileHandle;
	$FH{$f}->open(">$base.$f.backlex") or die "$0: Error - Can't open $mafile.$f.backlex\n";
    }

    my $trainFH = *TRAIN;
    $trainFH = *TRAIN; ## This is to prevent a pointless warning message
    if( ! &MADATools::openReadFile( $trainFH, $SVMtraindict ) ) {
	die "$0: Error - SVM Training Dictionary file could not be opened: $SVMtraindict\n";
    }

    while ( <$trainFH> ) {
	my @parts = split(/\s+/, $_);
	if( $parts[0] !~ /^\@CARD/ ) {   ## Lines beginning with @CARD are "cardinal" number reps in the SVMTools dictionary
	    $trainVocab{$parts[0]} = $parts[1];
	}
	#  %trainVocab keys are the word, values are the number of times seen in training
	#  The above lines allow for a blank ("") word entry.
    }
    
    close $trainFH;
}



##  Read in backoff lexicon order of feature values
my %backoffLexOrder = ();
my $backoffLexOrderFileH = *BACKLEXORDERFILEH;
$backoffLexOrderFileH = *BACKLEXORDERFILEH; ## This is to prevent a pointless warning message
my $backoffLexOrderFile = "$configs{MADA_HOME}/$configs{MODEL_DIR}/DefaultBackLexFeatureOrders";
if( ! &MADATools::openReadFile( $backoffLexOrderFileH, $backoffLexOrderFile ) ) {
    die "$0: Error - Feature value statistics file could not be opened: $backoffLexOrderFile\n";
}
while( <$backoffLexOrderFileH> ) {
    chomp;
    my @a = split(/\s+/,$_);
    my $feat = shift @a;
    $backoffLexOrder{$feat} = \@a;
}



#foreach $f ( sort keys %backoffLexOrder ) {
#    print "$f:";
#    foreach ( @{ $backoffLexOrder{$f} } ) {  print "\t$_"; }
#    print "\n";
#}




############################################################################################
#####    READ .MA FILE, WRITE .SVMT/BACKLEXES,                   #####
#####    WRITE .NGRAM.IN, RECORD BEST UNIGRAMS, POSSIBLE LEXES   #####

my $lexngramin    = "";
my $lexngrammap   = "";
my $lexngramout   = "";
my $diacngramin   = "";
my $diacngrammap  = "";
my $diacngramout  = "";
my $ngramin    = $mafile . '.ngram.in';
my $ngramfinal = $mafile . '.ngram';

if( exists $otherfeatures{ngramlex} ) {
#    $lexngramin    = $mafile . ".lex-$lextype" . ".$lexorder" . ".ngram.in";
    $lexngrammap   = $mafile . ".lex-$lextype" . ".$lexorder" . ".ngram.map";
    $lexngramout   = $mafile . ".lex-$lextype" . ".$lexorder" . ".ngram.out";
}

if( exists $otherfeatures{ngramdiac} ) {
#    $diacngramin    = $mafile . ".diac.$diacorder" . ".ngram.in";
    $diacngrammap   = $mafile . ".diac.$diacorder" . ".ngram.map";
    $diacngramout   = $mafile . ".diac.$diacorder" . ".ngram.out";
}


my $wordcount=0;

my $maFH = *MAFILE;
$maFH = *MAFILE; ## This is to prevent a pointless warning message
if( ! &MADATools::openReadFile( $maFH, $mafile ) ) {
    	die "$0: Error - .ma file could not be opened: $mafile\n";
}

open(SVMTFILE, ">$svmtfile") || die "$0: Error - .svmt file cound not be opened: $svmtfile\n";


if( exists $otherfeatures{ngramlex} || exists $otherfeatures{ngramdiac} ) {
    if( ! open(NGRAMIN, ">$ngramin") ) {
	&MADATools::report("Temporary Ngram input file cound not be written: $ngramin .  No Ngram information will be used.", "error", $quiet);
	delete $otherfeatures{ngramlex};
	delete $otherfeatures{ngramdiac};
    }
}


if( ! open(NGRAM, ">$ngramfinal") ) {
    &MADATools::report("Final Ngram file cound not be written: $ngramfinal .  No Ngram information will be created.","error",$quiet);
    delete $otherfeatures{ngramlex};
    delete $otherfeatures{ngramdiac};
}




my $mword = MADAWord->new();
my $normword;
my $inputline = "";
my %lexdict = ();
my %diacdict = ();
my %ngramlexes = ();
my %ngramdiacs = ();
my %normwords = ();

my $bestlexscore;
my $bestdiacscore;
my %bls = ();
my %bds = ();
my %lexes;
my %diacs;
my $lex;
my $diac;

while( $mword->readMADAWord( $maFH ) ) {

    if( $mword->isSentenceBreak() ) {

	###  Write the sentence to SRT input file
	$inputline =~ s/\s+$//;
	if( exists $otherfeatures{ngramlex} || exists $otherfeatures{ngramdiac} ) {
	    print NGRAMIN "$inputline\n";
	}
	
	$inputline = "";

    }
    elsif( $mword->isBlankLine() ) {
	next;
	## Skip blank lines
    }
    else {

	$normword = $mword->getNormWord();

	$wordcount++;
	if( ! $quiet ) {
	    print STDERR "[" . $wordcount/1000000 . "M]" if (($wordcount % 50000) == 0);
	    print STDERR "\n"       if (($wordcount % 500000) == 0);
	}
	$normwords{$wordcount} = $normword;
	
	###  Write the word to the SRI .input line
	$inputline .= "$normword ";


	###  Write the correct line to .svmt file
	print SVMTFILE "$normword\n";


	
	###   Write to back lexica, if appropriate

	if ( $SVMtraindict ne "" ) {

	    if (! exists $trainVocab{$normword} || $trainVocab{$normword} == 0 ){
		if( $mword->isNoAnalysis() == 0 && $mword->isPass() == 0 ) {
		    foreach $f (keys %classifiers){
			# Print a line to back lex for a word not found in training dictionary:
			#  Format = WORD NUMVALUES NUMVALUES [FEATURE-VALUE]+
			#my @vals = &MADATools::unique( @{ $mword->getFeatureArray( $f ) } );
			my @vals = ();
			
			##  EDITED TO HANDLE POSCAS
			#if( $f eq "poscas" ) {
			#    my @posArr = @{ $mword->getFeatureArray("pos") };
			#    my @casArr = @{ $mword->getFeatureArray("cas") };
			#    for( my $j=0; $j<=$#posArr; $j++ ) {
			#	push @vals, $posArr[$j] . "__" . $casArr[$j];
			#    }
			#}
			#else {

			@vals = @{ $mword->getFeatureArray( $f ) };
			
                        #}


			my @sources = @{ $mword->getFeatureArray( "source" ) };
			my %valHash = ();
			
			for( my $j=0; $j<=$#vals; $j++ ) {
			    if( $sources[$j] eq "lex" ) {
				$valHash{$vals[$j]} = 200;
			    }
			    elsif( $sources[$j] eq "spvar" ) {
				if( ! exists $valHash{$vals[$j]} ) { 
				    $valHash{$vals[$j]} = 100; 
				}
				elsif( $valHash{$vals[$j]} < 10 ) {   				
				    $valHash{$vals[$j]} = 100; 
				}
			    }
			    else {
				if( ! exists $valHash{$vals[$j]} ) { $valHash{$vals[$j]} = 1; }
			    }			    
			    
			}

			my $val  = scalar( keys %valHash );
			my $tot = 0;
			foreach ( keys %valHash ) {
			    $tot += $valHash{$_};
			}

			my $blout = "";
			#  Edit to reorder values in backup lexicon
			my $q = scalar( @{ $backoffLexOrder{$f} } );
			foreach $v ( @{ $backoffLexOrder{$f} } ) {
			    if( exists $valHash{$v} ) {
				my $p = $valHash{$v} + $q;
				$tot += $q;

				## SVM ":" BUG FIX
				my $capf = uc($f);
				my $anv = $v;
				$anv =~ s/\_//g;

				$blout .= " $capf$anv $p";
				#$blout .= " $f:$v $p";
			    }
			    $q--;

			}
			$FH{$f}->print("$normword $tot $val$blout\n");
			

			# $FH{$f}->print("$normword $tot $val");
			#if( $f eq "cas" ) {
			#    my %order = ( "g" => 5, "n" => 4, "u" => 3, "na" => 2, "a" => 1 );
			#    foreach $v ( keys %order ) {
			#	if( exists $valHash{$v} ) {
			#	    my $p = $valHash{$v} + $order{$v};
			#	    $FH{$f}->print(" $f\:$v $p");
			#	}
			#    }
			#    $FH{$f}->print("\n");
			#}
			#else {
			#    foreach $v (sort keys %valHash ){
			#	$FH{$f}->print(" $f\:$v $valHash{$v}");
			#    }
			#    $FH{$f}->print("\n");
			#}
			
			


		    }
		}
		$trainVocab{$normword}=-1; #add it but mark it.
	    }

	}



	###  Record all possible lexes/diacs for this word

	if( ! exists $lexdict{$normword} && exists $otherfeatures{ngramlex} ) {
	    
	    if( $mword->isNoAnalysis() || $mword->isPass() ) {
		my $k = $normword;
		$lexdict{$normword} = {$k => 1};
	    }
	    else {
		my $a;
		if( $lextype eq 'NORM') { $a = $mword->getFeatureCounts('normlex'); }
		else { $a = $mword->getFeatureCounts('lex'); }
		
		#if( $a =~ /DEFAULT/ ) {
		#    $a .= '_' . $normword;
		#}
		
		$lexdict{$normword} = $a;
	    }
	}


	if( ! exists $diacdict{$normword} && exists $otherfeatures{ngramdiac} ) {

	    if( $mword->isNoAnalysis() || $mword->isPass() ) {
		my $k = $normword;
		$diacdict{$normword} = {$k => 1};
	    }
	    else {
		my $a = $mword->getFeatureCounts('diac');		
		$diacdict{$normword} = $a;
		#print STDERR "$0: NOTE - Adding $normword to diacdict:  $a\n";
	    }


	}



    }



}

if( ! $quiet ) {
    print STDERR "\n";
}

###  Close file handles
if( exists $otherfeatures{ngramlex} || exists $otherfeatures{ngramdiac} ) {
    close(NGRAMIN);
}


close($maFH);
close(SVMTFILE);
if ($SVMtraindict ne ""){
    foreach $f (keys %classifiers){
	$FH{$f}->close;
    }
}






##################################################################################
#####     BUILD MAP FILES IF NEEDED     #####

if( exists $otherfeatures{ngramlex} ) {
    open(LEXNGRAMMAP, ">$lexngrammap");
    if( ! -w LEXNGRAMMAP ) {
	&MADATools::report("Unable to write map file $lexngrammap .  No Lexeme Ngram information will be created.", "error", $quiet);
	delete $otherfeatures{ngramlex};	
    }
    else {
	foreach $normword ( sort keys %lexdict ) {
	    my $ref = $lexdict{$normword};

#	    my $tot = 0;
#	    foreach( keys %{ $ref } ) { $tot += $ref->{$_}; }
#	    if( $tot == 0 ) { $tot = 1; }
	    
#           OLD STYLE:  Didn't do anything helpful
#	    my $n = scalar( keys %{ $ref } );
#	    if( $n != 0 ) {
#		$n = 1 / $n;
#	    }

	    my $line = "$normword ";
	    my $key;
	    foreach $key ( sort keys %{ $ref } ) {
#		my $n = $ref->{$key} / $tot;
		if( $key =~ /\d/ ) {
		    $key =~ s/\d/8/g;
		}
		#$line .= "$key $n ";
		$line .= "$key ";
	    }
	    $line =~ s/\s*$//;
	    
	    print LEXNGRAMMAP "$line\n";
	
	}
    }
    close LEXNGRAMMAP;
}


if( exists $otherfeatures{ngramdiac} ) {
    open(DIACNGRAMMAP, ">$diacngrammap");
    if( ! -w DIACNGRAMMAP ) {
	&MADATools::report("Unable to write map file $diacngrammap .  No Diac Ngram information will be created.","error",$quiet);
	delete $otherfeatures{ngramdiac};	
    }
    else {
	foreach $normword ( sort keys %diacdict ) {
	    my $ref = $diacdict{$normword};

#	    my $tot = 0;
#	    foreach( keys %{ $ref } ) { $tot += $ref->{$_}; }
#	    if( $tot == 0 ) { $tot = 1; }
	    
#           OLD STYLE:  Didn't do anything helpful
#	    my $n = scalar( keys %{ $ref } );
#	    if( $n != 0 ) {
#		$n = 1 / $n;
#	    }


	    my $line = "$normword ";
	    my $key;
	    foreach $key ( sort keys %{ $ref } ) {
		#my $n = $ref->{$key} / $tot;

		if( $key =~ /\d/ ) {
		    $key =~ s/\d/8/g;
		}
		#$line .= "$key $n ";
		$line .= "$key ";
	    }
	    $line =~ s/\s*$//;
	    
	    print DIACNGRAMMAP "$line\n";
	
	}
    }
    close DIACNGRAMMAP;
}


##################################################################################
#####     RUN SRI NGRAM TOOL IF NEEDED     #####

if( exists $otherfeatures{ngramlex} ) {

    my $lm;
    if( $lextype eq "BAMA" ) {
	$lm = $ngramLMdir . '/MADA-train.lexes.5.lm';
    }
    else {
	$lm = $ngramLMdir . '/MADA-train.normlexes.5.lm';    
    }
	
    #my $cmd = "$SRIngramtool -scale -keep-unk -text $ngramin -map $lexngrammap -order $lexorder -lm $lm > $lexngramout";
    my $cmd = "$SRIngramtool -keep-unk -text $ngramin -map $lexngrammap -order $lexorder -lm $lm > $lexngramout";
    if( ! $quiet ) {
	print STDERR "Developing lexeme ngrams\n";
    }
    #print STDERR "  $cmd\n";
    system($cmd);
}

if( exists $otherfeatures{ngramdiac} ) {

    my $lm = $ngramLMdir . '/MADA-train.diacs.5.lm';        	
    #my $cmd = "$SRIngramtool -scale -keep-unk -text $ngramin -map $diacngrammap -order $diacorder -lm $lm > $diacngramout";
    my $cmd = "$SRIngramtool -keep-unk -text $ngramin -map $diacngrammap -order $diacorder -lm $lm > $diacngramout";
    if( ! $quiet ) {
	print STDERR "Developing diac ngrams\n";
    }
    #print STDERR "  $cmd\n";
    system($cmd);
    if( ! $quiet ) {
	print STDERR "\n";
    }
}


##################################################################################
#####     SCAN SRI .OUT FILES  IF NEEDED     #####

if( exists $otherfeatures{ngramlex} ) {

    my $outFH = *OUTFILE;
    $outFH = *OUTFILE; ## This is to prevent a pointless warning message
    if( ! &MADATools::openReadFile( $outFH, $lexngramout ) ) {
	&MADATools::report("Unable to read output file of SRI tool $SRIngramtool: $lexngramout .  No Lexeme Ngram information will be created.","error",$quiet);
	delete $otherfeatures{ngramlex};
    }
    else {
	my $line;
	my $count = 0;
	my $lex;
	while( $line = <$outFH> ) {
	    chomp $line;
	    foreach $lex ( split(/\s+/, $line) ) {
		if( $lex eq '<s>' || $lex eq '</s>' ) {
		    next;
		}
		else {
		    $count++;
		    $ngramlexes{$count} = $lex;
		}
	    }
	}	
    }

    close( $outFH );
}

if( exists $otherfeatures{ngramdiac} ) {

    my $outFH = *OUTFILE;
    $outFH = *OUTFILE; ## This is to prevent a pointless warning message
    if( ! &MADATools::openReadFile( $outFH, $diacngramout ) ) {
	&MADATools::report("Unable to read output file of SRI tool $SRIngramtool: $diacngramout .  No Diac Ngram information will be created.","error",$quiet);
	delete $otherfeatures{ngramdiac};
    }
    else {
	my $line;
	my $count = 0;
	my $diac;
	while( $line = <$outFH> ) {
	    chomp $line;
	    foreach $diac ( split(/\s+/, $line) ) {
		if( $diac eq '<s>' || $diac eq '</s>' ) {
		    next;
		}
		else {
		    $count++;
		    $ngramdiacs{$count} = $diac;
		}
	    }
	}	
    }

    close( $outFH );
}


##################################################################################
#####     WRITE FINAL .NGRAM FILE     #####


print NGRAM "## Ngram information file derived from input file $mafile\n";
print NGRAM "## Lexeme type = $lextype  Higher-order Lexeme order = $lexorder\n";
#print NGRAM "## Format:  WordNumber  NormalizedWord  #ofUnigramLexes  #ofUnigramDiacs  #ofNgramLexes  (Unigram Lexes)  (Unigram Diacs)  (Ngram Lexes)\n";
print NGRAM "## Format:  WordNumber  NormalizedWord  #ofNgramLexes  #ofNgramDiacs  (Ngram Lexes)  (Ngram Diacs)\n";
print NGRAM "##\n";

my $wc;
my $line;
foreach $wc ( sort { $a <=> $b } keys %normwords ) {
    
    my ($nnl, $nnd);
    my ($nlex, $ndiac);
    

    
    if( ! exists $ngramlexes{$wc} ) { # %ngramlexes will be empty if ngramlex was not requested
	$nnl = 0; 
	$nlex = "---";
    }
    else{ $nnl = 1; $nlex = $ngramlexes{$wc}; }


    if( ! exists $ngramdiacs{$wc} ) { # %ngramlexes will be empty if ngramlex was not requested
	$nnd = 0; 
	$ndiac = "---";
    }
    else{ $nnd = 1; $ndiac = $ngramdiacs{$wc}; }
 
   
    $line = "$wc\t$normwords{$wc}\t$nnl\t$nnd\t$nlex\t$ndiac";
    
#    if( $nnl > 0 ) { $line .= $nlex; }
#    if( $nnd > 0 ) { $line .= "\t$ndiac"; }
   
    print NGRAM "$line\n";
    
}
   
close NGRAM;





if( $removetempngramfiles eq 'yes' ){

    unlink( $ngramin, $lexngramout, $lexngrammap, $diacngramout, $diacngrammap );
}


if( ! $quiet ) {
    print STDERR "Done.\n";
}

##################################################################################

sub printUsage {

    print "\nUsage: $0 config=<.madaconfig file> file=<.ma file> [quiet] [other variables]\n\n";
    print "  Output is produced in <.ma file>.svmt, <.ma file>.FEATURE.backlex, \n";
    print "  and <.ma file>.ngrams. Both the config file and the .ma file must be\n";
    print "  specified.\n\n";

    print "  If quiet is included on the command line, all informational and warning messages will be\n";
    print "   repressed.\n\n";

    print "  The other variables are optional, and can be any of the following,\n";
    print "  specified in VARIABLE=VALUE format:\n\n";
    print "    MADA_HOME=<directory location of MADA installation>\n";
    print "    MODEL_DIR=<SVM Model directory location relative to MADA_HOME>\n";
    print "    CLASSIFIERS=\"list of classifers, separated by spaces, in quotes\"\n";
    print "    LEXEME_TYPE=[BAMA|NORM]\n";
    print "    LEX_NGRAM_ORDER=[1|2|3|4|5]\n";
    print "    DIAC_NGRAM_ORDER=[1|2|3|4|5]\n";
    print "    SRI_NGRAM_TOOL=<absolute location of SRI's disambig executable>\n";
    print "    REMOVE_TEMP_LEX_NGRAM_FILES=[YES|NO]\n";
    print "    NGRAM_LM_DIRECTORY=<location of the directory containing the ngram language models, relative to MADA_HOME>\n";
    print "    OTHER_FEATURES=\"quoted, space-separated list of other features used in scoring analyses\"\n\n";
    print "  If any of the above options is specified on the command line, the\n";
    print "  command line value will be used instead of the value indicated in the\n";
    print "  .madaconfig file. All other options will be ignored. For a more\n";
    print "  detailed description of each variable, consult your .madaconfig file.\n\n";
	
}








