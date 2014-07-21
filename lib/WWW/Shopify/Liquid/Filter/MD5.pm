#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::MD5; use base 'WWW::Shopify::Liquid::Filter';
use Storable qw(freeze);
use Digest::MD5 qw(md5_hex);
$Storable::canonical = 1;
use Data::Dumper;
sub operate {
	my ($self, $hash, $operand, @arguments) = @_;
	return md5_hex(freeze($operand)) if ref($operand);
	return md5_hex($operand);
}

1;