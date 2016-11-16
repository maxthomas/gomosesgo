#! /usr/bin/perl

$| = 1;
use strict;
use warnings;
use File::Spec;

########################################################################
# INSTALL.pl
# Copyright (c) 2010-2012 Columbia University in 
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
########################################################################
#
# This script is meant to automate some of the tasks that should be
# done when MADA is first installed.  It does the following:
#
# 0) Verifies that the user has installed SRILM and SVMTools, and
#    added SVMTools and MADA to his PERL5LIB
# 1) Runs XAMA-to-ALMOR3.pl to generate an ALMOR database file
# 2) Generates an example .madaconfig file appropriate to the user's
#    system (i.e., with the MADA_HOME, SVM_TAGGER and SRI_NGRAM_TOOL
#    variables set correctly)
# 3) Runs MADA on a small test file to verify the installation is correct
#
#
# This script requires that the user provide the following:
#
#   A) The directory where MADA is installed
#   B) The location of the SRILM tool 'disambig'
#   C) The directory of SVMTools
#   D) The directory containing the XAMA to use for ALMOR
#   E) The version of XAMA being used
#
# 
# Usage:  perl INSTALL.pl \\
#              madahome=<MADA directory> \\
#              srihome=<SRI home directory> \\
#              svmhome=<SVMTools home directory> \\
#              xamadir=<directory containing XAMA dict* and table* files> \\
#              [ xamaversion=(SAMA3.1|SAMA3.0|BAMA2.0|ARAMORPH1.2.1) ]
#
# The madahome directory is the top-level directory of MADA, where this INSTALL.pl
#    script is located.
#
# The srihome directory is the top-level directory of the SRILM toolkit installation.
#
# The svmhome directory is the top-level directory of the SVMTool installation
#    We STRONGLY recommend that you upgrade to SVMTools 1.3.1 if you have not done so.
#
# XAMA is a shorthand for referring to BAMA or SAMA collections.
# The specified xamahome directory should contain 6 files named dictPrefixes, 
#    dictStems, dictSuffixes, tableAB, tableAC and table BC. In SAMA-3.1, this
#    directory is located at <SAMA 3.1 home directory>/lib/SAMA_DB/v3_1/
#
# For the xamaversion, currently only SAMA3.1, SAMA3.0, BAMA 2.0 and
#    ARAMORPH1.2.1 are supported. Note that using BAMA2.0 will result 
#    in some accuracy loss (2-4% absolute, depending on the evaluation 
#    measure) as MADA was tuned with SAMA3.1 in mind. Using ARAMORPH1.2.1
#    will also result in accuracy loss.
#
#
#
#
########################################################################


############################################################################
##### READ COMMAND LINE  #####

my $madahome="";
my $srihome="";
my $svmhome="";
my $xamadir="";
my $xamaversion="";

my $disambig="";
my $svmtagger="";

foreach( @ARGV ) {

    if( /^madahome=(\S+)/ )      { $madahome=$1; }
    elsif( /^srihome=(\S+)/ )    { $srihome=$1;  }
    elsif( /^svmhome=(\S+)/ )    { $svmhome=$1;  }
    elsif( /^xamadir=(\S+)/ )    { $xamadir=$1; }
    elsif( /^xamaversion=(SAMA3.1|SAMA3.0|BAMA2.0|ARAMORPH1.2.1)/i ) {
	$xamaversion=uc($1);
    }

}


############################################################################
##### VERIFY EXISTANCE OF NEEDED DIRECTORIES  #####

if( $madahome ne "" ) {
    $madahome = File::Spec->rel2abs( $madahome );  # Get Absolute paths
}
if( $srihome ne "" ) {
    $srihome  = File::Spec->rel2abs( $srihome  );
}
if( $svmhome ne "" ) {
    $svmhome  = File::Spec->rel2abs( $svmhome  );
}
if( $xamadir ne "" ) {
    $xamadir = File::Spec->rel2abs( $xamadir );
}


print "\n\n===============================================\n";
print "Running MADA installation and testing script ...\n\n";

if( ! -d $madahome || ! -d "$madahome/ALMOR" ||
    ! -d "$madahome/config-files" || 
    ! -d "$madahome/MADA" ||
    ! -d "$madahome/SAMPLE" ||
    ! -d "$madahome/feature-weights" ) {

    &printUsage();
    die "$0: Error -  the provided madahome parameter does not appear to be a valid MADA installation directory.\n";

}
else {

    print "Located MADA home directory $madahome ...\n";
}


if( ! -d $srihome ) {

    &printUsage();
    die "$0: Error - the provided SRILM home directory does not appear to exist\n";
}
else {

    $disambig = `find $srihome/bin -name disambig`;
    chomp $disambig;
    
    if( $disambig eq "" ) {

	die "$0: Error - Unable to locate SRILM disambig exectuable; double-check that your SRILM installation was done correctly.\n";
    }
    else {

	print "Located disambig utility at $disambig ...\n";
    }


}


if( ! -d $svmhome ) {

    &printUsage();
    die "$0: Error - the provided SVMTools home directory does not appear to exist\n";

}
else {
    print "Located SVMTools directory $svmhome ...\n";
    $svmhome =~ /SVMTool-(\S+)$/;
    my $ver = $1;
    
    print "  SVMTools version appears to be $ver ...\n";
    if( $ver ne "1.3.1") {

	print "$0: Warning - The most current version of SVMTools is 1.3.1. We strongly recommend that you upgrade to this version.\n";
    }

    $svmtagger = $svmhome . "/bin/SVMTagger";
    if( ! -e $svmtagger ) {

	die "$0: Error - Unable to locate the SVMTagger executable under $svmhome/bin\n";
    }
    
    print "  Located SVMTagger at $svmtagger ...\n";

}


if( ! -d $xamadir || ! -e "$xamadir/dictPrefixes" ||
    (! -e "$xamadir/dictStems" && ! -e "$xamadir/dictStems.tsv") || 
    ! -e "$xamadir/dictSuffixes" ||
    ! -e "$xamadir/tableAB" || ! -e "$xamadir/tableAC" ||
    ! -e "$xamadir/tableBC" ) {

    &printUsage();
    die "$0: Error - The specified XAMA directory does not appear to exist, or does not contain all 3 dict* file and all 3 table* files.\n";

}
else {

    print "Located XAMA prefix and table directory $xamadir ...\n";
}


if( $xamaversion !~ /^(SAMA3.1|SAMA3.0|BAMA2.0|ARAMORPH1.2.1)$/i ) {

    &printUsage();
    die "$0: Error - The specified XAMA version $xamaversion is not valid\n\tCurrently only SAMA3.1, SAMA3.0, BAMA2.0 and ARAMORPH1.2.1 are supported.";

}
else {

    print "Specified version of XAMA to use is $xamaversion ...\n";

}


my $xamamap;

if( $xamaversion =~ /^(SAMA3.0|SAMA3.1)$/i ) {
    $xamamap = $madahome . "/ALMOR/Form2Func-SAMA3.1.map";
}
elsif( $xamaversion =~ /^(BAMA2.0)$/ ) {
    $xamamap = $madahome . "/ALMOR/Form2Func-BAMA2.map";
} elsif ( $xamaversion =~ /^ARAMORPH1.2.1$/ ) {
    $xamamap = $madahome . "/ALMOR/Form2Func-ARAMORPH1.2.1.map";
}
if( ! -e $xamamap ) {
	
    die "$0: Error - Could not locate the map file associated with this version of XAMA: $xamamap ... check that all of the MADA home directory is intact. \n";
}


print "Located XAMA map file $xamamap ... \n";

print "...Finished locating components.\n\n";

############################################################################
##### CHECK THAT SVMTools and MADA are in PERL5LIB  #####

my $perl5lib = $ENV{'PERL5LIB'};
print "===============================================\n";
print "Verifying \$PERL5LIB path elements ...\n";
print "\nYour current \$PERL5LIB is  $perl5lib \n";

if( $perl5lib !~ /$svmhome\/lib/ ) {

    die "$0: Error - SVMTools lib directory ($svmhome/lib) does not appear to be included in your \$PERL5LIB environment variable.  Please add it before proceeding.\n";

}
else {
    print "Verified that SVMTools/lib is within your \$PERL5LIB ...\n";

}

if( $perl5lib !~ /$madahome/ ) {
    die "$0: Error - MADA home directory ($madahome) does not appear to be included in your \$PERL5LIB environment variable.  Please add it before proceeding.\n";
}
else {
    print "Verified that MADA is within your \$PERL5LIB ...\n";

}

############################################################################
#####  CREATE ALMOR.db file from XAMA information  #####

print "\n===============================================\n";

my $cmd;
my $date = `date +%m%d%y`;
chomp $date;

my $almordb = "$madahome/MADA/almor-$xamaversion-$date.db";
my $almorlink = "almor.db";

$cmd = "perl $madahome/ALMOR/XAMA-to-ALMOR3.pl $xamamap $xamadir $almordb";
print "\nCreating ALMOR database from XAMA information; there many be a few warning messages\n";
print "here that can be ignored:\n   $cmd\n";

system($cmd);

if( ! -e $almordb || -z $almordb ) {

    die "$0:  Error - Problem creating ALMOR database $almordb \n";
}


my $pwd = File::Spec->path();  # Current directory
chdir "$madahome/MADA";

$cmd = "ln -sf almor-$xamaversion-$date.db $almorlink";
print "Creating soft link:\n   $cmd\n";

system($cmd);
chdir $pwd;

if( ! -e "$madahome/MADA/$almorlink" ) {
    
    die "$0:  Error - Problem creating soft link to new ALMOR database $madahome/MADA/$almorlink \n";
}


############################################################################
#####  CREATE A NEW .MADACONFIG FILE USING THESE DIRECTORY STRUCTURES  #####

print "\n===============================================\n";
my $generic = "$madahome/config-files/generic.madaconfig";
my $template = "$madahome/config-files/template.madaconfig";

print "\nCreating a new MADA configuration file template using your system information ...\n";

open(GEN, "$generic") || die "$0: Error - Unable to open generic mada config file $generic\n";
open(TEM, ">$template") || die "$0: Error - Unable to open your template madaconfig file $template for writing\n";

my $line;
while( $line =<GEN>) {

    chomp $line;
    
    if( $line =~ /^MADA_HOME/ ) {
	$line =~ s/^MADA_HOME\s+=\s+(\S+)\s*$/MADA_HOME = $madahome/;
	
    }
    elsif( $line =~ /^SRI_NGRAM_TOOL/ ) {
	$line =~ s/^SRI_NGRAM_TOOL\s+=\s+(\S+)\s*$/SRI_NGRAM_TOOL = $disambig/;
    }
    elsif( $line =~ /^SVM_TAGGER/ ) {
	$line =~ s/^SVM_TAGGER\s+=\s+(\S+)\s*$/SVM_TAGGER = $svmtagger/;
    }

    print TEM "$line\n";

}


close(GEN);
close(TEM);

print "  ...Done.  Use $template as your baseline .madaconfig file.\n";

############################################################################
#####  RUN TEST OF MADA SYSTEM #####

print "\n===============================================\n";
print "\nInstallation complete. Running test of entire MADA system ...\n";

my $infile = "$madahome/SAMPLE/sample+ID.ar.utf8";
my $gold = "$madahome/SAMPLE/GOLD.sample+ID.ar.utf8";
if( $xamaversion =~ /ARAMORPH1.2.1/i ) {
    $gold = "$madahome/SAMPLE/Aramorph-GOLD.sample+ID.ar.utf8";
}

if( -e "$infile.bw" ) {
    unlink( "$infile.bw" );
}
if( -e "$infile.bw.mada" ) {
    unlink( "$infile.bw.mada" );
}
if( -e "$infile.bw.mada.tok" ) {
    unlink( "$infile.bw.mada.tok" );
}

$cmd = "perl $madahome/MADA+TOKAN.pl file=$infile config=$template TOKAN_SCHEME=\"SCHEME=ATB MARKNOANALYSIS SENT_ID\" SENTENCE_IDS=YES";

print "\n Running:  $cmd\n\n";

system($cmd);

print "\n\n";

## Check that *.bw, *mada, and *tok files exist:
if( ! -e "$infile.bw" ) {

    die "$0: Error - The installation test could not create a preprocessed test file ($infile.bw).\n    Verify that you have write permisions to the $madahome/SAMPLE directory, and ample disk space.\n\n";
}

if( ! -e "$infile.bw.mada" ) {
    die "$0: Error - The installation test could not create a MADAfied version of the test input ($infile.bw.mada).\n\n";
}

if( ! -e "$infile.bw.mada.tok" ) {

    die "$0: Error - The installation test could not create a TOKANized version of the test input ($infile.bw.mada.tok).\n\n";
}


## Check that the *bw and *tok files are matches

my $differ = `diff -qb $infile.bw $gold.bw`;
if( $differ ne "" ) {
    print STDERR "$0: Warning - $differ\n";
    print STDERR "$0: Warning - Detected a possible problem with the preprocessed test file ($infile.bw);\n      Compare with $gold.bw\n\n";
}
else {
    print "Pre-processed Test file created successfully!\n\n";
}


$differ = `diff -qb $infile.bw.mada.tok $gold.bw.mada.tok`;
if( $differ ne "" && $xamaversion !~ /BAMA2.0/i) {
    print STDERR "$0: Warning - $differ\n";
    print STDERR "$0: Warning - Detected a possible problem with the preprocessed test file ($infile.bw.mada.tok);\n      Compare with $gold.bw.mada.tok\n\n";
}
else {

    print "MADA and TOKAN test files created successfully!\n\n";
}


print "===============================================\n";
print "Installation of MADA complete.  \nUse the configuration file $template as a template for your MADA configurations.\n\n";

sub printUsage {


    print "=================================================================================\n";
    print "Usage:  perl INSTALL.pl \\\\\n";
    print "             madahome=<MADA directory> \\\\\n";
    print "             srihome=<SRI home directory> \\\\\n";
    print "             svmhome=<SVMTools home directory> \\\\\n";
    print "             xamadir=<directory containing XAMA dict* and table* files> \\\\\n";
    print "             xamaversion=(SAMA3.1|SAMA3.0|BAMA2.0|ARAMORPH1.2.1) \n\n";

    print " The madahome directory is the top-level directory of MADA, where this INSTALL.pl\n";
    print "     script is located.\n\n";
    print " The srihome directory is the top-level directory of the SRILM toolkit installation.\n\n";
    print " The svmhome directory is the top-level directory of the SVMTool installation.\n";
    print "     We STRONGLY recommend that you upgrade to SVMTools 1.3.1 if you have not done so.\n\n";
    print " XAMA is a shorthand for referring to BAMA or SAMA collections.\n";
    print " The specified xamadir directory should contain 6 files named dictPrefixes, \n";
    print "     dictStems, dictSuffixes, tableAB, tableAC and table BC. In SAMA-3.1, this \n";
    print "     directory is located at <SAMA 3.1 home directory>/lib/SAMA_DB/v3_1/\n\n";
    print " The xamaversion currently accepts only SAMA3.1, SAMA3.0, BAMA2.0 or ARAMORPH1.2.1\n";
    print "     SAMA 3.1 gives the best performance.\n";

    print "==================================================================================\n\n";
}
