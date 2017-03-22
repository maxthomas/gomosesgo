#!/usr/bin/env perl
#
# Remove NRC-style OOV tags

use warnings;
use strict;
use utf8;

$|++;

while(<STDIN>) {

    s/<OOV>//g;
    s/<\/OOV>//g;

    # clean up extraneous spaces
    s/ +/ /g;
    s/^ //g;
    s/ $//g;

    print $_;
}
