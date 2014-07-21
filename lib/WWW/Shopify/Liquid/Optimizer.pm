#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;

package WWW::Shopify::Liquid::Optimizer;
use base 'WWW::Shopify::Liquid::Pipeline';

sub new { return bless { }, $_[0]; }

use Clone qw(clone);

sub optimize {
	my ($self, $hash, $ast) = @_;
	return undef unless $ast;
	my $result = $ast->optimize(clone($hash));
	return !ref($result) ? WWW::Shopify::Liquid::Token::Text->new(undef, $result) : $result;
}

1;