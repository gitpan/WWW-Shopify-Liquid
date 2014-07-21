#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Include;
use base 'WWW::Shopify::Liquid::Tag::Free';
sub max_arguments { return 1; }
sub min_arguments { return 1; }

sub verify {
	my ($self) = @_;
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self) unless
		$self->{arguments}->[0]->isa('WWW::Shopify::Liquid::Operator::With') ||
		$self->{arguments}->[0]->isa('WWW::Shopify::Liquid::Token::String');
}

sub process {
	my ($self) = @_;
	die new WWW::Shopify::Liquid::Exception::Renderer::Unimplemented($self);
}



1;