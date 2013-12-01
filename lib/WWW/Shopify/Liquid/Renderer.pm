#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;

package WWW::Shopify::Liquid::Renderer;
use base 'WWW::Shopify::Liquid::Pipeline';

sub new { return bless { }, $_[0]; }

sub render {
	my ($self, $hash, $ast) = @_;
	return $ast->render($hash);
}

1;