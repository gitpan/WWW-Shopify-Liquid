#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Unless;
use base 'WWW::Shopify::Liquid::Tag::If';
sub process {
	my ($self, $hash) = @_;
	my $result = $self->{arguments}->[0]->process($hash);
	return $self if (blessed($result) && $result->isa('WWW::Shopify::Liquid::Token'));
	return $self->{$result ? 'false_path' : 'true_path'}->process($hash);
}

1;