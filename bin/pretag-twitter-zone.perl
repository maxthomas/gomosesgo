#!/usr/bin/env perl

# Tag tweets, urls, etc for pretranslation in moses
# Optionally uses glossary for certain tag types (hashtags)

use FindBin qw($RealBin);
use strict;
use utf8;

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my @protected_patterns = ();
my @protected_labels = ();
my $protected_patterns_file = "";

my $HELP = 0;

while (@ARGV)
{
    $_ = shift;
    /^-b$/ && ($| = 1, next);
    /^-h$/ && ($HELP = 1, next);
    /^-protected/ && ($protected_patterns_file = shift, next);
}

# print help message
if ($HELP)
{
    print "Usage ./pretag-twitter-gloss.perl < textfile > taggedfile\n";
    print "Options:\n";
    print "  -b     ... disable Perl buffering.\n";
    print "  -protected FILE  ... specify file with patters to be protected in tokenisation.\n";
    exit;
}

# needs LABEL<TAB>REGEX format!
if ($protected_patterns_file)
{
  open(PP,$protected_patterns_file) || die "Unable to open $protected_patterns_file";
  binmode(PP, ":utf8");
  while(<PP>) {
    chomp;
    my @fields = split /\t/, $_;
    push @protected_patterns, $fields[1];
    push @protected_labels, $fields[0];
    
  }
  print STDERR scalar(@protected_patterns) . " patterns loaded\n";
  close PP;
}

while(<STDIN>) {
    
    my $text = $_;
    chomp $text;

    # Find protected patterns
    my @protected = ();
    my @protlabel = ();

    #foreach my $protected_pattern (@protected_patterns) {
    for my $i ( 0 .. $#protected_patterns ) {

	#shorthand plz
	my $protected_pattern = $protected_patterns[$i];
	my $protected_label = $protected_labels[$i];
	my $t = $text;
	#while ($t =~ /($protected_pattern)(.*)$/) {
	while ($t =~ /($protected_pattern)/) {
	    push @protected, $1;
	    push @protlabel, $protected_label;
	    $t =~ s/$1//;
	    #$t =~ s/\Q$1\E//;
	}
    }

    #we do this to avoid patterns stomping on each other...
    for (my $i = 0; $i < scalar(@protected); ++$i) {
      my $subst = sprintf("THISISPROTECTED%.3d", $i);
      $text =~ s,\Q$protected[$i], $subst ,g;
    }
    $text =~ s/ +/ /g;
    $text =~ s/^ //g;
    $text =~ s/ $//g;

    # restore patterns finally
    for (my $i = 0; $i < scalar(@protected); ++$i) {
	my $label = $protlabel[$i];
	my $prot  = $protected[$i];
	my $trans = $prot;
	#gloss_lookup($prot, $label);
	my $subst = sprintf("THISISPROTECTED%.3d", $i);
	my $tagged = "";
	if($label eq "HASHTAG") {
	    
	    #remove hash
	    $prot =~ s/^#//;
	    my @pieces = split /_/, $prot ;
	    #gotta do it this way otherwise we get reordered like crazy
	    $tagged = "<zone> <ht translation=\"#BEGIN\">#BEGIN</ht> <wall /> " . join(" ", @pieces) . " <wall /> <ht translation=\"#END\">#END</ht></zone>";
	    #original variant - hash mark+end don't stay put
	    #$tagged = "<zone> <ht translation=\"#\">#</ht> " . join(" ", @pieces) . " <ht translation=\"#END\">#END</ht></zone>";
	    #Variant B
	    #$tagged = "<ht translation=\"#\">#</ht> <zone> " . join(" ", @pieces) . "</zone> <ht translation=\"#END\">#END</ht>";
	}
	else {
	    $tagged = sprintf("<%s translation=\"%s\">%s</%s>", $label, $trans, $prot, $label);
	}
	$text =~ s/$subst/$tagged/g;
    }
    $text =~ s/ +/ /g;
    $text =~ s/^ //g;
    $text =~ s/ $//g;


    print $text . "\n";
    
    #dbg
    #exit(1);
}
