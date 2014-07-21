#!/usr/bin/perl
use strict;
use warnings;

use WWW::Shopify::Liquid::Tag;

package WWW::Shopify::Liquid::Tag::Assign;
use base 'WWW::Shopify::Liquid::Tag::Free';
sub min_arguments { return 1; }
sub max_arguments { return 1; }
sub verify {
	my ($self) = @_;
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self, "Requires assignment operator to be the first thing in an assign tag.") unless
		$self->{arguments}->[0]->isa('WWW::Shopify::Liquid::Operator::Assignment');
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self, "Requires variable for what you're assigning to.") unless
		$self->{arguments}->[0]->{operands}->[0]->isa('WWW::Shopify::Liquid::Token::Variable');
}
sub process {
	my ($self, $hash, $action) = @_;
	my @vars = map { $self->is_processed($_) ? $_ : $_->process($hash, $action) } @{$self->{arguments}->[0]->{operands}->[0]->{core}};
	return $self if $action eq "optimize" && int(grep { !$self->is_processed($_) } @vars) > 0;
	my $inner_hash = $hash;
	for (0..$#vars-1) {
		return $self if !exists $inner_hash->{$vars[$_]} && $action eq 'optimize';
		$inner_hash->{$vars[$_]} = {} if !exists $inner_hash->{$vars[$_]};
		$inner_hash = $inner_hash->{$vars[$_]};
	}
	# For now, only do renders.
	if ($action eq "optimize") {
		# If we run across something that should be assigned, we must delete it in the hash to preserve uncertainty.
		delete $inner_hash->{$vars[-1]};
		return $self;
	}
	my $result = $self->{arguments}->[0]->{operands}->[1]->$action($hash);
	return $self unless $self->is_processed($result);
	$inner_hash->{$vars[-1]} = $result;
	return '';
}



1;