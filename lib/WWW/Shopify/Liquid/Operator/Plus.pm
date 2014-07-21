#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::Plus;
use base 'WWW::Shopify::Liquid::Operator';
use Scalar::Util qw(looks_like_number);
sub symbol { return '+'; }
sub priority { return 9; }
sub operate { 
	return $_[3] . $_[4] if !looks_like_number($_[3]);
	return $_[0]->ensure_numerical($_[3]) + $_[0]->ensure_numerical($_[4]);
}

1;