#! /usr/bin/perl

$| = 1;
use strict;
use warnings;
use MADA::MADATools;
use FileHandle;
 

#######################################################################
# TOKAN-evaluate.pl -- General tokenizer updated to work with ALMOR3
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
# This script, given a evaluation type (which defines the TOKAN_SCHEME
# to use) and two *.mada files (one test and one gold), will apply the 
# tokenization to each word, compare the results, and output an overall
# score rating how well the tokenization matches.
#
#######################################################################

#######################################################################
##### READ COMMAND LINE  #####


my $cmdline = &MADATools::readCommandLine( @ARGV );

if( ! exists $cmdline->{CONFIG} ) {
    &printUsage();
    die "$0: Error - configuration file not specified in command line \n";
}
if( ! exists $cmdline->{FILE} && ! exists $cmdline->{FILETOK} ) {
    &printUsage();
    die "$0: Error - MADA output file or TOKAN file to process not specified in command line \n";
}
if( ! exists $cmdline->{GOLD} && ! exists $cmdline->{GOLDTOK} ) {
    &printUsage();
    die "$0: Error - Gold MADA output file or TOKAN file to process not specified in command line \n";
}


my $madafile = "";
my $tokfile = "";
if( exists $cmdline->{FILE} ) {
    $madafile = $cmdline->{FILE};
    if( ! -e $madafile ){ 
	die "$0: Error - MADA file to evaluate ($madafile) does not exist.\n";
    }
}
if( exists $cmdline->{FILETOK} ) {
    $tokfile = $cmdline->{FILETOK};
    if( ! -e $tokfile ) {
	die "$0: Error - TOKAN file to evaluate ($tokfile) does not exist.\n";
    }
}


my $goldfile = "";
my $gtokfile = "";
if( exists $cmdline->{GOLD} ) {
    $goldfile = $cmdline->{GOLD};
    if( ! -e $goldfile ) {
	die "$0: Error - Gold MADA file ($goldfile) does not exist.\n";
    }
}
if( exists $cmdline->{GOLDTOK} ) {
    $gtokfile = $cmdline->{GOLDTOK};
    if( ! -e $gtokfile ) {
	die "$0: Error - Gold TOKAN file ($gtokfile) does not exist.\n";
    }
}

if( $goldfile eq "" && $gtokfile eq "") {
    die "$0: Error - Gold file to evaluated against not specified.\n";
}
if( $madafile eq "" && $tokfile eq "" ) {
    die "$0: Error - File to evaluate not specified.\n";
}

my $config   = $cmdline->{CONFIG};

my $evaltype = "simpleatb";
if( exists $cmdline->{EVALTYPE} ) {
    $evaltype = lc( $cmdline->{EVALTYPE} );
}
if( $evaltype !~ /^simpleatb|simpled3$/ ) {
    &printUsage();
    die "$0: Error - Specified evaluation type ($evaltype) unrecoginzed\n";
}

my $clean = 0;
if( exists $cmdline->{CLEAN} ) {
    $clean = 1;
}

my $printerrs = 0;
if( exists $cmdline->{PRINTERRS} ) {
    $printerrs = 1;
}



# Read configuration file
my %configs = %{ &MADATools::readConfig($config) }; 
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
my $home = $configs{MADA_HOME};

my $sentID=0;
if( exists $configs{SENTENCE_IDS} ) {
    $sentID = lc( $configs{SENTENCE_IDS} );
    if( $sentID =~ /^yes$/ ) { $sentID = 1; }
    else{ $sentID = 0; }
}
$configs{SENTENCE_IDS} = $sentID;


#######################################################################
# Pick Scheme to use
#######################################################################

my $scheme= ""; 
if( $evaltype =~ /^simpleatb$/ ) {
    $scheme = "SCHEME=ATB GROUPTOKENS";
} elsif( $evaltype =~ /^simpled3$/ ) {
    $scheme = "SCHEME=D3 GROUPTOKENS";
}

my ($args, $gargs);
$args  = "config=$config file=$madafile"; 
$gargs = "config=$config file=$goldfile";

my ($ftokext, $gtokext) = ("$evaltype".".tok", "$evaltype".".gtok");


my $f = $madafile;
$f =~ s/\.gz//;
$f .= ".$ftokext";
my $g = $goldfile;
$g =~ s/\.gz//;
$g .= ".$gtokext";


$args  .= " TOKAN_OUTPUT_EXTENSION=$ftokext  TOKAN_SCHEME=\"$scheme\" ";
$gargs .= " TOKAN_OUTPUT_EXTENSION=$gtokext  TOKAN_SCHEME=\"$scheme\" ";

foreach my $ar ( @ARGV ) {
    #print STDERR "Examining $ar\n";
    if( $ar !~ /^(clean|printerrs|config\=|file(tok)?\=|gold(tok)?\=|TOKAN_SCHEME\=|TOKAN_OUTPUT_EXTENSION\=)/i ) {
	$ar =~ /^([^\=]+\=)(.+)$/;
	my $var = $1;
	my $val = $2;
	if( $val =~ /\s/ ) { $val = "\"$val\""; } # Add quotes if needed
	$args .= " $var" . $val;
	$gargs.= " $var" . $val;
    }
}


#######################################################################
#   Run TOKAN
#######################################################################

my $cmd;

if( $madafile ne "" ) {
    $cmd = "perl $home/TOKAN.pl $args";
    print STDERR "Running TOKAN on $madafile ...\n";
    print STDERR "  $cmd\n";
    system($cmd);
} else {
    $f = $tokfile;
    $madafile = $tokfile;
} 

if( ! -e $f ) {
    die "$0: Error -- Failed to create output file $f \n";
}

if( $goldfile ne "" ) {
    $cmd = "perl $home/TOKAN.pl $gargs";
    print STDERR "Running TOKAN on $goldfile ...\n";
    print STDERR "  $cmd\n";
    system($cmd);
} else {
    $g = $gtokfile;
    $goldfile = $gtokfile;
}

if( ! -e $g ) {
    die "$0: Error -- Failed to create output file $g \n";
}

#######################################################################
#   Compare Outputs
#######################################################################

open(FTOK, $f) || die "$0: Error - Unable to read TOKAN output $f \n";
open(GTOK, $g) || die "$0: Error - Unable to read TOKAN output $g \n";

my $line;
my $gline;
my $nsent  = 0;
my $gnsent = 0;
my $nwords  = 0;
my $gnwords = 0;

my $ncorrw = 0;
my $ncorrwnorm = 0;
my $ncorrs = 0;
my $ncorrsnorm = 0;

my $ncorrseg = 0;

my $numtokc = 0;
my $numsenttokc = 0;

my $err = 0;
my ($tokp, $gtokp);

my @errtypes = (0,0,0,0);

if( $printerrs ) {
    print "Error Listing:\n";
    printf "%8s %8s %20s %20s %12s\n", "SENT#", "WORD#", "GOLDTOK", "FILETOK", "ERRTYPE";

}

while( $line = <FTOK>  ) {
    $gline = <GTOK>;
    if( ! defined $gline ) {
	die "$0: Error - Misalignment in number of lines (# test > # gold lines)\n";
    }
    chomp $line;
    chomp $gline;    
    my @toks  = split(/\s+/, $line);
    my @gtoks = split(/\s+/, $gline);

    if( $sentID ) {
	my $id  = shift @toks;
	my $gid = shift @gtoks;
	if( $id ne $gid ) {
	    die "$0: Error - Misalignment in Sent ID:  $id vs. $gid\n";
	}
    }
    if( scalar( @toks ) != scalar( @gtoks )  ) {
	my $d = scalar( @toks );
	my $e = scalar( @gtoks );
	die "$0: Error - Misalignment in number of words:  $nsent sentence, $d vs $e \n";
    }


    $nsent++;
    if( $line eq $gline ) { $ncorrs++; }
    if( &normAYDP($line) eq &normAYDP($gline) ) { $ncorrsnorm++; }

    my @t = split(/[\s\_]+/, $line );
    my @g = split(/[\s\_]+/, $gline );
    if( scalar( @t ) == scalar( @g ) ) {
	$numsenttokc++;
    }


    for( my $i=0; $i<=$#toks; $i++) {
	$nwords++;
	$err = 0;
	if( $toks[$i] eq $gtoks[$i] ) {
	    $ncorrw++;
	} else {
	    $tokp = $toks[$i];
	    $gtokp = $gtoks[$i];
	    $tokp =~ s/[\+\_]//g;
	    $gtokp =~ s/[\+\_]//g;
	    if( $tokp ne $gtokp ) {
		$err += 1;
	    }
	}

	$tokp = &normAYDP( $toks[$i] );
	$gtokp = &normAYDP( $gtoks[$i] );
	if( $tokp eq $gtokp ) {
	    $ncorrwnorm++;
	}

	$tokp = $toks[$i];
	$gtokp = $gtoks[$i];
	$tokp =~ s/[^\+\_]+/X/g;
	$gtokp =~ s/[^\+\_]+/X/g;
	if( $tokp eq $gtokp ) {
	    $ncorrseg++;
	} else {
	    $err += 2;
	}
	
	if( $printerrs ) {
	    if( $err == 1 ) {
		printf "%8d %8d %20s %20s %12s\n", $nsent, $i+1, $gtoks[$i], $toks[$i], "SPELL";
	    } elsif ( $err == 2 ) {
		printf "%8d %8d %20s %20s %12s\n", $nsent, $i+1, $gtoks[$i], $toks[$i], "SEG";
	    } elsif ( $err == 3 ) {
		printf "%8d %8d %20s %20s %12s\n", $nsent, $i+1, $gtoks[$i], $toks[$i], "SPELL+SEG";
	    }
	}

	$errtypes[$err]++;

    }


}

$gline = <GTOK>;
if( defined $gline ) {
    die "$0: Error - Misalignment in number of lines (# test < # gold lines)\n";
}

close(FTOK);
close(GTOK);


print "------------------------------------------------------------------------\n";
print "File Evaluated  : $madafile \n";
print "Gold Standard   : $goldfile \n";
print "Evaluation type : $evaltype ($scheme)\n\n";

print "Number of sents : $nsent \n";
print "Number of words : $nwords \n";

my $acc = 0;
if( $nwords > 0 ){
    $acc = 100 * ($ncorrw / $nwords);
}
printf "Words with Perfect tokenization         =  %10d (%8.3f %% )\n", $ncorrw, $acc;
printf "Words with Tokenization Errors          =  %10d (%8.3f %% )\n\n", ($nwords - $ncorrw), 
    (100 - $acc);

$acc = 0;
if( $nsent > 0 ) {
    $acc = 100 * ($ncorrs/$nsent);
}
printf "Sents with Perfect tokenization         =  %10d (%8.3f %% )\n", $ncorrs, $acc;
printf "Sents with Tokenization Errors          =  %10d (%8.3f %% )\n\n", ($nsent - $ncorrs), 
    (100 - $acc);

$acc = 0;
if( $nwords > 0 ){
    $acc = 100 * ($ncorrseg / $nwords);
}
printf "Words with Matching Segmentation        =  %10d (%8.3f %% )\n", $ncorrseg, $acc;
printf "Words with Segmentation errors          =  %10d (%8.3f %% )\n\n", ($nwords - $ncorrseg), 
    (100 - $acc);


$acc = 0;
if( $nwords > 0 ){
    $acc = 100 * ($ncorrwnorm / $nwords);
}
printf "Words with Matching Tok (norm A/Y/D/P)  =  %10d (%8.3f %% )\n", $ncorrwnorm, $acc;

$acc = 0;
if( $nsent > 0 ) {
    $acc = 100 * ($ncorrsnorm/$nsent);
}
printf "Sents with Matching Tok (norm A/Y/D/P)  =  %10d (%8.3f %% )\n\n", $ncorrsnorm, $acc;


if( $nwords > 0 ) {
    print "Word Err Types:\n";
    printf "No Errors                           =  %10d (%8.3f %% )\n", $errtypes[0], 
    100*($errtypes[0]/$nwords);
    printf "Spelling Errors                     =  %10d (%8.3f %% )\n", $errtypes[1],
    100*($errtypes[1]/$nwords);
    printf "Segmentation Errors                 =  %10d (%8.3f %% )\n", $errtypes[2],
    100*($errtypes[2]/$nwords);
    printf "Spelling and Segmentation Errors    =  %10d (%8.3f %% )\n", $errtypes[3],
    100*($errtypes[3]/$nwords);
}


print "\n\n";



#######################################################################
#   clean up
#######################################################################

if( $clean ) {
    print STDERR "Removing temporary TOKAN outputs.\n";
    unlink($f);
    if( $gtokfile eq "" ) {
	unlink($g);
    }
}






sub printUsage {

    print "\nUsage: $0 config=<.madaconfig file> [file=<.mada output file> || filetok=<TOKAN output file> ]\n";
    print "     [gold=<gold .mada file> || goldtok=<gold tok file> ] [evaltype=[simpleatb|simpled3]] [clean] [printerrs] \n\n";

}




sub normAYDP {
    my ($word) = @_;

    $word =~ s/p/h/g;
    $word = &MADATools::normalizeWord($word);

    return $word;
    
}
