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
		$self->{arguments}->isa('WWW::Shopify::Liquid::Operator::Assignment');
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self, "Requires simple variable for what you're assigning to.") unless
		$self->{arguments}->{operands}->[0]->isa('WWW::Shopify::Liquid::Token::Variable') &&
		int(@{$self->{arguments}->{operands}->[0]->{core}}) == 1 &&
		$self->{arguments}->{operands}->[0]->{core}->[0]->isa('WWW::Shopify::Liquid::Token::String');
}
sub process {
	my ($self, $hash, $action) = @_;
	my $var = $self->{arguments}->{operands}->[0]->{core}->[0]->{core};
	my $result = $self->{arguments}->{operands}->[1]->$action($hash);
	return $self unless $self->is_processed($result);
	$hash->{$var} = $result;
	return '';
}



1;