#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::JSON; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return ($_[2] ? encode_json($_[2]) : "{}"); }

1;