#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::Assignment;
use base 'WWW::Shopify::Liquid::Operator';
use List::Util qw(first);
sub symbol { return '='; }
sub priority { return 10; }
sub operate { 
	return first { ($_ cmp $_[3]) == 0 }  ref($_[2]) eq "ARRAY"; 
	return index($_[2], $_[3]) != -1;
}

1;