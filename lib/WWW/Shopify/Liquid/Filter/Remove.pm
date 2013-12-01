#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Remove; use base 'WWW::Shopify::Liquid::Filter';
sub operate { my $str = $_[2]; $str =~ s/$_[3]//g; return $str; }

1;