#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::MD5; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return md5_hex($_[2]); }

1;