#! /usr/bin/perl

$| = 1;
use strict;
use warnings;
use Benchmark;
use MADA::MADATools;

#######################################################################
# MADA-runSVMTOOLS.pl
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
# This script runs the SVMTagger tool on the (temporary) files produced by
# MADA-generate-SVM+ngram-files.pl (specifically, the .svmt file and
# the collection of .backlex files) in order to generate feature
# classification decisions on each word of the input.  It typically is
# the most time consuming portion of the MADA process.
#######################################################################


## SVM bug fix:  with the new models, the feature tags have had their '_' terms dropped;
##  This hash has entries to put them back to their original forms.

my %restoreTag = ( "ASP*" => "asp:*", "ASPp" => "asp:p", "ASPna" => "asp:na", "ASPc" => "asp:c",
		   "ASPi" => "asp:i",
		   "CASu" => "cas:u", "CASn" => "cas:n", "CASna" => "cas:na", "CASa" => "cas:a",
		   "CASg" => "cas:g",
		   "ENC03mpposs" => "enc0:3mp_poss", "ENC03ddobj" => "enc0:3d_dobj", 
		   "ENC02mpposs" => "enc0:2mp_poss", "ENC03dpron" => "enc0:3d_pron",
		   "ENC03mspron" => "enc0:3ms_pron", "ENC03msposs" => "enc0:3ms_poss",
		   "ENC0maninterrog" => "enc0:man_interrog", "ENC03mppron" => "enc0:3mp_pron",
		   "ENC02dpron" => "enc0:2d_pron",   "ENC03mpdobj" => "enc0:3mp_dobj",
		   "ENC02fppron" => "enc0:2fp_pron", "ENC0lAneg" => "enc0:lA_neg",
		   "ENC0manrel" => "enc0:man_rel",   "ENC01sdobj" => "enc0:1s_dobj", 
		   "ENC02mspron" => "enc0:2ms_pron", "ENC02mppron" => "enc0:2mp_pron",
		   "ENC0mainterrog" => "enc0:ma_interrog", "ENC0na" => "enc0:na",
		   "ENC03fsdobj" => "enc0:3fs_dobj", "ENC0mArel" => "enc0:mA_rel",
		   "ENC00" => "enc0:0", "ENC02fspron" => "enc0:2fs_pron", "ENC02fpposs" => "enc0:2fp_poss",
		   "ENC01sposs" => "enc0:1s_poss",   "ENC0Ahvoc" => "enc0:Ah_voc", "ENC02ddobj" => "enc0:2d_dobj",
		   "ENC02mpdobj" => "enc0:2mp_dobj", "ENC03fppron" => "enc0:3fp_pron",
		   "ENC01pposs" => "enc0:1p_poss",   "ENC0marel" => "enc0:ma_rel", "ENC02fsposs" => "enc0:2fs_poss",
		   "ENC03msdobj" => "enc0:3ms_dobj", "ENC0mAinterrog" => "enc0:mA_interrog",
		   "ENC03dposs" => "enc0:3d_poss",   "ENC03fpposs" => "enc0:3fp_poss",
		   "ENC0masub" => "enc0:ma_sub",     "ENC02fpdobj" => "enc0:2fp_dobj",
		   "ENC02dposs" => "enc0:2d_poss",   "ENC01spron" => "enc0:1s_pron",
		   "ENC03fspron" => "enc0:3fs_pron", "ENC03fsposs" => "enc0:3fs_poss",
		   "ENC03fpdobj" => "enc0:3fp_dobj", "ENC01ppron" => "enc0:1p_pron",
		   "ENC02fsdobj" => "enc0:2fs_dobj", "ENC02msposs" => "enc0:2ms_poss",
		   "ENC01pdobj" => "enc0:1p_dobj",   "ENC02msdobj" => "enc0:2ms_dobj",
		   "ENC0mAsub" => "enc0:mA_sub",
		   "GENna" => "gen:na", "GENm" => "gen:m", "GENf" => "gen:f",
		   "MODs" => "mod:s", "MODi" => "mod:i", "MODna" => "mod:na",
		   "MODu" => "mod:u", "MODj" => "mod:j",
		   "NUMs" => "num:s", "NUMna" => "num:na", "NUMd" => "num:d",
		   "NUMu" => "num:u", "NUMp" => "num:p",
		   "PERna" => "per:na", "PER3" => "per:3", "PER2" => "per:2", "PER1" => "per:1",
		   "POSnoun" => "pos:noun", "POSpartneg" => "pos:part_neg", "POSpronrel" => "pos:pron_rel",
		   "POSnounnum" => "pos:noun_num", "POSadvinterrog" => "pos:adv_interrog", "POSpartvoc" => "pos:part_voc",
		   "POSadjcomp" => "pos:adj_comp", "POSpunc" => "pos:punc", "POSconjsub" => "pos:conj_sub",
		   "POSpartfut" => "pos:part_fut", "POSpronexclam" => "pos:pron_exclam",
		   "POSpart" => "pos:part", "POSpartverb" => "pos:part_verb", "POSverb" => "pos:verb",
		   "POSdigit" => "pos:digit", "POSconj" => "pos:conj", "POSproninterrog" => "pos:pron_interrog",
		   "POSpron" => "pos:pron", "POSabbrev" => "pos:abbrev", "POSpartdet" => "pos:part_det",
		   "POSinterj" => "pos:interj", "POSadjnum" => "pos:adj_num", "POSadv" => "pos:adv",
		   "POSpartrestrict" => "pos:part_restrict", "POSadvrel" => "pos:adv_rel",
		   "POSadj" => "pos:adj", "POSprep" => "pos:prep", "POSpartinterrog" => "pos:part_interrog",
		   "POSverbpseudo" => "pos:verb_pseudo", "POSnounprop" => "pos:noun_prop",
		   "POSpartfocus" => "pos:part_focus", "POSnounquant" => "pos:noun_quant",
		   "POSlatin" => "pos:latin", "POSprondem" => "pos:pron_dem", 
		   "PRC0na" => "prc0:na",
		   "PRC0mApart" => "prc0:mA_part", "PRC00" => "prc0:0", "PRC0Aldet" => "prc0:Al_det",
		   "PRC0mAneg" => "prc0:mA_neg", "PRC0lAneg" => "prc0:lA_neg", "PRC0mArel" => "prc0:mA_rel",
		   "PRC1laemph" => "prc1:la_emph", "PRC1kaprep" => "prc1:ka_prep", "PRC1fiyprep" => "prc1:fiy_prep",
		   "PRC1lijus" => "prc1:li_jus", "PRC10" => "prc1:0", "PRC1larc" => "prc1:la_rc",
		   "PRC1liprep" => "prc1:li_prep", "PRC1wAvoc" => "prc1:wA_voc", "PRC1yAvoc" => "prc1:yA_voc",
		   "PRC1taprep" => "prc1:ta_prep", "PRC1waprep" => "prc1:wa_prep", "PRC1safut" => "prc1:sa_fut",
		   "PRC1hAdem" => "prc1:hA_dem", "PRC1biprep" => "prc1:bi_prep",
		   "PRC1na" => "prc1:na", "PRC1laprep" => "prc1:la_prep",
		   "PRC1bipart" => "prc1:bi_part", 
		   "PRC2faconn" => "prc2:fa_conn",
		   "PRC2farc" => "prc2:fa_rc", "PRC2na" => "prc2:na", "PRC20" => "prc2:0",
		   "PRC2wapart" => "prc2:wa_part", "PRC2wasub" => "prc2:wa_sub", "PRC2fasub" => "prc2:fa_sub",
		   "PRC2waconj" => "prc2:wa_conj", "PRC2faconj" => "prc2:fa_conj", 
		   "PRC30" => "prc3:0", "PRC3na" => "prc3:na", "PRC3>aques" => "prc3:>a_ques",
		   "STTu" => "stt:u", "STTi" => "stt:i", "STTna" => "stt:na", "STTc" => "stt:c",
		   "STTd" => "stt:d",
		   "VOXp" => "vox:p", "VOXna" => "vox:na", "VOXu" => "vox:u", "VOXa" => "vox:a"
    );



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
    die "$0: Error - .svmt file to process not specified in command line \n";
}

my $quiet = 0;
if( exists $cmdline->{QUIET} ) {
    $quiet = 1;
}

##################################################################################
#####  READ CONFIGURATION FILE, LOAD VARIABLES #####

my $configfile = $cmdline->{CONFIG};
my $mafile = $cmdline->{FILE};  
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


my $modeldir = "";
if ( exists $configs{MODEL_DIR} ) {
    $configs{MODEL_DIR} =~ s/\/+$//; # Strip off trailing '/' characters if present
    $modeldir = "$configs{MADA_HOME}/$configs{MODEL_DIR}";
}
else {
    die "$0: Error - SVM Model directory unspecified in configuration file and/or command line.\n";
}



my $SVMTagger = "";
if( exists $configs{SVM_TAGGER} && -f $configs{SVM_TAGGER} ) {
    $SVMTagger = $configs{SVM_TAGGER};
}
else {
    die "$0: Error - SVM Tagger executable unspecified in configuration file and/or command line, or is otherwise unavailable.\n";
}


my %classifiers;
if( exists $configs{CLASSIFIERS} ) {
    foreach( split( /\s/, $configs{CLASSIFIERS} ) ) {
	$classifiers{$_} = 1;
    }
}
else { #default to using only pos (not recommeded)
    %classifiers = ( pos => 1 );
    &MADATools::report("Classifier list not specified in configuration file or command line.  Using Part-of-Speech (POS) as only classifier.","warn",$quiet);
}


my $removebacklexfiles = "no";
if( exists $configs{REMOVE_BACKLEX_FILES} ) {
    $removebacklexfiles = lc( $configs{REMOVE_BACKLEX_FILES} );
}
if( $removebacklexfiles !~ /^(yes|no)$/ ) {
    $removebacklexfiles = "no";
}

##################################################################################
#####  RUN EACH OF THE SPECIFIED SVM CLASSIFIERS #####

#my $SVMTOOLcommand = "$perlversion $SVMTagger -T 1";
my $SVMTOOLcommand = "perl $SVMTagger -T 1";

if( ! $quiet ) {
    print STDERR "SVMTools Classification Running ...\n";
}
my $command="";
my $f;

system ("cp -f $mafile.svmt $mafile.svmt.classified.temp");
unlink( "$mafile.svmt.temp" );
my $stime;
my $etime;

foreach $f (sort keys %classifiers){
    # The command line below creates a file with one word per line, and the output of each classifer listed
    $command = "$SVMTOOLcommand -B $mafile.$f.backlex $modeldir/$f < $mafile.svmt |cut -d \" \" -f 2 | paste -d \" \" $mafile.svmt.classified.temp - > $mafile.svmt.temp; mv $mafile.svmt.temp $mafile.svmt.classified.temp";
    if( ! $quiet ) {
	print STDERR "   Classifying feature $f...  Time:  ";
	$stime = Benchmark->new;
    }
    system("$command");   
    if( ! $quiet ) {
	$etime = Benchmark->new;
	print STDERR timestr(timediff($etime,$stime));
	print STDERR "\n";
    }
}


## SVM bug fix:  Correct the feature tag format
open(TEMP, "$mafile.svmt.classified.temp" ) || die "$0: Error - Unable to open $mafile.svmt.classified.temp\n";
open(OUT, ">$mafile.svmt.classified" ) || die "$0: Error - Unable to open $mafile.svmt.classified\n";

while( my $line = <TEMP> ) {
    my @a = split(/\s+/, $line);
    my $i;
    print OUT "$a[0]";
    for($i=1; $i<=$#a; $i++ ) {
	if( exists $restoreTag{$a[$i]} ) {
	    print OUT " $restoreTag{$a[$i]}";
	} else {
	    print OUT " $a[$i]";  # Should never happen if the %restoreTag hash is built correctly
	}
    }
    print OUT "\n";

}
close(TEMP);
close(OUT);

unlink ("$mafile.svmt.classified.temp");  # Remove the version of the .classified file that uses the punct-less tag format

if( $removebacklexfiles eq "yes" ) {  # Remove backlex files if requested to reduce clutter

    foreach $f ( keys %classifiers ) {
	unlink( "$mafile.$f.backlex" );
    }

    unlink( "$mafile.svmt" );  # Remove the .svmt file too
}


if( ! $quiet ) {
    print STDERR "Done.\n";
}


##################################################################################

sub printUsage {

    print "\nUsage: $0 config=<.madaconfig file> file=<.ma file> [quiet] [other variables]\n\n";
    print "  Output is produced in <.ma file>.svmt.classified. Both the config file and \n";
    print "  the .ma file must be specified; in addition, the .svmt and .backlex files generated\n";
    print "  by MADA-generate-SVM+ngram-files.pl must be present in the same directory\n";
    print "  as the <.ma file>.\n\n";

    print "  If quiet is included on the command line, all informational and warning messages will be\n";
    print "   repressed.\n\n";

    print "  The other variables are optional, and can be any of the following,\n";
    print "  specified in VARIABLE=VALUE format:\n\n";
    print "    MADA_HOME=<directory location of MADA installation>\n";
    print "    PERL_EXECUTABLE=<the location of the perl executable to use when running SVMTools -- please use 5.8.8 (5.10.0 is not supported by SVMTools)\n";
    print "    CLASSIFIERS=\"list of classifers, separated by spaces, in quotes\"\n";
    print "    SVM_TAGGER=<absolute location of the SVMTagger executable>\n";
    print "    REMOVE_BACKLEX_FILES=[YES|NO]\n";
    print "    MODEL_DIR=<directory location of the MADA SVM models, relative to MADA_HOME>\n\n";
    print "  If any of the above options is specified on the command line, the\n";
    print "  command line value will be used instead of the value indicated in the\n";
    print "  .madaconfig file. All other options will be ignored. For a more\n";
    print "  detailed description of each variable, consult your .madaconfig file.\n\n";
	
}






