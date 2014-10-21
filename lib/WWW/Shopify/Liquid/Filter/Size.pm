#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Size; use base 'WWW::Shopify::Liquid::Filter';
sub transparent { return 1; }
sub max_arguments { return 0; }
sub operate { return int(@{$_[2]}); }

1;