#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::And;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return ('&&', 'and'); }
sub priority { return 7; }
sub operate { return $_[2] && $_[3]; }

1;