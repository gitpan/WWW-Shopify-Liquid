#!/usr/bin/perl

use strict;
use warnings;

# Used in our AST to keep things simple; represents the concatenation of text and other stuff.
package WWW::Shopify::Liquid::Operator::Concatenate;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return (); }
sub operate {
	my ($self, $hash, $action, $op1, $op2) = @_;
	return $op1 . $op2;
}
sub new { return bless { }, $_[0]; }

1;