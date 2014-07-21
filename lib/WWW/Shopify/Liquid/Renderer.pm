#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;

package WWW::Shopify::Liquid::Renderer;
use base 'WWW::Shopify::Liquid::Pipeline';

sub new { return bless { }, $_[0]; }

use Clone qw(clone);

sub render {
	my ($self, $hash, $ast) = @_;
	return '' if !$ast && !wantarray;
	my $hash_clone = clone($hash);
	return ('', $hash_clone) unless $ast;
	my $result = $ast->isa('WWW::Shopify::Liquid::Element') ? $ast->render($hash_clone) : "$ast";
	return $result unless wantarray;
	return ($result, $hash_clone);
}

1;