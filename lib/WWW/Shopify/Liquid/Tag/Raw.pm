#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Raw;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';
sub inner_halt_lexing { return 1; }
sub process {
	my ($self, $hash) = @_;
	my $result = $self->{contents}->process($hash);
	return $result;
}



1;