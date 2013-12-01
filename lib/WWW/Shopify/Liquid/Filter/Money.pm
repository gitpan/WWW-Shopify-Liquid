#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Money; use base 'WWW::Shopify::Liquid::Filter';
sub operate { 
	my $format = $_[1]->{shop}->{money_format};
	my $amount = sprintf('%.2f', $_[2] / 100.0);
	$format =~ s/{{\s*amount\s*}}/$amount/;
	return $format;
}
1;