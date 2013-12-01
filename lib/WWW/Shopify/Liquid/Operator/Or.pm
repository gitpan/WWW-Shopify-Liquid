#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::Or;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return ('||', 'or'); }
sub priority { return 8; }
sub operate { return $_[2] || $_[3]; }

1;