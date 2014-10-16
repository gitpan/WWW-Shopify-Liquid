#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;

# Designed to wrap objects in the hash taht shoudln't be cloned. Only works for top level.
package WWW::Shopify::Liquid::Renderer::NoClone;
sub new { return bless { inner => $_[0] }; }

package WWW::Shopify::Liquid::Renderer;
use base 'WWW::Shopify::Liquid::Pipeline';

sub new { return bless { }, $_[0]; }

use Clone qw(clone);

sub render {
	my ($self, $hash, $ast) = @_;
	return '' if !$ast && !wantarray;
	my $hash_clone = $hash->{_clone} && $hash->{_clone} == 0 ? clone($hash) : $hash;
	return ('', $hash_clone) unless $ast;
	my $result = $ast->isa('WWW::Shopify::Liquid::Element') ? $ast->render($hash_clone) : "$ast";
	return $result unless wantarray;
	return ($result, $hash_clone);
}

1;