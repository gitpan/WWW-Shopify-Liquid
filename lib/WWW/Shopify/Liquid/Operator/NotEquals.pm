#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::NotEquals;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return '!='; }
sub priority { return 5; }
sub operate { return ($_[2] cmp $_[3]) != 0; }

1;