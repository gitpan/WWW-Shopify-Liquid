#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Replace; use base 'WWW::Shopify::Liquid::Filter';
sub operate { my $str = $_[2]; $str =~ s/$_[3]/$_[3]/; return $str; }

1;