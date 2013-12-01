#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Layout;
use base 'WWW::Shopify::Liquid::Tag::Free';
sub process {
	my ($self, $hash) = @_;
	my $result = $self->{arguments}->[0]->process($hash);
	return $self if blessed($result);
	$hash->{layout} = $result;
	return '';
}



1;