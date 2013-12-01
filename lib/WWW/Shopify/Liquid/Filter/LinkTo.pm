#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::LinkTo; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return "<a href='" . $_[3] . "'>" . $_[3] .  "</a>"; }

1;