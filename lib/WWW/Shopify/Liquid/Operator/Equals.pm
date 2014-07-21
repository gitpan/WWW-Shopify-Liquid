#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::Equals;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return '=='; }
sub priority { return 5; }
use Data::Compare;
sub operate { 
	my ($self, $hash, $action, $op1, $op2) = @_;
	return $op1 == $op2 if (ref($op1) && ref($op2) && ref($op1) eq "DateTime" && ref($op2) eq "DateTime");
	return Compare($op1, $op2) if (ref($op1) && ref($op2));
	return ($op1 cmp $op2) == 0;
}

1;