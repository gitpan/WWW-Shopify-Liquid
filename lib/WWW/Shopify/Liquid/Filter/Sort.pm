#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Sort; use base 'WWW::Shopify::Liquid::Filter';
sub operate { 
	my $prop = $_[3];
	return [sort(@{$_[2]})] if !$prop;
	return [sort { $a->$prop <=> $b->$prop } @{$_[2]}] if $prop;
}

1;