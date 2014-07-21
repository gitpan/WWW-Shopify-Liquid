#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::And;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return ('&&', 'and'); }
sub priority { return 3; }
sub operate { return $_[3] && $_[4]; }

1;