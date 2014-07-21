#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::JSON; use base 'WWW::Shopify::Liquid::Filter';
use JSON qw(encode_json);
sub operate { return defined $_[2] && ref($_[2]) ? encode_json($_[2]) : '{}'; }

1;