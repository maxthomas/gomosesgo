#! /usr/bin/perl

use strict;
use warnings;
use MADA::MADAWord;

############################################################
# extractFeaturesIntoColumns.pl
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
##  It reads a .ma or .mada file, and is given 
##  a comma separated list of features.
##  It then creates a tab-separated column, formated like so:
##
##  <word>  <feat1>  <feat2> ....
##
##  Sentence breaks are represented by empty lines. The
##  <word> is always included as the first column, and
##  the first line of the output consists of column headers.
##
##  This is an easy way of extracting a general list of 
##  disambiguated features from the output of MADA.
##
##  Run "perl extractFeaturesIntoColumns.pl" for usage
##  information.
##
############################################################

my %mostlikely = ( asp => "na", cas => "na", enc0 => "0", gen => "m", 
		   mod => "na", num => "s", per => "na", pos => "noun",
		   prc0 => "0", prc1 => "0", prc2 => "0", prc3 => "0", 
		   stt => "na", vox => "na"  );

my $file = "";
my $featlist = "";
my $sentids = 0;


foreach( @ARGV ) {
    
    if( /file=(\S+)/ ) { $file = $1; }
    elsif( /feats=(\S+)/ ) { $featlist = lc( $1 ); }
    elsif( /^(sentid|sentids)$/i ) { $sentids = 1; }

}

if( $file eq "" || $featlist eq "" ) {
    &printUsage();
    exit();
}

my @feats = split(/\,/, $featlist );




my %printoptions = ( filehandle => *STDOUT );
my %list = ();
my $word;
my $id = "";
my $out = "";
my ($f,$v);

$out = "\#\#WORD";
foreach $f (@feats) {
    $out .= "\t$f";
}
print "$out\n";
$out = "";

my $mword = MADAWord->new();         # Creates an empty MADAWord object
if( $file =~ /\.gz$/ ) {
    open(FH, "gzip -f -c -d $file |") || die "Error : Unable to open $file for reading\n";
}
else {
   open(FH, "$file") || die "Error : Unable to open $file for reading\n";
}


while( $mword->readMADAStars(*FH) ) {

    $word = $mword->getWord();

    if( $mword->isSentenceBreak() ) {
	print "\n";
	$id = "";
    }
     elsif( $mword->isNoAnalysis() || $mword->isPass() || $mword->isBlankLine() ) {
	if( $sentids && $id eq "" ) {
	    $id = $mword->getComment("SENTENCE_ID");
	    $id =~ s/^;;+\s*SENTENCE_ID\s*//;
	    print "\#\# $id\n";
	}


	if( $mword->isBlankLine() ) { $word = "UNK"; }

	$out = "$word";
	foreach $f (@feats ) {
	    if( exists $mostlikely{$f} ) {
		$v = $mostlikely{$f};
	    }
	    elsif( $f =~ /^(lex|normlex|normlexeme|gloss|diac)$/ ) {
		$v = $word;
	    }
	    elsif( $f =~ /^noanalysis$/ ) {
		$v = "NO";
	    }
	    else { 
		$v = "UNK"; ## Unknown feature value
	    }
	    
	    $out .= "\t$v";
	}
	print "$out\n";
	$out = "";

    }
    else {
	if( $sentids && $id eq "" ) {
	    $id = $mword->getComment("SENTENCE_ID");
	    $id =~ s/^;;+\s*SENTENCE_ID\s*//;
	    print "\#\# $id\n";
	}

	$out = "$word";
	
	foreach $f (@feats) {

	    if( $f eq "normlex" ) {
		$v = $mword->getNormLex(0);
	    }
	    elsif( $f eq "word" ) {
		$v = $word;
	    }
	    elsif( $f eq "normword" ) {
		$v = $mword->getNormWord();
	    }
	    elsif( $f eq "noanalysis" ) {
		$v = "YES";
	    }
	    else {
		$v = $mword->getFeature($f,0);
	    }
	    if( $v eq "" ) { 
		$v = "UNK"; 
	    }
	    $out .= "\t$v";

	}
	print "$out\n";
	$out = "";
    }
}
close(FH);




sub printUsage {

    print "perl $0  file=<.ma or .mada file> feats=<comma-separated list of MADA features> [sentids]\n\n";
    print "  Possible features = (word|normword|asp|bw|cas|enc0|diac|gen|gloss|mod|num|lex|per|\n";
    print "                       pos|prc0|prc1|prc2|prc3|stt|vox|normlex|normlexeme|noanalysis)\n\n";

    print "Output is in the format:\n";
    print "  <word>\t<feat1>\t<feat2>\t....\n\n";
    print "Sentence Breaks are indicated with empty lines.\n";
    print "If sentids is added to the command line, any sentence IDs found in the .mada file will be added\n";
    print "   prior to the first word in each sentence, as a comment starting with \#\#\n";
    print "The <word> is always included as the first column, and the first line of the output consists of\n";
    print "   column headers starting with \#\#\n\n";

}
