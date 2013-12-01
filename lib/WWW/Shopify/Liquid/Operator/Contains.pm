#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::Contains;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return 'contains'; }
sub priority { return 2; }
sub operate { return ($_[2] cmp $_[3]) != 1; }

1;