#!/usr/bin/env perl
#
# Remove NRC-style OOV tags

#use warnings;
#use strict;
use utf8;

#utf-8
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

#flush
$|++;

while(my $row = <STDIN>) {

    my @outrow = ();
    
    chomp $row;
    my @words = split /\s+/, $row;
    
    my @tag = ();
    while(my $word = shift @words) {
	
	#if hashtag, consume tokens
	if($word eq "#BEGIN") {
	    
	    push @tag, "#";
	    my $tagpiece = "";

	    while( (($tagpiece = shift @words) ne "#END") && (scalar(@words >0)) ) {
		
		#$tagpiece 

		push @tag, $tagpiece;
	    }
	    
	    my $outtag = join("_", @tag);
	    $outtag =~ s/^#_/#/;
	    #print STDERR "Tag: $outtag\n";
	    push @outrow, $outtag;
	    @tag = ();
	}
	else {
	    push @outrow, $word;
	}

    }
    
    print join(" ", @outrow) . "\n";
}
