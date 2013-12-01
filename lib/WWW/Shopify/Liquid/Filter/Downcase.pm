#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Downcase; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return lc($_[2]); }

1;