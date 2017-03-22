#! /usr/bin/perl

use strict;
use warnings;
use MADA::MADAWord;
use MADA::MADATools;

$| = 1;

############################################################
# extractFeatureIntoSentenceFormat.pl
# Copyright (c) 2008,2009,2010 Columbia University in 
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
##  It reads scored .mada file, and is given 
##   a particular feature. The script reads the
##   .ma or .mada file and prints out the specific
##  feature for each starred word in a sentence form. 
##  This can be useful for getting, for example, a string
##  of the english gloss entries as a basic translation, or
##  a sentence composed of the lexemes of the words, or a
##  diacritized version of the sentence.
##
##
##  Run "perl extractFeatureIntoSentenceFormat.pl" for usage information
############################################################

my $file = "";
my $feat = "";
my $includeword = 0;

my %features = ( asp => 1, bw => 1, cas => 1, diac => 1, enc0 => 1, 
		 #enc1 => 1, enc2 => 1, 
		 gen => 1, gloss => 1, lex => 1, mod => 1, num => 1, 
		 per => 1, pos => 1,
		 prc0 => 1, prc1 => 1, prc2 => 1, prc3 => 1, 
		 #rat => 1, 
		 stt => 1, vox => 1,
                 normlexeme=>1, normlex=>1, noanalysis => 1, 
		 word => 1, normword => 1);

my %mostlikely = ( asp => "na", cas => "na", enc0 => "0", gen => "m", 
		   mod => "na", num => "s", per => "na", pos => "noun",
		   prc0 => "0", prc1 => "0", prc2 => "0", prc3 => "0", 
		   stt => "na", vox => "na"  );

my $normdigit = 0;
my $normalefyaa = 0;
my $sentids = 0;
my $normlat = 0;

foreach( @ARGV ) {
    
    if( /file=(\S+)/ ) { $file = $1; }
    elsif( /feat=(\S+)/ ) { $feat = lc($1); }
    elsif( /includeword/i ) { $includeword = 1; }
    elsif( /normdigit/i ) { $normdigit = 1; }
    elsif( /normalefyaa/i ) { $normalefyaa = 1; }
    elsif( /sentids/i )     { $sentids = 1; }
    elsif( /normlat/i )     { $normlat = 1; }

}

if( $file eq "" || $feat eq "" ) {
    &printUsage();
    exit();
}

if( ! exists $features{$feat} ) {
    print "Specified feature $feat is not one of the MADA features.\n";
    exit();
 }


my $val;
my $out = "";
my $word;
my $normword;

my $id = "";

my $mword = MADAWord->new();         # Creates an empty MADAWord object

if( $file =~ /\.gz$/ ) {
    open(FH, "gzip -f -c -d $file |") || die "Error : Unable to open $file for reading\n";
}
else {
   open(FH, "$file") || die "Error : Unable to open $file for reading\n";
}

#open(FH, '<', $file);

my $wc = 0;
my $sc = 0;

while( $mword->readMADAStars(*FH) ) {
    
    $word = $mword->getWord();
    $normword = $mword->getNormWord();

    if( $mword->isSentenceBreak() ) {
	$out =~ s/\s+$//;
	$sc++;
	$wc = 0;

	if( $id ne "" ) {
	    print "$id $out\n";
	}
	else {
	    print "$out\n";
	}


	$out = "";
	$id = "";
	#exit(0);
    }
    elsif ( $mword->isNoAnalysis() || $mword->isPass() ) {

	$wc++;
	if( $sentids  && $id eq "" ) {
	    $id = $mword->getComment("SENTENCE_ID");
	    $id =~ s/^;;+\s*SENTENCE_ID\s*//;
	}
	
	if( $includeword  ) {
	    $out .= "$word\:";
	}

	if( $feat eq "noanalysis" ) {
	    $val = "NO";
	}
	elsif( $feat eq "word" ) {
	    $val = $word;
	    if( $normlat && $word =~ /^\@\@LAT\@\@/ ) {
		$val = "\@\@LAT\@\@";
	    } elsif( $normalefyaa ) {
		$val =~ s/Y/y/g; 
		$val =~ s/[><\|A\{]/A/g;
	    }

	}
	elsif( $feat eq "normword" ) {
	    $val = $normword;
	    if( $normlat && $word =~ /^\@\@LAT\@\@/ ) {
		$val = "\@\@LAT\@\@";
	    }
	}
	elsif( exists $mostlikely{$feat} ) {
	    $val = $mostlikely{$feat};
	}
	elsif( $feat =~ /^(lex|normlex|normlexeme|gloss|diac)$/ ) {
	    $val = $word;
	    if( $normlat && $word =~ /^\@\@LAT\@\@/ ) {
		$val = "\@\@LAT\@\@";
	    } elsif( $normalefyaa && $feat ne "gloss") {
		$val =~ s/Y/y/g; 
		$val =~ s/[><\|A\{]/A/g;
	    }


	}
	else { 
	    $val = "UNK"; ## Unknown feature value
	}

	#print STDERR "FOUND NO ANALYSIS : $word\n";
	$out .= "$val ";
    }
    else {
	$wc++;
	if( $sentids && $id eq "" ) {
	    $id = $mword->getComment("SENTENCE_ID");
	    $id =~ s/^;;+\s*SENTENCE_ID\s*//;
	}

	if( $includeword ) {
	    $out .= "$word\:";
	}
	
	if( $feat eq "noanalysis" ) {
	    $val = "YES";
	}
	elsif( $feat eq "word" ) {
	    $val = $word;
	    if( $normalefyaa ) {
		$val =~ s/Y/y/g; 
		$val =~ s/[><\|A\{]/A/g;
	    }
	}
	elsif( $feat eq "normword" ) {
	    $val = $normword;
	}
	else {
	    $val = $mword->getFeature($feat,0);
	    if( $val eq "" && ! $mword->isBlankLine() ) {
		print STDERR "Unable to determine feature $feat for word $wc [$word] in sentence $sc\n";
		#exit(0);
	    }

	    if( $normdigit && $feat eq "lex") {
		$val =~ s/(\_\d+)$//;
		my $tail = $1;
		$val =~ s/\d/8/g;
		if( defined $tail ) {
		    $val .= $tail;
		}
	    }
	    elsif( $normdigit ) { 
		$val =~ s/\d/8/g; 
	    }

	    if( $normalefyaa && $feat =~ /lex|diac/ ) {
		$val =~ s/Y/y/g; 
		$val =~ s/[><\|A\{]/A/g;
	    }
	    
	}

	$out .= "$val ";

    }



}
close(FH);




sub printUsage {

    print "perl $0  file=<.ma or .mada file> feat=<MADA feature> [includeword normdigit normalefyaa normlat sentids]\n\n";
    print "  feature = (word|normword|asp|bw|cas|diac|enc0|gen|gloss|lex|mod|\n";
    print "             num|per|pos|prc0|prc1|prc2|prc3|stt|vox|normlex|normlexeme|noanalysis)\n\n";

    print "If includeword is an argument, the format will be in \"word:feature word:feature ...\" format.\n";
    print "if sentids is an argument, any sentence ID in the MADA file will be placed at the front of the output line.\n";
    print "If normdigit is an argument, all digits in output will be replaced with \"8\"\n";
    print "If normalefyaa is an argument, all alefs, yaas in output will be normalized to \"A\" and \"y\"\n";
    print "  The normdigit and normalefyaa arguments only activate if the feat is lex, normlex or diac.\n";
    print "  These arguments also only affect the printed values, not the Word if includeword is active.\n";
    print "If normlat is an argument and the feat is word, normword, lex, normlex, gloss or diac, all \@\@LAT\@\@ tagged\n";
    print "  words will be reduced to \@\@LAT\@\@ only (without the actual word).\n\n";
    print "Output is one-sentence-per-line format.\n\n";


}

