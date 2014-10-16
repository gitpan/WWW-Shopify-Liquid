#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::Assignment;
use base 'WWW::Shopify::Liquid::Operator';
use List::Util qw(first);
sub symbol { return '='; }
sub priority { return 1; }
sub operate { 
	return first { ($_ cmp $_[4]) == 0 }  ref($_[3]) eq "ARRAY"; 
	return index($_[3], $_[4]) != -1;
}

1;