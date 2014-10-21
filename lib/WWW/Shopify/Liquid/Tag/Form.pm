#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Form;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';

sub min_arguments { return 1; }
sub max_arguments { return 1; }

sub process {
	my ($self, $hash) = @_;
	my $result = $self->{arguments}->[0]->process($hash);
	return $self if blessed($result);
	return '';
}



1;