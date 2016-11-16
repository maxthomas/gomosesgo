#!/usr/bin/perl

### NOTE: THE FUNCTIONALITY OF THIS CODE IS ALSO PRESENT IN THE MADATools.pm LIBRARY

#######################################################################
# clean-utf8.pl <MAP> printmap? <STDIN>                  (Nizar Habash)
#######################################################################
# Copyright (c) 2005,2006,2007,2008,2009,2010 Columbia University in 
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
# This code cleans up UTF8 files before passing them on to other
# processing steps.  It takes a file <MAP> as input specifying 
# what characters are mapped to.
#
#MAP has the following format
#
#<CHAR><tab><ACTION><tab><COMMENT>
#
#<CHAR> can be
#    unicode char specifier: uXXXX (e.g. u0020)
#    unicode char range: uXXXX-uYYYY (e.g. u0600-u0610)
#    INVALID: a reserved word indicating what action to take with 
#             invalid UTF8 chars
#    ELSE: a reserved word indicating what action to take for unspecified chars
#
#<ACTION> can be
#    OK: map char to itself
#    DEL: delete char
#    SPC: map char to space
#    <ascii symbol>+ one or more ascii symboles (e.g. !, !?)
#    <unicode specifies>+ (e.g. u0200 or u0644u0645)
#
#The input is passed through STDIN and output is STDOUT
#The special parameter printmap forces the script to abort after printing an html
#file showing the expanded map.
#
#No tokenization is done except that adjacent multiple spaces and initial 
#and final spaces are deleted.
#
#KNOWN CURRENT LIMITATIONS
#    - Maps only from single character (to zero,one or more chars); 
#      but no multi-character mapping
#######################################################################

use utf8;
use Encode;
use strict;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
binmode STDIN, ":utf8";

my $argc  = @ARGV;
die "Usage: $0 <char_map> printmap?\n"
    if ($argc < 1);

my $map = $ARGV[0];
my $printmap = $ARGV[1];
my %MAP =();

open(MAP, "$map")|| die "Cannot open file $map\n";

binmode MAP, ":utf8";

while (my $mapline=<MAP>){
    
    if (($mapline!~/^\#/)&&($mapline!~/^\s*$/)){
	my ($char,$action,$comment)=split(/\t+/,$mapline);
	
	if ($char=~/^(u....)$/){ #single unicode 
	    $char="$1-$1";
	}
	
	if($char=~/^u(....)-u(....)$/){ #unicode range
	    my $start=&hex2dec($1);
	    my $end=&hex2dec($2);
	    
	    if ($end<$start){
		die "Wrong Range: $char :: Start=$start End=$end\n";
	    }
	    
	    for (my $i=$start; $i<=$end;$i++){
		my $m=chr($i);
		if ($action=~/^OK$/){
		    $MAP{$m}=$m;
		}elsif($action=~/^DEL$/){
		    $MAP{$m}="";
		}elsif($action=~/^SPC$/){
		    $MAP{$m}=" ";
		}elsif($action=~/^u/){   #unicode sequence
		    $MAP{$m}=uXXXX2unicode($action);
		}else{
		    $MAP{$m}=$action;
		}    
		#print "$m ==> $MAP{$m} <br> \n";
	    }
	    
	}
    }
}

#If PRINTMAP is turned on, we do not convert, but just produce an html of the map; and then quit.
if ($printmap=~/printmap/i){
    print "<html><body>\n";
  
    print "Total symbols handled = ";
    my $x=(keys %MAP);
    print "$x <br>\n";

    print "<table>\n";
    print "<tr><td>MAP-FROM</td><td>MAP-TO</td></tr>\n";
    foreach my $key (sort (keys %MAP)){
	print "<tr><td>$key</td><td>$MAP{$key}</td></tr>\n";
    }
    print "<\/body>\n";
    print "<\/table>\n";
    print "<\/html>\n";
    exit;
}else{ # convert input
    
    while (my $line=<STDIN>){
	chomp ($line);
	my $newline="";

	foreach my $l (split(//,$line)){
	    if (not (utf8::valid($l))){
		$newline.=$MAP{"INVALID"};
	    }elsif (exists $MAP{$l}){
		$newline.=$MAP{$l};
	    }else{
		$newline.=$MAP{"ELSE"};
	    }
	}
	$newline=~s/^\s+//g;
	$newline=~s/\s+$//g;
	$newline=~s/\s+/ /g;
	print "$newline\n";
    }
}


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


