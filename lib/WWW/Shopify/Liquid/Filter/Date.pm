#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Date; use base 'WWW::Shopify::Liquid::Filter';
sub min_arguments { return 1; }
sub max_arguments { return 1; }
sub operate { return $_[2]->strftime($_[3]); }

1;