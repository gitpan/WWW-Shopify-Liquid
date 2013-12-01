#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Last; use base 'WWW::Shopify::Liquid::Filter';
sub transparent { return 1; }
sub operate { return $_[2] && ref($_[2]) eq "ARRAY" ? $_[2]->[-1] : ''; }

1;