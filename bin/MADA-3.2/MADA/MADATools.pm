package MADATools;

#######################################################################
# MADATools.pm
# Copyright (c) 2007-2012 Columbia University in 
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


=head1 NAME

    MADATools -- A package containing general utility functions for MADA-related scripts

=head1 DESCRIPTION

    These functions are typically simple data manipulations that aren't associated
    with a particular object or class. Examples include removing duplicate entries
    from an array (uniquing) and stripping extraneous whitespace from a string.

=cut

use strict;
use warnings;

use Encode;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( readConfig read_config unique removeDiacritics 
		     cleanWhitespace openReadFile readCommandLine 
                     convertEncoding readUTF8CleanMap cleanUTF8String
                     convertBuckwalterToUTF8 convertUTF8ToBuckwalter

                     convertSafeBWToUTF8 convertUTF8ToSafeBW
                     convertBuckwalterToSafeBW convertSafeBWToBuckwalter

                     convertTaggedBuckwalterToUTF8 tagEnglishInString
                     separatePunctuationAndNumbers makeXMLFriendly unmakeXMLFriendly 
                     convertNewMADAPOSToOldMADAPOS
                     mapNewFeatValToOldFeatVal normalizeWord

                     report
);



##################################################################################
###   Global / "Static" Variables



my %CLEAN_UTF8_MAP = ();   ## A global hash to store UTF-8 cleaner Map information in memory


my %MADAPOSTagMap = (  ## Maps new MADA POS Tag set to the Old MADA POS Tag set

    noun => "N",          noun_num => "N",      noun_quant => "N",
    noun_prop => "PN",
    adj => "AJ",          adj_comp => "AJ",     adj_num => "AJ",
    adv => "AV",
    adv_interrog => "Q",  pron_interrog => "Q",
    adv_rel => "REL",     pron_rel => "REL", 
    pron => "PRO",        pron_exclam => "PRO", 
    pron_dem => "D",      part_det => "D",
    verb => "V",          verb_pseudo => "P",
    part => "P",          part_focus => "P",    part_fut => "P", part_interrog => "P", 
    part_restrict => "P", part_verb => "P",     part_voc => "P", prep => "P", 
    part_neg => "NEG",
    abbrev => "AB",
    punc => "PX",
    conj => "C",
    conj_sub => "C",
    interj => "IJ",
    digit => "NUM",
    latin => "F"
    );




#my $UTF8_ENCODING_OBJ = Encode::find_encoding("utf8");  ## An encoding object; declaring it here saves time when using encode/decode



=head2 Methods

##################################################################################


=head3 readConfig, read_config

    MADATools::readConfig($configfile)
    MADATools::read_config($configfile)
 
    my $configFile = $ARGV[0];
    my %configs = %{ MADATools::readConfig($configFile) }; 
    # %configs is now filled with variables and values listed in the config file

    This function read in a configuration file and loads a hash with the
    values it finds there. The format of the config file is:
    
      VARIABLE = VALUE

    with one variable per line. The function will ignore (as a comment) anything
    it finds after a '#' character, and blank lines.

    This function can accept gzipped configuration files.

    This function can be called as either readConfig() or read_config(); readConfig()
    is its proper name and is consistent with the established function naming
    conventions. read_config() is an older name that is maintained for backward
    compatability.

=cut

sub read_config {
    return &readConfig(@_);
}

sub readConfig {
    my ($configfile) = @_;
    my %config;
    my @temp;
    
    #print "  Reading from config file $configfile...\n";
    my $fh = *MY_CONFIG_FILE_HANDLE_IN_MADATOOLS;
    if( ! &openReadFile( $fh, $configfile ) ) {
	die "$0:readConfig: Error - Unable to open configuration file $configfile.\n";
    }

    while( my $line=<$fh> ) {
	chomp $line;
	if( $line ne "" ) {

	    if( $line =~ /\#/ ) {
		@temp = split(/\#/, $line);
		$line = $temp[0];
		if( ! defined $line ) {$line = "";}
	    }
	
	    if( $line =~ /\=/ ) {
		@temp = split(/\=/, $line);
		my $key = $temp[0];
		my $value = ""; 
		for (my $i = 1; $i < $#temp; $i++ ) {
		    $value .= $temp[$i] . "=";
		}
		$value .= $temp[$#temp];

		# strip off extra whitespace at beginning and end
		$key =~ s/^\s*|\s*$//g;
		$value =~ s/^\s*|\s*$//g;
		
		$config{$key} = $value;
	    }
	}
    }

    close $fh;
    return \%config;
}

##################################################################################


=head3 unique

    MADATools::unique(@l)
 
    my @array = (1,2,4,5,2,3,4,2,1);
    @array = MADATools::unique(@array);
    # @array now is (1,2,4,5,3)

    Returns a new array of unique values of a provided array; the order of the
    elements is preserved.

=cut

sub unique {
    my (@l)=@_;
    my %l=();
    my @m = ();
    foreach my $l (@l){
	if( ! exists $l{$l} ) {
	    $l{$l}=1;
	    push @m, $l;
	}
    }
    return (@m);
}

##################################################################################


=head3 cleanWhitespace

    MADATools::cleanWhitespace($w)
 
    my $line = "   This is    a line with   space\t\t ";
    $line = MADATools::cleanWhitespace($line);
    # $line is now "This is a line with space";

    This function just replaces strings of whitespace with a single space,
    and removes any whitespace from the beginning and end of a given string.

=cut

sub cleanWhitespace {
    my ($w) = @_;
    $w =~ s/\s+/ /g;
    $w =~ s/^\s+|\s+$//g;
    return $w;
}

##################################################################################


=head3 removeDiacriticsFromTail

    MADATools::removeDiacriticsFromTail($w)
 
    my $line = "AiT~alaEa";
    $line = MADATools::removeDiacriticsFromTail($line);
    # $line is now "AiT~alaE";

    This function just removes diacritics [uiao~FKN\`] from
    the end of the provided word only.

=cut

sub removeDiacriticsFromTail {
    my ($w) = @_;
    $w=~s/[uiao~FKN\`]+$//;
    return $w;
}


##################################################################################


=head3 removeDiacritics

    MADATools::removeDiacritics($w)
 
    my $line = "AiT~alaEa";
    $line = MADATools::removeDiacritics($line);
    # $line is now "ATlE";

    This function just removes diacritics [uiao~FKN\`] from
    a provided word or string and returns the result.

=cut

sub removeDiacritics {
    my ($w) = @_;
    $w=~s/[uiao~FKN\`]//g;
    return $w;
}

##################################################################################


=head3 normalizeWord

    MADATools::normalizeWord($w)

    my $normword = MADATools->normalizeWord($word);

    Takes a word and performs standard normalization steps:
       digits -> '8'
       all 'Y' characters -> 'y'
       Alef normalization ( alefs -> 'A' )
       Diacritic stripping ( [uiao~FKN\`] -> '' )

    then returns the normalized word.

    If the input word happens to be a string of nothing but diacritics, nothing
    is done to the word and it is returned.

    If the input word begins with "@@", it will be returned untouched.

=cut

sub normalizeWord {
    my ($w) = @_;
    if( $w !~ /^\@\@/ ) {
	$w =~ s/\d/8/g;
	$w =~ s/Y/y/g; 
	$w =~ s/[><\|A\{]/A/g;
	if( $w !~ /^[uiao~FKN\`]+$/ ) {   
	    # Don't remove diacritics if that's all there is
	    $w = &removeDiacritics($w);
	}
    }

    return $w;
}

##################################################################################


=head3 normalizeLex

    MADATools::normalizeLex($l)

    my $normlex = MADATools->normalizeLex($lex);

    Takes a lexeme in BAMA format and strips off the _\d+ suffix from the
    end (if present) and then returns the normalized lexeme.

=cut

sub normalizeLex {
    my ($l) = @_;
    $l =~ s/\_\d+$//;
    return $l;
}



##################################################################################

=head3 openReadFile

    MADATools::openReadFile($handle, $filename)
 
    my $filehandle = *FH;
    if( ! MADATools::openReadFile($filehandle,$filename) ) {
          die "Unable to open file $filename\n"; 
    }

    my $line;
    while( $line = <$filehandle> ) { ... }

    This function opens a file for reading using the specified
    file handle.
.
    It can open a regular or gzipped file.

    If the file cannot be opened, the function returns 0.

=cut


sub openReadFile {
    my ($handle, $filename) = @_;
   
    my $ok = 1;

    if( ! -r $filename ) { $ok = 0 } 
    else {

	if( $filename =~ /\.gz$/ ) {
	    if( ! open($handle, "gzip -f -c -d $filename |") ) { $ok = 0; }
	}
	else {	
	    if( ! open($handle, '<', $filename) ) { $ok = 0;}

	}
    }

    return $ok;

}

##################################################################################

=head3 readCommandLine

    MADATools::readCommandLine(@args)
 
    @ARGV = ( configfile=generic.madaconfig, file=tempfile.ma, 
	      TARGET_DIRECTORY=./target, OPTION1=YES );

    my %options = %{ MADATools::readCommandLine(@ARGV) };
    
    my $configfile = $options{CONFIGFILE};
    my $file = $options{FILE};
    my $targetDir = $options{TARGET_DIRECTORY};
    my $option1 = $options{OPTION1};

    This function is meant to operation on the command line options given
    to a script (i.e., @ARGV). It assumes that the command line consists of
    a string of variables and values in VARIABLE=VALUE format, separated by
    whitespace. If a variable is listed without a value (that is, an entry
    in @ARGV without a "=" character), the variable is given a value of "".

    By convention, variable names should consist of only letters, digits or
    underscores.

    All variable names are uppercased after being read.

    Returns a reference to a hash of the variables-value pairs.


=cut

sub readCommandLine {
    my (@args) = @_;
    my %opts = ();
    my ($var,$val,$elem);
    foreach $elem ( @args ) {

	if( $elem =~ /^([^\=]+)\=(.*)$/ ) {
	    $var = $1;
	    $val = $2;	    
	}	
	else {
	    $var = $elem;
	    $val = "";
	}

	$var = uc( $var );
	$opts{$var} = $val;

    }

    return \%opts;
}

##################################################################################


=head3 convertEncoding

    MADATools::convertEncoding($inline,$incode,$outcode,$inputEncoded,$outputEncoded)
 
    Example of use:

    ## $line is in UTF-8 octet sequence 
    $line = MADATools::convertEncoding($line,"UTF-8","BUCKWALTER");
    ## $line is now in Buckwalter

    ## $line2 is a UTF-8 string (not encoded)
    $line2 = MADATools::convertEncoding($line2, "UTF-8", "CP-1256", 0, 0);
    ## $line2 is now a CP1256 string (not encoded


    This function is designed to convert a line of text between two of several
    possible encodings. It is meant to replace the old ArabicTokenizer.pl code.

    Supported Encodings include:

    BUCKWALTER | UTF-8 | UTF-16 | CP-1256 | ISO-8859-6 ( or ISO )

    NOTE:  The input and output of this function are assumed to be encoded as
    octet sequences already (i.e., the output of Encode::encode()) by default.
    The fourth argument, if false, will cause the function to encode() the input
    string into octets before converting.  The fifth argument, if false, will cause
    the function to decode() the output into a string before returning it. Thus,
    these fourth and fifth arguments allow the user to use this function on
    encoded or non-encoded data and have the output encoded or non-encoded.

    When providing the encodings to use, the hyphens do not need to be included,
    and the names are case insensitive.
   

=cut


sub convertEncoding {
    my ($inline,$incode,$outcode,$inputEncoded,$outputEncoded)=@_;
    my $outline;

    if( ! defined $inputEncoded )  { $inputEncoded = 1;  }
    if( ! defined $outputEncoded ) { $outputEncoded = 1; }

    ## Convert incode to CP1256
    if($incode =~ /^UTF-?8$/i) {
	if( ! $inputEncoded ) {
	    $inline = Encode::encode("cp1256",$inline);
	}
	else {
	    $inline = Encode::encode("cp1256", Encode::decode("utf8", $inline));
	}
    }
    elsif($incode =~ /^UTF-?16$/i) {
	if( ! $inputEncoded ) {
	    $inline = Encode::encode("cp1256",$inline);
	}
	else {
	    $inline = Encode::encode("cp1256", Encode::decode("UTF-16", $inline));
	}	
    }
    elsif($incode =~ /^(BUCKWALTER|BW)$/i) {
	$inline=&convertBuckwalterToCP1256($inline);
    }
    elsif($incode =~ /^(ISO-?8859-?6?|ISO)$/i) { 
	if( ! $inputEncoded ) {
	    $inline = Encode::encode("cp1256",$inline);
	}
	else {
	    $inline = Encode::encode("cp1256", Encode::decode("iso-8859-6", $inline) );
	}
    }
    elsif( $incode =~ /^CP-?1256$/i && ! $inputEncoded ) {
	$inline = Encode::encode("cp1256", $inline);
    }


    $outline = $inline;

    ## Convert cp1256 to outcode
    if($outcode =~ /^UTF-?8$/i) { 
	if( ! $outputEncoded ) {
	    $outline = Encode::decode("utf8",$outline);
	}
	else {
	    $outline = Encode::encode("utf8", Encode::decode("cp1256", $outline));
	}
	
    }
    elsif($outcode =~ /^UTF-?16$/i) { 
	if( ! $outputEncoded ) {
	    $outline = Encode::decode("UTF-16",$outline);
	}
	else {
	    $outline = Encode::encode("UTF-16", Encode::decode("cp1256", $outline));
	}
    } 
    elsif($outcode =~ /^(BUCKWALTER|BW)$/i) {
	$outline=&convertCP1256ToBuckwalter($outline);
    }
    elsif($outcode =~ /^(ISO-8859-6|ISO)$/i) { 
	if( ! $outputEncoded ) {
	    $outline = Encode::decode("iso-8859-6",$outline);
	}
	else {
	    $outline = Encode::encode("iso-8859-6", Encode::decode("cp1256", $outline));
	}
 	
    }
    elsif( $outcode =~ /^CP-?1256$/i && ! $outputEncoded ) {
	$outline = Encode::decode("cp1256",$outline);
    }

 
    return $outline;
}




##################################################################################



=head3 convertBuckwalterToCP1256

    MADATools::convertBuckwalterToCP1256($line)
 
    Example of use:

    ## $line is in Buckwalter
    $line = MADATools::convertBuckwalterToCP1256($line);
    ## $line is now in CP-1256


    This function directly converts a line in Buckwalter to CP-1256.

    NOTE:  THE OUTPUT IS AN OCTET SEQUENCE, LIKE THE OUTPUT OF Encode::encode().


    This function is used internally by MADATools::convertEncoding().
   

=cut

sub convertBuckwalterToCP1256 {

    my ($line)=@_;

    $line =~ s/\'/\Á/g;
    $line =~ s/\|/Â/g;
    $line =~ s/\>/Ã/g;
    $line =~ s/\&/Ä/g;
    $line =~ s/\</Å/g;
    $line =~ s/\}/Æ/g;
    $line =~ s/A/Ç/g;
#added
    $line =~ s/\{/Ç/g;
    $line =~ s/b/È/g;
    $line =~ s/p/É/g;
    $line =~ s/t/Ê/g;
    $line =~ s/v/Ë/g;
    $line =~ s/j/Ì/g;
    $line =~ s/H/Í/g;
    $line =~ s/x/Î/g;
    $line =~ s/d/Ï/g;
    $line =~ s/\*/Ð/g;
    $line =~ s/r/Ñ/g;
    $line =~ s/z/Ò/g;
    $line =~ s/s/Ó/g;
    $line =~ s/\$/Ô/g;
    $line =~ s/S/Õ/g;
    $line =~ s/D/Ö/g;
    $line =~ s/T/Ø/g;
    $line =~ s/Z/Ù/g;
    $line =~ s/E/Ú/g;
    $line =~ s/g/Û/g;
    $line =~ s/f/Ý/g;
    $line =~ s/q/Þ/g;
    $line =~ s/k/ß/g;
    $line =~ s/l/á/g;
    $line =~ s/m/ã/g;
    $line =~ s/n/ä/g;
    $line =~ s/h/å/g;
    $line =~ s/w/æ/g;
    $line =~ s/y/í/g;
    $line =~ s/Y/ì/g;
    $line =~ s/F/ð/g;
    $line =~ s/N/ñ/g;
    $line =~ s/K/ò/g;
    $line =~ s/a/ó/g;
    $line =~ s/u/õ/g;
    $line =~ s/i/ö/g;
    $line =~ s/\~/ø/g;
    $line =~ s/o/ú/g;
    $line =~ s/_/Ü/g;
    #$line =~ s/\,/\xa2/g; # comma
    $line =~ s/\,/\xa1/g; # comma
    $line =~ s/\;/\xba/g; # semicolon
    $line =~ s/\?/\xbf/g; # questionmark
    $line =~ s/V/Ý/g; # V->f
    $line =~ s/G/\x90/g; # 
    $line =~ s/P/\x81/g; # 
    $line =~ s/J/\x8d/g; # 

    return ($line);
}

##################################################################################



=head3 convertCP1256ToBuckwalter

    MADATools::convertCP1256ToBuckwalter($line)
 
    Example of use:

    ## $line is in CP-1256
    $line = MADATools::convertCP1256ToBuckwalter($line);
    ## $line is now in Buckwalter


    This function directly converts a line in CP-1256 to Buckwalter.

    NOTE:  THE INPUT IS AN OCTET SEQUENCE, LIKE THE OUTPUT OF Encode::encode().

    This function is used internally by MADATools::convertEncoding().
   

=cut

sub convertCP1256ToBuckwalter {

    my ($line)=@_;
    $line =~ s/Á/\'/g;
    $line =~ s/Â/\|/g;
    $line =~ s/Ã/\>/g;
    $line =~ s/Ä/\&/g;
    $line =~ s/Å/\</g;
    $line =~ s/Æ/\}/g;
    $line =~ s/Ç/A/g;
    $line =~ s/È/b/g;
    $line =~ s/É/p/g;
    $line =~ s/Ê/t/g;
    $line =~ s/Ë/v/g;
    $line =~ s/Ì/j/g;
    $line =~ s/Í/H/g;
    $line =~ s/Î/x/g;
    $line =~ s/Ï/d/g;
    $line =~ s/Ð/\*/g;
    $line =~ s/Ñ/r/g;
    $line =~ s/Ò/z/g;
    $line =~ s/Ó/s/g;
    $line =~ s/Ô/\$/g;
    $line =~ s/Õ/S/g;
    $line =~ s/Ö/D/g;
    $line =~ s/Ø/T/g;
    $line =~ s/Ù/Z/g;
    $line =~ s/Ú/E/g;
    $line =~ s/Û/g/g;
    $line =~ s/Ý/f/g;
    $line =~ s/Þ/q/g;
    $line =~ s/ß/k/g;
    $line =~ s/á/l/g;
    $line =~ s/ã/m/g;
    $line =~ s/ä/n/g;
    $line =~ s/å/h/g;
    $line =~ s/æ/w/g;
    $line =~ s/í/y/g;
    $line =~ s/ì/Y/g;
    $line =~ s/ð/F/g;
    $line =~ s/ñ/N/g;
    $line =~ s/ò/K/g;
    $line =~ s/ó/a/g;
    $line =~ s/õ/u/g;
    $line =~ s/ö/i/g;
    $line =~ s/ø/\~/g;
    $line =~ s/ú/o/g;
    $line =~ s/Ü/_/g;
 #   $line =~ s/\xa2/\,/g; # comma
    $line =~ s/\xa1/\,/g; # comma
    $line =~ s/¡/\,/g;
    $line =~ s/\xba/\;/g; # semicolon
    $line =~ s/\xbf/\?/g; # questionmark
    $line =~ s/\x90/G/g; # 
    $line =~ s/\x81/P/g; # 
    $line =~ s/\x8d/J/g; # 

    return $line;
}


##################################################################################



=head3 convertUTF8ToBuckwalter

    MADATools::convertUTF8ToBuckwalter($line)
 
    Example of use:

    ## $line is in UTF-8
    $line = MADATools::convertUTF8ToBuckwalter($line);
    ## $line is now in Buckwalter


    This function directly converts a line in UTF8 directly to Buckwalter, without
    an intermediate CP1256 representation.


    The input should be set to utf8, i.e., using:
       binmode IN, ":utf8";
       $line = <IN>;
    or
       $line = Encode::decode("utf8",$line);
    or the equivalent.

   

=cut

sub convertUTF8ToBuckwalter {

    my ($line)= (@_);
    #$line = $UTF8_ENCODING_OBJ->decode($line);  ## Same as Encode::decode("utf8",$line), but faster since object already created
    $line =~ s/\x{0621}/\'/g;   ## HAMZA
    $line =~ s/\x{0622}/\|/g;   ## ALEF WITH MADDA ABOVE
    $line =~ s/\x{0623}/\>/g;   ## ALEF WITH HAMZA ABOVE
    $line =~ s/\x{0624}/\&/g;   ## WAW WITH HAMZA ABOVE
    $line =~ s/\x{0625}/\</g;   ## ALEF WITH HAMZA BELOW
    $line =~ s/\x{0626}/\}/g;   ## YEH WITH HAMZA ABOVE
    $line =~ s/\x{0627}/A/g;    ## ALEF
    $line =~ s/\x{0628}/b/g;    ## BEH
    $line =~ s/\x{0629}/p/g;    ## TEH MARBUTA
    $line =~ s/\x{062A}/t/g;    ## TEH
    $line =~ s/\x{062B}/v/g;    ## THEH
    $line =~ s/\x{062C}/j/g;    ## JEEM
    $line =~ s/\x{062D}/H/g;    ## HAH
    $line =~ s/\x{062E}/x/g;    ## KHAH
    $line =~ s/\x{062F}/d/g;    ## DAL
    $line =~ s/\x{0630}/\*/g;   ## THAL
    $line =~ s/\x{0631}/r/g;    ## REH
    $line =~ s/\x{0632}/z/g;    ## ZAIN
    $line =~ s/\x{0633}/s/g;    ## SEEN
    $line =~ s/\x{0634}/\$/g;   ## SHEEN
    $line =~ s/\x{0635}/S/g;    ## SAD
    $line =~ s/\x{0636}/D/g;    ## DAD
    $line =~ s/\x{0637}/T/g;    ## TAH
    $line =~ s/\x{0638}/Z/g;    ## ZAH
    $line =~ s/\x{0639}/E/g;    ## AIN
    $line =~ s/\x{063A}/g/g;    ## GHAIN
    $line =~ s/\x{0640}/_/g;    ## TATWEEL
    $line =~ s/\x{0641}/f/g;    ## FEH
    $line =~ s/\x{0642}/q/g;    ## QAF
    $line =~ s/\x{0643}/k/g;    ## KAF
    $line =~ s/\x{0644}/l/g;    ## LAM
    $line =~ s/\x{0645}/m/g;    ## MEEM
    $line =~ s/\x{0646}/n/g;    ## NOON
    $line =~ s/\x{0647}/h/g;    ## HEH
    $line =~ s/\x{0648}/w/g;    ## WAW
    $line =~ s/\x{0649}/Y/g;    ## ALEF MAKSURA
    $line =~ s/\x{064A}/y/g;    ## YEH

    ## Diacritics
    $line =~ s/\x{064B}/F/g;    ## FATHATAN
    $line =~ s/\x{064C}/N/g;    ## DAMMATAN
    $line =~ s/\x{064D}/K/g;    ## KASRATAN
    $line =~ s/\x{064E}/a/g;    ## FATHA
    $line =~ s/\x{064F}/u/g;    ## DAMMA
    $line =~ s/\x{0650}/i/g;    ## KASRA
    $line =~ s/\x{0651}/\~/g;   ## SHADDA
    $line =~ s/\x{0652}/o/g;    ## SUKUN
    $line =~ s/\x{0670}/\`/g;   ## SUPERSCRIPT ALEF

    $line =~ s/\x{0671}/\{/g;   ## ALEF WASLA
    $line =~ s/\x{067E}/P/g;    ## PEH
    $line =~ s/\x{0686}/J/g;    ## TCHEH
    $line =~ s/\x{06A4}/V/g;    ## VEH
    $line =~ s/\x{06AF}/G/g;    ## GAF


    ## Punctuation should really be handled by the utf8 cleaner or other method
 #   $line =~ s/\xa2/\,/g; # comma
#    $line =~ s//\,/g; # comma
#    $line =~ s//\,/g;
#    $line =~ s//\;/g; # semicolon
#    $line =~ s//\?/g; # questionmark

    return $line;
}


##################################################################################



=head3 convertUTF8ToSafeBW

    MADATools::convertUTF8ToSafeBW($line)
 
    Example of use:

    ## $line is in UTF-8
    $line = MADATools::convertUTF8ToSafeBW($line);
    ## $line is now in SafeBW


    This function directly converts a line in UTF8 directly to SafeBW.

    The input should be set to utf8, i.e., using:
       binmode IN, ":utf8";
       $line = <IN>;
    or
       $line = Encode::decode("utf8",$line);
    or the equivalent.

   

=cut

sub convertUTF8ToSafeBW {

    my ($line)= (@_);
    #$line = $UTF8_ENCODING_OBJ->decode($line);  ## Same as Encode::decode("utf8",$line), but faster since object already created
    $line =~ s/\x{0621}/C/g;   ## HAMZA
    $line =~ s/\x{0622}/M/g;   ## ALEF WITH MADDA ABOVE
    $line =~ s/\x{0623}/O/g;   ## ALEF WITH HAMZA ABOVE
    $line =~ s/\x{0624}/W/g;   ## WAW WITH HAMZA ABOVE
    $line =~ s/\x{0625}/I/g;   ## ALEF WITH HAMZA BELOW
    $line =~ s/\x{0626}/Q/g;   ## YEH WITH HAMZA ABOVE
    $line =~ s/\x{0627}/A/g;    ## ALEF
    $line =~ s/\x{0628}/b/g;    ## BEH
    $line =~ s/\x{0629}/p/g;    ## TEH MARBUTA
    $line =~ s/\x{062A}/t/g;    ## TEH
    $line =~ s/\x{062B}/v/g;    ## THEH
    $line =~ s/\x{062C}/j/g;    ## JEEM
    $line =~ s/\x{062D}/H/g;    ## HAH
    $line =~ s/\x{062E}/x/g;    ## KHAH
    $line =~ s/\x{062F}/d/g;    ## DAL
    $line =~ s/\x{0630}/V/g;   ## THAL
    $line =~ s/\x{0631}/r/g;    ## REH
    $line =~ s/\x{0632}/z/g;    ## ZAIN
    $line =~ s/\x{0633}/s/g;    ## SEEN
    $line =~ s/\x{0634}/c/g;   ## SHEEN
    $line =~ s/\x{0635}/S/g;    ## SAD
    $line =~ s/\x{0636}/D/g;    ## DAD
    $line =~ s/\x{0637}/T/g;    ## TAH
    $line =~ s/\x{0638}/Z/g;    ## ZAH
    $line =~ s/\x{0639}/E/g;    ## AIN
    $line =~ s/\x{063A}/g/g;    ## GHAIN
    $line =~ s/\x{0640}/_/g;    ## TATWEEL
    $line =~ s/\x{0641}/f/g;    ## FEH
    $line =~ s/\x{0642}/q/g;    ## QAF
    $line =~ s/\x{0643}/k/g;    ## KAF
    $line =~ s/\x{0644}/l/g;    ## LAM
    $line =~ s/\x{0645}/m/g;    ## MEEM
    $line =~ s/\x{0646}/n/g;    ## NOON
    $line =~ s/\x{0647}/h/g;    ## HEH
    $line =~ s/\x{0648}/w/g;    ## WAW
    $line =~ s/\x{0649}/Y/g;    ## ALEF MAKSURA
    $line =~ s/\x{064A}/y/g;    ## YEH

    ## Diacritics
    $line =~ s/\x{064B}/F/g;    ## FATHATAN
    $line =~ s/\x{064C}/N/g;    ## DAMMATAN
    $line =~ s/\x{064D}/K/g;    ## KASRATAN
    $line =~ s/\x{064E}/a/g;    ## FATHA
    $line =~ s/\x{064F}/u/g;    ## DAMMA
    $line =~ s/\x{0650}/i/g;    ## KASRA
    $line =~ s/\x{0651}/X/g;   ## SHADDA
    $line =~ s/\x{0652}/o/g;    ## SUKUN
    $line =~ s/\x{0670}/e/g;   ## SUPERSCRIPT ALEF

    $line =~ s/\x{0671}/L/g;   ## ALEF WASLA
    $line =~ s/\x{067E}/P/g;    ## PEH
    $line =~ s/\x{0686}/J/g;    ## TCHEH
    $line =~ s/\x{06A4}/V/g;    ## VEH
    $line =~ s/\x{06AF}/G/g;    ## GAF

    return $line;
}



##################################################################################



=head3 convertSafeBWToBuckwalter

    MADATools::convertSafeBWToBuckwalter($line)
 
    Example of use:

    ## $line is in SafeBW
    $line = MADATools::convertSafeBWToBuckwalter($line);
    ## $line is now in Buckwalter


    This function directly converts a line in SafeBW directly to Buckwalter

=cut

sub convertSafeBWToBuckwalter {

    my ($line)= (@_);

    $line =~ s/C/\'/g;    # HAMZA
    $line =~ s/M/\|/g;    # ALEF MADDA ABOVE
    $line =~ s/Q/\}/g;    # YEH HAMZA ABOVE
    $line =~ s/V/\*/g;    # THAL
    $line =~ s/c/\$/g;    # SHEEN
    $line =~ s/L/\{/g;    # ALEF WASLA
    $line =~ s/e/\`/g;    # DAGGER ALEF
    $line =~ s/X/\~/g;    # SHADDA
    $line =~ s/O/\>/g;    # ALEF HAMZA ABOVE
    $line =~ s/W/\&/g;    # WAW HAMZA ABOVE
    $line =~ s/I/\</g;    # ALEF HAMZA BELOW

    return $line;
}


##################################################################################



=head3 convertSafeBWToUTF8

    MADATools::convertSafeBWToUTF8($line)
 
    Example of use:

    ## $line is in SafeBW
    $line = MADATools::convertSafeBWToUTF8($line);
    ## $line is now in UTF8


    This function directly converts a line in SafeBW directly to UTF8

    The output should be set to produce utf8, i.e., using:
       binmode OUT, ":utf8";
    or the equivalent.

=cut

sub convertSafeBWToUTF8 {

    my ($line)= (@_);

    $line =~ s/C/\x{0621}/g;   ## HAMZA
    $line =~ s/M/\x{0622}/g;   ## ALEF WITH MADDA ABOVE
    $line =~ s/O/\x{0623}/g;   ## ALEF WITH HAMZA ABOVE
    $line =~ s/W/\x{0624}/g;   ## WAW WITH HAMZA ABOVE
    $line =~ s/I/\x{0625}/g;   ## ALEF WITH HAMZA BELOW
    $line =~ s/Q/\x{0626}/g;   ## YEH WITH HAMZA ABOVE
    $line =~ s/A/\x{0627}/g;    ## ALEF
    $line =~ s/b/\x{0628}/g;    ## BEH
    $line =~ s/p/\x{0629}/g;    ## TEH MARBUTA
    $line =~ s/t/\x{062A}/g;    ## TEH
    $line =~ s/v/\x{062B}/g;    ## THEH
    $line =~ s/j/\x{062C}/g;    ## JEEM
    $line =~ s/H/\x{062D}/g;    ## HAH
    $line =~ s/x/\x{062E}/g;    ## KHAH
    $line =~ s/d/\x{062F}/g;    ## DAL
    $line =~ s/V/\x{0630}/g;    ## THAL
    $line =~ s/r/\x{0631}/g;    ## REH
    $line =~ s/z/\x{0632}/g;    ## ZAIN
    $line =~ s/s/\x{0633}/g;    ## SEEN
    $line =~ s/c/\x{0634}/g;    ## SHEEN
    $line =~ s/S/\x{0635}/g;    ## SAD
    $line =~ s/D/\x{0636}/g;    ## DAD
    $line =~ s/T/\x{0637}/g;    ## TAH
    $line =~ s/Z/\x{0638}/g;    ## ZAH
    $line =~ s/E/\x{0639}/g;    ## AIN
    $line =~ s/g/\x{063A}/g;    ## GHAIN
    $line =~ s/\_/\x{0640}/g;   ## TATWEEL
    $line =~ s/f/\x{0641}/g;    ## FEH
    $line =~ s/q/\x{0642}/g;    ## QAF
    $line =~ s/k/\x{0643}/g;    ## KAF
    $line =~ s/l/\x{0644}/g;    ## LAM
    $line =~ s/m/\x{0645}/g;    ## MEEM
    $line =~ s/n/\x{0646}/g;    ## NOON
    $line =~ s/h/\x{0647}/g;    ## HEH
    $line =~ s/w/\x{0648}/g;    ## WAW
    $line =~ s/Y/\x{0649}/g;    ## ALEF MAKSURA
    $line =~ s/y/\x{064A}/g;    ## YEH

    ## Diacritics
    $line =~ s/F/\x{064B}/g;    ## FATHATAN
    $line =~ s/N/\x{064C}/g;    ## DAMMATAN
    $line =~ s/K/\x{064D}/g;    ## KASRATAN
    $line =~ s/a/\x{064E}/g;    ## FATHA
    $line =~ s/u/\x{064F}/g;    ## DAMMA
    $line =~ s/i/\x{0650}/g;    ## KASRA
    $line =~ s/X/\x{0651}/g;    ## SHADDA
    $line =~ s/o/\x{0652}/g;    ## SUKUN
    $line =~ s/e/\x{0670}/g;    ## SUPERSCRIPT ALEF

    $line =~ s/L/\x{0671}/g;    ## ALEF WASLA
    $line =~ s/P/\x{067E}/g;    ## PEH
    $line =~ s/J/\x{0686}/g;    ## TCHEH
    $line =~ s/V/\x{06A4}/g;    ## VEH
    $line =~ s/G/\x{06AF}/g;    ## GAF

    return $line;


}

##################################################################################



=head3 convertBuckwalterToUTF8

    MADATools::convertBuckwalterToUTF8($line) 

    Example of use:

    ## $line is in Buckwalter
    $line = MADATools::convertBuckwalterToUTF8($line);
    ## $line is now in UTF8


    This function directly converts a line in Buckwalter directly to UTF8, without
    an intermediate CP1256 representation.

    The output should be set to produce utf8, i.e., using:
       binmode OUT, ":utf8";
    or the equivalent.

=cut

sub convertBuckwalterToUTF8 {

    my ($line)= (@_);
    $line =~ s/\'/\x{0621}/g;   ## HAMZA
    $line =~ s/\|/\x{0622}/g;   ## ALEF WITH MADDA ABOVE
    $line =~ s/\>/\x{0623}/g;   ## ALEF WITH HAMZA ABOVE
    $line =~ s/\&/\x{0624}/g;   ## WAW WITH HAMZA ABOVE
    $line =~ s/\</\x{0625}/g;   ## ALEF WITH HAMZA BELOW
    $line =~ s/\}/\x{0626}/g;   ## YEH WITH HAMZA ABOVE
    $line =~ s/A/\x{0627}/g;    ## ALEF
    $line =~ s/b/\x{0628}/g;    ## BEH
    $line =~ s/p/\x{0629}/g;    ## TEH MARBUTA
    $line =~ s/t/\x{062A}/g;    ## TEH
    $line =~ s/v/\x{062B}/g;    ## THEH
    $line =~ s/j/\x{062C}/g;    ## JEEM
    $line =~ s/H/\x{062D}/g;    ## HAH
    $line =~ s/x/\x{062E}/g;    ## KHAH
    $line =~ s/d/\x{062F}/g;    ## DAL
    $line =~ s/\*/\x{0630}/g;   ## THAL
    $line =~ s/r/\x{0631}/g;    ## REH
    $line =~ s/z/\x{0632}/g;    ## ZAIN
    $line =~ s/s/\x{0633}/g;    ## SEEN
    $line =~ s/\$/\x{0634}/g;   ## SHEEN
    $line =~ s/S/\x{0635}/g;    ## SAD
    $line =~ s/D/\x{0636}/g;    ## DAD
    $line =~ s/T/\x{0637}/g;    ## TAH
    $line =~ s/Z/\x{0638}/g;    ## ZAH
    $line =~ s/E/\x{0639}/g;    ## AIN
    $line =~ s/g/\x{063A}/g;    ## GHAIN
    $line =~ s/\_/\x{0640}/g;    ## TATWEEL
    $line =~ s/f/\x{0641}/g;    ## FEH
    $line =~ s/q/\x{0642}/g;    ## QAF
    $line =~ s/k/\x{0643}/g;    ## KAF
    $line =~ s/l/\x{0644}/g;    ## LAM
    $line =~ s/m/\x{0645}/g;    ## MEEM
    $line =~ s/n/\x{0646}/g;    ## NOON
    $line =~ s/h/\x{0647}/g;    ## HEH
    $line =~ s/w/\x{0648}/g;    ## WAW
    $line =~ s/Y/\x{0649}/g;    ## ALEF MAKSURA
    $line =~ s/y/\x{064A}/g;    ## YEH

    ## Diacritics
    $line =~ s/F/\x{064B}/g;    ## FATHATAN
    $line =~ s/N/\x{064C}/g;    ## DAMMATAN
    $line =~ s/K/\x{064D}/g;    ## KASRATAN
    $line =~ s/a/\x{064E}/g;    ## FATHA
    $line =~ s/u/\x{064F}/g;    ## DAMMA
    $line =~ s/i/\x{0650}/g;    ## KASRA
    $line =~ s/\~/\x{0651}/g;   ## SHADDA
    $line =~ s/o/\x{0652}/g;    ## SUKUN
    $line =~ s/\`/\x{0670}/g;   ## SUPERSCRIPT ALEF

    $line =~ s/\{/\x{0671}/g;   ## ALEF WASLA
    $line =~ s/P/\x{067E}/g;    ## PEH
    $line =~ s/J/\x{0686}/g;    ## TCHEH
    $line =~ s/V/\x{06A4}/g;    ## VEH
    $line =~ s/G/\x{06AF}/g;    ## GAF


    ## Punctuation should really be handled by the utf8 cleaner or other method
 #   $line =~ s/\xa2/\,/g; # comma
#    $line =~ s//\,/g; # comma
#    $line =~ s//\,/g;
#    $line =~ s//\;/g; # semicolon
#    $line =~ s//\?/g; # questionmark


    
#    return $UTF8_ENCODING_OBJ->encode($line) #Same as Encode::encode("utf8",$line), but faster since object already created
    return $line;

}


##################################################################################



=head3 convertBuckwalterToSafeBW

    MADATools::convertBuckwalterToSafeBW($line)
 
    Example of use:

    ## $line is in Buckwalter
    $line = MADATools::convertBuckwalterTpSafeBW($line);
    ## $line is now in SafeBW


    This function directly converts a line in Buckwalter directly to SafeBW, as
    defined in Nizar's book, except that Shadda (~) is represented as a X.

=cut

sub convertBuckwalterToSafeBW {

    my ($line)= (@_);

    $line =~ s/\'/C/g;    # HAMZA
    $line =~ s/\|/M/g;    # ALEF MADDA ABOVE
    $line =~ s/\}/Q/g;    # YEH HAMZA ABOVE
    $line =~ s/\*/V/g;    # THAL
    $line =~ s/\$/c/g;    # SHEEN
    $line =~ s/\{/L/g;    # ALEF WASLA
    $line =~ s/\`/e/g;    # DAGGER ALEF
    $line =~ s/\~/X/g;    # SHADDA
    $line =~ s/\>/O/g;    # ALEF HAMZA ABOVE
    $line =~ s/\&/W/g;    # WAW HAMZA ABOVE
    $line =~ s/\</I/g;    # ALEF HAMZA BELOW

    return $line;
}

##################################################################################

=head3 hex2dec

    MADATools::hex2dec($a)
 
    Example of use:

    my $dec = MADATools::hex2dec($hex)

    This function simply converts a hexidecimal string to a decimal value.   

=cut

sub hex2dec {
    my ($a)=@_;
    my $o=0;
    my @a=split('',$a);   
    for (my $i=(@a-1),my $x=0;$i>=0;$i--,$x++){
	$a[$i]=~s/a/10/i;
	$a[$i]=~s/b/11/i;
	$a[$i]=~s/c/12/i;
	$a[$i]=~s/d/13/i;
	$a[$i]=~s/e/14/i;
	$a[$i]=~s/f/15/i;
	
	$o+=$a[$i]*(16**$x);
    }
    return($o);
}


##################################################################################


=head3 uXXXX2unicode

    MADATools::uXXXX2unicode($a)
 
    Example of use:

    my $char = MADATools::uXXXX2unicode($ustring)

    Converts a unicode hex string (or concatenation of such strings) into a 
    character string.

=cut

sub uXXXX2unicode {
    my ($a)=@_;
    $a=~s/^u//;
    my @a=split('u',$a);
    for (my $i=0;$i<@a;$i++){
	$a[$i]=chr(&hex2dec($a[$i]));
    }
    $a=join('',@a);
    return($a);
}

##################################################################################


=head3 readUTF8CleanMap

    MADATools::readUTF8CleanMap($mapfile)
 
    Example of use:

    my $result = MADATools::readUTF8CleanMap($mapfilename);

    Given a UTF8 clean Map file (usually the standard map clean-utf8-MAP), read
    it into the global %CLEAN_UTF8_MAP variable (emptying out existing contents).

    Returns 1 if everything was read fine, returns 0 if there was a problem
    reading the file.

=cut

sub readUTF8CleanMap {
    my ($mapfile)=@_;
    my $result = 0;
    my $mapline;

    if( open(CLEANUTF8MAP, $mapfile ) ) {
	    
	%CLEAN_UTF8_MAP = ();
	binmode CLEANUTF8MAP, ":encoding(utf8)";   ## Causes data read from map file to be checked as valid utf-8
#	binmode CLEANUTF8MAP, ":utf8";
	while( $mapline = <CLEANUTF8MAP> ) {
	    chomp $mapline;
	    if (($mapline!~/^\#/)&&($mapline!~/^\s*$/)){
		my ($char,$action,$comment)=split(/\t+/,$mapline);
		    
		if ($char=~/^(u....)$/){ #single unicode 
		    $char="$1-$1";
		}
	
		if($char=~/^u(....)-u(....)$/){ #unicode range
		    my $start=&MADATools::hex2dec($1);
		    my $end=&MADATools::hex2dec($2);
			
		    if ($end<$start){
			die "MADATools::readUTF8CleanMap:  Error - In reading $mapfile, Found Wrong Range: $char :: Start=$start End=$end\n";
		    }
	    
		    for (my $i=$start; $i<=$end;$i++){
			my $m=chr($i);
			if ($action=~/^OK$/){
			    $CLEAN_UTF8_MAP{$m}=$m;
			}
			elsif($action=~/^DEL$/){
			    $CLEAN_UTF8_MAP{$m}="";
			}
			elsif($action=~/^SPC$/){
			    $CLEAN_UTF8_MAP{$m}=" ";
			}
			elsif($action=~/^u/){   #unicode sequence
			    $CLEAN_UTF8_MAP{$m}=&MADATools::uXXXX2unicode($action);
			}
			else{
			    $CLEAN_UTF8_MAP{$m}=$action;
			}    
		    }			
		}
		elsif( $char =~ /^INVALID$/ ) {
		    if( $action =~ /^SPC$/ ) { $CLEAN_UTF8_MAP{"INVALID"} = " "; }
		    elsif( $action =~ /^DEL$/ ) {$CLEAN_UTF8_MAP{"INVALID"} = ""; }
		    else { $CLEAN_UTF8_MAP{"INVALID"} = $action; }
		}
		elsif( $char =~ /^ELSE$/ ) {
		    if( $action =~ /^SPC$/ ) { $CLEAN_UTF8_MAP{"ELSE"} = " "; }
		    elsif( $action =~ /^DEL$/ ) {$CLEAN_UTF8_MAP{"ELSE"} = ""; }
		    else { $CLEAN_UTF8_MAP{"ELSE"} = $action; }
		}

	    }	       
	}

	$result = 1;
	close(CLEANUTF8MAP);
    }
	

    return $result;
}


##################################################################################


=head3 cleanUTF8String

    MADATools::cleanUTF8String( $result, $outstring )
 
    Example of use:

    my ($result,$newstring) = MADATools::cleanUTF8String($utf8string);

    Takes any UTF8 found in the input string and cleans it to a 'safe' subset
    of UTF8 that can be converted, etc. Requires that readUTF8CleanMap() be
    run first to populate the cleaning character map.

    This function attempts to use Encode::decode() to decode the utf8 in 
    in the input string, so the input string should be utf8 encoded. The output
    string will be encoded as utf8 using Encode::encode().

    Returned $result is 1 if everything was read fine, $result is 0 if the 
    the map in memory is empty (that is, readUTF8CleanMap() has not been run).

    This function also cleans whitespace, replace all strings of whitespace
    with a single space, and trimming whitespace from the beginning and end of
    the line.

=cut

sub cleanUTF8String {
    my ($instring) = @_;
    my $result = 0;
    my $outstring = "";

    ## Return 0 result in the case of an empty map
    if( scalar( keys %CLEAN_UTF8_MAP ) == 0 ) {
	return( $result, $outstring );
    }
    #else {  print STDERR "  NUMBER OF KEYS IN MAP = ", scalar(keys %CLEAN_UTF8_MAP), "\n"; }

#    foreach my $l (split(//, Encode::decode("utf8",$instring) )){
    foreach my $l (split(//,$instring )){

	if (not (utf8::valid($l))){
	    $outstring .= $CLEAN_UTF8_MAP{"INVALID"};
	}
	elsif (exists $CLEAN_UTF8_MAP{$l}){
	    $outstring .= $CLEAN_UTF8_MAP{$l};
	}
	else{
	    $outstring .= $CLEAN_UTF8_MAP{"ELSE"};
	}
    }

    $outstring = &MADATools::cleanWhitespace($outstring);
    $result = 1;

    return ($result, $outstring);
#    return ($result, Encode::encode("utf8",$outstring) );
}

##################################################################################

=head3 tagEnglishInString

    MADATools::tagEnglishInString( $in, $mode, $id )
 
    Example of use:

    my $out = MADATools::tagEnglishInString($utf8String,"tag","noid");
    ##  Words in $out with latin letters now tagged with @@LAT@@ prefix

    my $out2 = MADATools::tagEnglishInString($utf8String,"replace","noid");
    ##  Words in $out2 with latin letters now REPLACED with @@LAT@@

    my $out3 = MADATools::tagEnglishInstring($utf8String,"tag","id");
    ##  Words in $out3 with latin letters now tagged, but the first word in the string
    ##   is not tagged because it is assumed to be a sentence id

    Takes a string and, for every word found to have [A-Za-z] characters that doesn't
    already start with "@@" and gives them a @@LAT@@ prefix.

    The second argument can be "tag" or "replace". If given as "replace", then 
    the words with latin characters are removed and replaced with @@LAT@@.

    The third argument can be "noid" or "id". If given as "id", then the first word
    in the string is never tagged or replaced, regardless of its content, because it
    is assumed to be a sentence id.
    
    The second and third arguments are case-insensitive, and default to "tag" and
    "noid" respectively.


    NOTE:  If this is called on a Buckwalter string or English sentence, it will tag
    every word in the string.

=cut

sub tagEnglishInString {
    my($in,$mode,$id) = @_;

    if( ! defined $mode ) { $mode = "tag"; }
    if( ! defined $id ) { $id = "noid"; }

    if( $mode =~ /^noid|id$/i ) { $id = $mode; $mode = "tag"; }
    if( $mode !~ /^tag|replace$/i ) { $mode = "tag"; }
    if( $id !~ /^noid|id$/i ) { $id = "noid"; }

    my @w = split( /\s+/, $in );
    my $i;

    if( $id =~ /^id$/i ) { $id = 1; }
    else { $id = 0; }

    for( $i = $id; $i<=$#w; $i++ ) {

	if( $w[$i] =~ /[a-zA-Z]/ && $w[$i] !~ /^\@\@/ ) {
	    if( $mode =~ /^replace$/i ) {
		$w[$i] = '@@LAT@@';
	    }
	    else {
		$w[$i] = '@@LAT@@' . $w[$i];
	    }		
	}
    }

    return &MADATools::cleanWhitespace( join(' ', @w) );
}



##################################################################################



=head3 convertTaggedBuckwalterToUTF8

    MADATools::convertTaggedBuckwalterToUTF8( $in, $mode ) 

    Example of use:

    ## $line is in Buckwalter, which may have Latin words tagged with @@LAT@@
    $line = MADATools::convertTaggedBuckwalterToUTF8($line,"droptags");
    ## $line is now in UTF8, with @@LAT@@ dropped

    $line = MADATools::convertTaggedBuckwatlerToUTF8($line,"keeptags");
    ## $line is now in UTF8, with @@LAT@@ tags retained


    This function directly converts a line in Buckwalter directly to UTF8, without
    an intermediate CP1256 representation. It checks each word for a @@LAT@@
    prefix -- if it finds one, it does not convert the word to UTF8, and either
    drops the @@LAT@@ tag or retains it. The rest of the word is returned as is.

    The default of the second argument is "droptags".

    If the word only consists of @@LAT@@ (as might be the case if the tag function
    was set to "replace"), the word will be deleted entirely if "droptags" is 
    selected.


=cut

sub convertTaggedBuckwalterToUTF8 {
    my( $in, $mode ) = @_;
    if( ! defined $mode ) { $mode = "droptags"; }
    if( $mode !~ /^keeptags|droptags$/i ) { $mode = "droptags"; }

    my @w = split( /\s+/, $in );
    my $i;

    for($i=0; $i<=$#w; $i++ ) {

	if( $w[$i] =~ /^\@\@LAT\@\@/ ) {
	    if( $mode =~ /^droptags$/i ) {
		$w[$i] =~ s/^\@\@LAT\@\@//;
	    }
	}
	else {
	    $w[$i] = &MADATools::convertBuckwalterToUTF8($w[$i]);
	}
    }
    return &MADATools::cleanWhitespace( join(' ', @w) );
}



##################################################################################

=head3 separatePunctuationAndNumbers

    MADATools::separatePunctuationAndNumbers( $in, $format, $sentid )
 
    Example of use:

    my $out = MADATools::separatePuncutationAndNumbers($utf8String,"utf8");
    ##  Punctuation and numbers are now separated by whitespace; since the input is
    ##   utf8, Buckwalter forbidden characters like <>|&, etc. are also separated.

    my $out2 = MADATools::tagEnglishInStringAndNumbers($bwstring,"bw");
    ##  Punctuation and numbers are now separated by whitespace; since the input is
    ##   bw, Buckwalter forbidden characters like <>|&, etc. are NOT separated.


    Takes a string and a format argument, and outputs a string with numbers and
    punctuation separated by whitespace.

    If the format is "utf8" (case-insensitive), then Buckwalter punct characters
    like <>|&{} will also be separated.  If the format is "bw", then these
    characters will not be separated.

    The default format is "utf8".

    Numbers will be separated in such a way that commas or periods used as decimals
    are kept with the digits.  

    This function will not try to split any word prefixed with @@LAT@@, so 
    email addresses and urls should not be broken up.

    If the third argument ($sentid) is "yes", the first word in the string will be not be affected,
    and any punctuation or numbers in that word will remain as is.  The default value for
    this argument is "no".

    If possible, this function should be run on strings that have already passed through the
    clean-utf8 function (which will, for example, collapse various number forms to 
    ASCII digits, collapse comma forms to commas, etc.) and the tagEnglishInString
    function (so that latin strings with punctuation are not affected).


=cut

sub separatePunctuationAndNumbers {
    my($in,$format,$sentid) = @_;

    if( ! defined $format ) { $format = "utf8"; }
    if( $format =~ /^yes|no$/i ) { $sentid = $format; $format = "utf8"; }
    if( $format !~ /^utf-?8|bw|buckwalter$/i ) { $format = "utf8"; }
    
    if( ! defined $sentid ) { $sentid = "no"; }



    my @w = split( /\s+/, $in );
    my $i;
    my $out = "";

    foreach( $i=0; $i<=$#w; $i++ ) {

	my $word = $w[$i];

	if( $sentid =~ /^yes$/i && 0 == $i ) {
	    # Do nothing
	    
	}
	elsif( $word !~ /^\@\@LAT\@\@/ ) {

	    ## Flag cases where a number begins with a decimal/comma (ie, without a leading zero)
	    $word =~ s/(\s+)(\.)(\d)/$1SEPPUNCTMARKDECIMAL$3/g;
	    $word =~ s/(\s+)(\,)(\d)/$1SEPPUNCTMARKCOMMA$3/g;
	    $word =~ s/^(\.)(\d)/SEPPUNCTMARKDECIMAL$2/g;
	    $word =~ s/^(\,)(\d)/SEPPUNCTMARKCOMMA$2/g;

	    $word =~ s/([\-\=\"\_\:\#\@\!\?\^\/\(\)\[\]\%\;\\\+\.\,])/ $1 /g;

	    if( $format =~ /^utf-?8$/i ) {
		## Buckwalter-forbidden tokenizations
		$word =~ s/([\{\}\*\|\>\<\'\`\&\~\$])/ $1 /g;
	    }

	    ## Fix decimal points
	    $word =~ s/(\d)\s+([\,\.])\s+(\d)/$1$2$3/g;
	    $word =~ s/SEPPUNCTMARKDECIMAL/\./g;
	    $word =~ s/SEPPUNCTMARKCOMMA/\,/g;
	    
	    ## Separate numbers
	    $word =~ s/([^\d\.\,])(\d)/$1 $2/g;
	    $word =~ s/(\d)([^\d\.\,])/$1 $2/g;


	}

	$out .= "$word ";

    }


    return &MADATools::cleanWhitespace($out);
    
}


##################################################################################

=head3 isPunct

    MADATools::isPunct( $str )
 
    Example of use:

    if(  MADATools::isPunct( $str ) ) {
       # Process punctuation string
    }

    Returns true if the input string is a sequence of ASCII punctuation
    characters, not counting the Buckwalter reserved characters:

      {}<>|&$'`~*

    Returns false if other characters are present.

    Whitespace at the beginning and end of the word is ignored.

=cut 

sub isPunct {

    my ($str) = @_;
    my $result = 0;

    if( $str =~ /^\s*[\-\=\"\_\:\#\@\!\?\^\/\(\)\[\]\%\;\\\+\.\,]+\s*$/ ) {
	$result = 1;
    }

    return $result;

}


##################################################################################

=head3 makeXMLFriendly

    MADATools::makeXMLFriendly( $in )
 
    Example of use:

    $line = MADATools::makeXMLFriendly( $utf8string );
    ## $line is a copy of $utf8string, with problematic characters replaced

    This function replaces the characters in the input that would cause problems
    in XML with substitutes.

    It may garble standard Buckwalter encoded text, so should only be considered
    "safe" when run on UTF8 strings.

    The function only makes the following substitutions:

        &  -->  &amp;
        <  -->  &lt;
        >  -->  &gt;
        "  -->  &quot;
        '  -->  &apos;

    Also see the inverse function, unmakeXMLFriendly().

=cut 

sub makeXMLFriendly {
    my ($in) = @_;

    $in =~ s/\&/\&amp;/g;
    $in =~ s/\</\&lt;/g;
    $in =~ s/\>/\&gt;/g;
    $in =~ s/\"/\&quot;/g;
    $in =~ s/\'/\&apos;/g;

    return $in;    
}


##################################################################################

=head3 unmakeXMLFriendly

    MADATools::unmakeXMLFriendly( $in )
 
    Example of use:

    $line = MADATools::makeXMLFriendly( $xmlstring );
    ## $line is a copy of $xmlstring, with XML placeholders replaced

    This function replaces the characters in the input that are used as placeholders
    in XML formats with the ASCII equivalent.

    The function only makes the following substitutions:

        &amp;  --> &
        &lt;   --> <
        &gt;   --> >
        &quot; --> "
        &apos; --> '

    Also see the inverse function, makeXMLFriendly().

=cut 

sub unmakeXMLFriendly {
    my ($in) = @_;

    $in =~ s/\&amp;/\&/g;
    $in =~ s/\&lt;/\</g;
    $in =~ s/\&gt;/\>/g;
    $in =~ s/\&quot;/\"/g;
    $in =~ s/\&apos;/\'/g;

    return $in;    
}



##################################################################################

=head3 convertNewMADAPOSToOldMADAPOS

    MADATools::convertNewMADAPOSToOldMADAPOS($newpos)
 
    Example of use:

    my $oldpos = MADATools::convertNewMADAPOSToOldMADAPOS($newpos)

    This function simply reduces a member of the new POS tagset used in MADA 3.0+
    to the equivalent POS tag used in MADA 2.32 or earlier.

    If the provided POS tag is not member of the current POS tagset, an empty
    string is returned.

=cut

sub convertNewMADAPOSToOldMADAPOS {
    my ($new)=@_;
    my $old = "";

    $new = lc($new);
    $new =~ s/^\s+|\s+$//g;
    
    if( exists $MADAPOSTagMap{$new} ) {
	$old = $MADAPOSTagMap{$new};
    }
   
    return($old);
}





##################################################################################

=head3 mapNewFeatValToOldFeatVal

    MADATools::mapNewFeatValToOldFeatVal($feature,$newval)
 
    Example of use:

    my $reducedval = MADATools::mapNewFeatValToOldFeatVal($feature,$newval)

    Given a feature and a value used under MADA 3.0+, this function simply reduces 
    the value to the equivalent value tag used in MADA 2.32 or earlier.

    Returns the same value if the feature or new value is not recognized
    (expect for POS features, in which case an empty string is returned).

    Note that for the stt feature the returned value is a combination
    of the old def and idafa features in the form "defvalue-idafavalue".
  

=cut


sub mapNewFeatValToOldFeatVal {
    ## Given a feature and a value, return the old-style equivalent value

    my ($feature, $val) = @_;

    my $ret = $val;

    if( $feature eq "asp" ) {
	if( $val eq "c" )     { $ret = "CV";  }
	elsif( $val eq "i" )  { $ret = "IV";  }
	elsif( $val eq "p" )  { $ret = "PV";  }
	elsif( $val eq "na" ) { $ret = "NA";   }
    }
    elsif( $feature eq "cas" ) { 
	if( $val eq "n" )     { $ret = "NOM";  }
	elsif( $val eq "a" )  { $ret = "ACC";  }
	elsif( $val eq "g" )  { $ret = "GEN";  }
	elsif( $val eq "na" ) { $ret = "NA";   }
	elsif( $val eq "u" )  { $ret = "NOCASE"; }  ## Undefined
    }
    elsif( $feature eq "enc0" ) {
	if( $val eq "0" )     { $ret = "NO"; }
	elsif( $val eq "na" ) { $ret = "NA"; }
	else                  { $ret = "YES"; }   ## clitic = YES
    }
    elsif( $feature eq "gen" ) {
	if( $val eq "f" )     { $ret = "FEM"; }
	elsif( $val eq "na")  { $ret = "NA";  }
	elsif( $val eq "m" )  { $ret = "MASC"; }
    }
    elsif( $feature eq "mod" ) {
	if( $val eq "i" )     { $ret = "I"; }
	elsif( $val eq "j" )  { $ret = "J"; }
	elsif( $val eq "s" )  { $ret = "S"; }
	elsif( $val eq "na" ) { $ret = "NA"; }
	elsif( $val eq "u" )  { $ret = "I"; }   ## Undefined
    }
    elsif( $feature eq "num" ) {
	if( $val eq "s" )     { $ret = "SG"; }
	elsif( $val eq "p" )  { $ret = "PL"; }
	elsif( $val eq "d" )  { $ret = "DU"; }
	elsif( $val eq "na" ) { $ret = "NA"; }
	elsif( $val eq "u")   { $ret = "SG"; }  ## Undefined
    }
    elsif( $feature eq "per" ) {
	if( $val eq "1" )    { $ret = "1"; }
	elsif( $val eq "2" ) { $ret = "2"; }
	elsif( $val eq "3" ) { $ret = "3"; }
	elsif( $val eq "na") { $ret = "NA"; }
    }
    elsif( $feature eq "pos" ) {
	$ret = &MADATools::convertNewMADAPOSToOldMADAPOS( $val );
    }
    elsif( $feature eq "prc0" ) {
	if( $val eq "0" )     { $ret = "NO"; }
	elsif( $val eq "na" ) { $ret = "NA"; }
	else                  { $ret = "YES"; }   ## art = YES
    }
    elsif( $feature eq "prc1" ) {
	if( $val eq "0" )     { $ret = "NO"; }
	elsif( $val eq "na" ) { $ret = "NA"; }
	else                  { $ret = "YES"; }   ## part = YES
    }
    elsif( $feature eq "prc2" ) {
	if( $val eq "0" )     { $ret = "NO"; }
	elsif( $val eq "na" ) { $ret = "NA"; }
	else                  { $ret = "YES"; }   ## conj = YES
    }
    elsif( $feature eq "prc3" ) {
	$ret = $val;
    }
    elsif( $feature eq "stt" ) {
	if( $val eq "i" )     { $ret = "INDEF-NOPOSS"; }
	elsif( $val eq "d" )  { $ret = "DEF-NOPOSS";   }
	elsif( $val eq "c" )  { $ret = "DEF-POSS";     }
	elsif( $val eq "na" ) { $ret = "NA-NA";        }
	elsif( $val eq "u" )  { $ret = "DEF-NOPOS";    }

    }
    elsif( $feature eq "vox" ) {
	if( $val eq "a" )     { $ret = "ACT";  }
	elsif( $val eq "p" )  { $ret = "PASS"; }
	elsif( $val eq "na" ) { $ret = "NA";   }
	else                  { $ret = "ACT"; }  ## Undefined

    }



    return $ret;

}

##################################################################################

=head3 report

    MADATools::report($message,$type,$quiet)
 
    Example of use:

    MADATools::($message, $type, $quiet);

    Causes a log message to be printed to STDERR. 

    Type can be 'warn', 'error', or 'info'. If $quiet == 1, only error types
    will be printed.

=cut

sub report {
    my ( $message, $type, $quiet ) = @_;
    my $out = $message;
    if( ! defined $type ) { $type = "info"; }
    if( ! defined $quiet ) { $quiet = 0; }
    
    if( $type =~ /error/i ) {
	$out = "$0: Error - $out\n";
	print STDERR $out;
    } elsif( ! $quiet ) {
	if( $type =~ /warn/i ) {
	    $out = "$0: Warning - $out";
	} elsif( $type =~ /info/i ) {
	    $out = "$0: $out";
	}
	print STDERR "$out\n"
    }
}


##################################################################################

=head1 KNOWN BUGS

    Currently in Development.  No bugs known.

=cut

=head1 SEE ALSO

    MADAWord, TOKAN, ALMOR3

=cut

=head1 AUTHOR

    Ryan Roth, Nizar Habash, Owen Rambow
    
    Center for Computational Learning Systems
    Columbia University
    
    Copyright (c) 2007,2008,2009,2010 Columbia University in the City of New York

=cut

1;
