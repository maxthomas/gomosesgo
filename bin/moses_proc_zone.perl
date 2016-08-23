#!/usr/bin/env perl

#zone/wall tokenizer

use strict;
use utf8;
use FindBin qw($RealBin);
use Time::HiRes qw ( time );

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
	if($f =~ /^</ && $f ne "<wall") {
	    
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
	elsif($f =~ /<\/[a-zA-Z0-9]+>$/ || $f eq "/>") {

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
	    push @procout, $o;
	}
	#tokenize,
	else {

	    my $input = tokenize($o);
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

#selected guts of the moses tokenizer
# doesn't do non-breaking yet, but should
sub tokenize
{
    my($text) = @_;

    chomp($text);
    $text = " $text ";

    # remove ASCII junk
    $text =~ s/\s+/ /g;
    $text =~ s/[\000-\037]//g;

    #fix spacing
    $text =~ s/ +/ /g;
    $text =~ s/^ //g;
    $text =~ s/ $//g;

    # separate out all "other" special characters
    $text =~ s/([^\p{IsAlnum}\s\.\'\`\,\-])/ $1 /g;

    # separate out "," except if within numbers (5,300)
    # previous "global" application skips some:  A,B,C,D,E > A , B,C , D,E
    # first application uses up B so rule can't see B,C
    # two-step version here may create extra spaces but these are removed later
    # will also space digit,letter or letter,digit forms (redundant with next section)
    $text =~ s/([^\p{IsN}])[,]/$1 , /g;
    $text =~ s/[,]([^\p{IsN}])/ , $1/g;

    #contraction hack - add the moses guts
    #back if you're 
    $text =~ s/\'/ \' /g;

    # clean up extraneous spaces
    $text =~ s/ +/ /g;
    $text =~ s/^ //g;
    $text =~ s/ $//g;

    return lc($text);
}
