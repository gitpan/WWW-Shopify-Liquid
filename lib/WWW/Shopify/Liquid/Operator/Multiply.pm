#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::Multiply;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return '*'; }
sub priority { return 4; }
sub operate { return $_[2] * $_[3]; }

1;