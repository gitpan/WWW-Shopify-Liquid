#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::Or;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return ('||', 'or'); }
sub priority { return 4; }
sub operate { return $_[3] || $_[4]; }

1;