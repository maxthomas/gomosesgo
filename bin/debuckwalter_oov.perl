#!/usr/bin/env perl
# @file postdecode_plugin
# @brief This plugin unbuckwalterizes.
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2015, Sa Majeste la Reine du Chef du Canada /
# Copyright 2015, Her Majesty in Right of Canada

# SCREAM dep locations
# use lib '/tools/cpan/lib64/perl5';
# use lib '/Users/jgwinnup/work/qcr-1.8/lib/perl5/site_perl/5.18.2/darwin-thread-multi-2level';

use FindBin qw($RealBin);
use Encode;
use Encode::Arabic::Buckwalter;

binmode(STDIN, ":encoding(UTF-8)");
binmode(STDOUT, ":encoding(UTF-8)");

my @protected_patterns = ();
my $protected_patterns_file = "$RealBin/fixed-twitter-protected-patterns";

#flush!
$|++;

# Borrowed from Moses Tokenizer
# Load protected patterns
if ($protected_patterns_file)
{
  open(PP,$protected_patterns_file) || die "Unable to open $protected_patterns_file";
  while(<PP>) {
    chomp;
    push @protected_patterns, $_;
  }
  print STDERR scalar(@protected_patterns) . " patterns loaded\n";
}

while(<STDIN>) {
   s#<OOV>(.*?)</OOV>#"<OOV>" . unbuckwalterize($1) . "</OOV>"#gex;
   #s#<OOV>(.*?)</OOV>#unbuckwalterize($1)#gex;
   print;
}

sub unbuckwalterize {
   my $word = $1;
   
   #see if word matches a pattern
   foreach my $protected_pattern (@protected_patterns) {

       if ($word =~ /$protected_pattern/) {
	   print STDERR "Found pattern: $protected_pattern\n";
	   return $word;
       }
   }

   # Special case for ISIS.
   return "ISIS" if ($word eq "dAE\$");

   # Need plain format for debuckwalterizing.
   $word =~ s/&lt;/</g;
   $word =~ s/&gt;/>/g;
   $word =~ s/&amp;/&/g;

   return decode("Buckwalter", $word);
}
