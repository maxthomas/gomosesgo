#!/usr/bin/env perl

# Remix NRC's fastMada processing to be more friendly for our Moses
# setup
# Hax to allow <wall /> tags to pass through

# SCREAM dep locations
#use lib '/tools/MADA/MADA-3.2';
#use lib '/tools/NRC';

use strict;
use utf8;
use FindBin qw($RealBin);
use Time::HiRes qw ( time );
use MADA::MADATools;
use JSON;

#no buffering
$|++;

# This is a utf8 handling script => io should be in utf8 format
# ref: http://search.cpan.org/~tty/kurila-1.7_0/lib/open.pm
# We need UTF-8 to be able to properly lowercase the input.
use open IO => ':encoding(utf-8)';
use open ':std';  # <= indicates that STDIN and STDOUT are utf8

#utf8
#binmode(STDIN, ":utf8");
#binmode(STDOUT, ":utf8");
#binmode(STDERR, ":utf8");

#SCREAM customization
my $SCREAM_MADA = "$RealBin/MADA-3.2";

BEGIN { push(@INC, $RealBin) }
use tokenize::Arabic::Data;
warn "Using ", $INC{'tokenize/Arabic/Data.pm'}, " for the tokenization\n";

#mada mada mada
my $MADA_HOME = $ENV{MADA_HOME} || $SCREAM_MADA;
print STDERR "MADA_HOME is $MADA_HOME\n";
die "You must define MADA_HOME" unless(defined($MADA_HOME));

# Parse tokan stuff.
my $sep = "·";
my $oov = undef;
my $nolc = 0;

#load mada stuff
loadMADACleanUpMap("$MADA_HOME/common-tasks/clean-utf8-MAP");
my $word2morpho = loadMappingData();

#
# The fun part
#
while(my $line = <STDIN>) {
    
    chomp $line;

    #output sentence
    my @out = ();
    my @fragments = split /\s+/, $line;

    my $inTag = 0;
    my @outfrag = ();
    foreach my $f (@fragments) {
	#debug
	#print "frag: '$f'\n";
	
	#check to see if we're starting a tag
	if($f =~ /^</) { #  && $f ne "<wall") {
	    
	    #if outfrag is not empty flush it to out -
	    #we're done with that stretch
	    if(scalar(@outfrag) > 0 ) {

		push @out, join(" ", @outfrag);

		#empty, move on
		@outfrag = ();
	    }
	    
	    #add fragment
	    push @outfrag, $f;
	}

	#closing tag
	elsif(($f =~ /<\/[a-zA-Z0-9]*>$/) || ($f eq "/>")) {

	    push @outfrag, $f;

	    push @out, join(" ", @outfrag);

	    @outfrag = ();
	}
	#default
	else {
	    push @outfrag, $f;
	}
	

    }

    #check for leftovers
    if(scalar(@outfrag) > 0 ) {
	push @out, join(" ", @outfrag);
    }

    my @procout = ();
    foreach my $o (@out) {
	
	#XML
	if($o =~ /^</ ) {
	    push @procout, $o;
	}
	#ending of wall tag
	elsif($o =~ /\/>$/){
	    print STDERR "end of wall: '$o'\n";
	    push @procout, $o;
	}
	#NRC Processing
	else {

	    my $input = $o;
	    # Need plain format for buckwalterizing.
	    # This should be  harmless in any case.
	    # We will escape entity after buckwalterizing.
	    $input =~ s/&lt;/</g;
	    $input =~ s/&gt;/>/g;
	    $input =~ s/&amp;/&/g;

	    $input = HowardsPrepro($input);
	    $input = MADAsPrepro($input);
	    $input = parse_tokan($input);
	    $input = tokenizeArabic($input, $word2morpho);

	    #re-escape so moses doesn't barf
	    $input =~ s/</&lt;/g;
	    $input =~ s/>/&gt;/g;
	    $input =~ s/&/&amp;/g;

	    #add to output
	    push @procout, $input;
	}

    }

    #write processed fragments
    print join(" ", @procout) . "\n";
    
    #print "Outfrags:\n";
    #foreach my $f (@out) {
    #	print $f . "\n";
    #}
    
}


# Load MADA's clean up map.
sub loadMADACleanUpMap {
    my $cleanUpMapFile = shift or die "You must provide the location of MADA's clean up map file.";
    my $now_fractions = time;
    if( &MADATools::readUTF8CleanMap($cleanUpMapFile) != 1 ) {
	die "$0: Error - Unable to read UTF-8 cleaning map file $cleanUpMapFile\n";
    }
    printf(STDERR "Loaded clean-up map in %3.3fms\n", 1000 * (time - $now_fractions));
}

sub MADAsPrepro {
   my $input = shift;
   die "You need to provide a sentence." unless(defined($input));

   my $result = 1;
   ($result, $input) =  &MADATools::cleanUTF8String($input);

   die "$0: Error - Empty UTF8 cleaning map file discovered.\n" if ( $result != 1 );

   $input = &MADATools::tagEnglishInString($input, "tag", "noid");
   $input = &MADATools::separatePunctuationAndNumbers($input, "utf-8", "no");
   $input = &MADATools::convertUTF8ToBuckwalter($input);

   return $input;
}

sub loadMappingData {
   my $word2morpho = undef;
   # Load Buckwalter's map.
   warn "Using ", $INC{'tokenize/Arabic/Data.pm'}, " for the tokenization\n";
   my $now_fractions = time;
   $word2morpho  = decode_json( do { local $/; <tokenize::Arabic::Data::DATA>; } );
   printf(STDERR "Loaded morphology in %3.3fms\n", 1000 * (time - $now_fractions));

   return $word2morpho;
}

sub HowardsPrepro {
   my $input = shift;
   die "You need to provide a sentence." unless(defined($input));

   $input =~ s/[\r]?\n$/ /;
   $input =~ s/^/ /;
   $input =~ s/(\p{Script:Arabic}\p{General_Category:Mark}*)([^\p{Script:Arabic}\p{General_Category:Mark}])/$1 $2/g;
   $input =~ s/([^\p{Script:Arabic}\p{General_Category:Mark}])(\p{Script:Arabic}\p{General_Category:Mark}*)/$1 $2/g;
   $input =~ s/  +/ /g;
   $input =~ s/^ //;
   $input =~ s/ $//;

   return $input;
}

sub parse_tokan {
   my $in = shift;
   die "You need to provide a sentence." unless(defined($in));

   my @in = split(/\s+/, $in);
   # Remove the <\/?non-MSA> tags which are part of a token, or the entire
   # token if there is no content other than the tag.
   my @inclean = ();
   foreach my $i (@in){
      $i =~ s/\<non-MSA\>//g;
      $i =~ s/\<\/non-MSA\>//g;
      if ( $i !~ m/^\@\@LAT$sep/){
         push(@inclean, $i);
      }
   }

#   # Escape the middle dots that are not used as separators.  But occur within
#   # words that have not been analyzed
   return join(" ", map { &normalize($_) } @inclean);
}

sub normalize {
   my ($in) = @_;
   my $out = $in;
   if ($out =~ s/\@\@LAT\@\@//g) {
      #unless ($skipTokenization) {
      #   my $para = $out;
      #   $out = '';
      #   my @token_positions = tokenize($para, $pretok, $xtags);
      #   for (my $i = 0; $i < $#token_positions; $i += 2) {
      #      $out .= " " if ($i > 0);
      #      $out .= get_collapse_token($para, $i, @token_positions, $notok || $pretok);
      #   }
      #   chomp($out);
      #}
      $out = lc($out) unless($nolc);
   }
   elsif ($oov) {
      return undef;
   }

   $out =~ s/\@\@//g;
   return $out;
}

sub tokenizeArabic {
   my $input = shift;
   die "You need to provide a sentence." unless(defined($input));

   my $word2morpho = shift;
   die "You need to provide a mapping." unless(defined($word2morpho));

   chomp($input);
   # Glue words that ends with a sinble + to its successor.
   $input =~ s/(?<!^)(?<! )(?<!\+)\+ /+/g;
   # Glue words that starts with a sinble + to its predecessor.
   $input =~ s/ \+(?! |\+$)/+/g;


   return join(" ",
        map {
           s/\+/+ /g;
           s/\+/ +/g;
           $word2morpho->{$_} or $_
         } split(/ /, $input));

   my @tok = map { s/\+/+ /g; s/\+/ +/g; $_ } split(/ /, $input);

   my @output;
   foreach my $tok (@tok) {
       # NOTE: using this instead of the if exists means that a word mapping to
       # the empty string will behave has a passthrough instead of a deletion.
       push(@output, ($word2morpho->{$tok} or $tok));

#      if (exists($map->{$tok})) {
#         push(@output, $map->{$tok});
#      }
#      else {
#         #push(@output, "<UNDEFINED>" . $tok . "</UNDEFINED>");
#         push(@output, $tok);
#      }
   }

   return join(" ", @output);
}
