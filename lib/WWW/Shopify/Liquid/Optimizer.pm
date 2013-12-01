#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;

package WWW::Shopify::Liquid::Optimizer;
use base 'WWW::Shopify::Liquid::Pipeline';

sub new { return bless { }, $_[0]; }

sub optimize {
	my ($self, $hash, $ast) = @_;
	my $result = $ast->optimize($hash);
	return !ref($result) ? WWW::Shopify::Liquid::Token::Text->new(undef, $result) : $result;
}

1;