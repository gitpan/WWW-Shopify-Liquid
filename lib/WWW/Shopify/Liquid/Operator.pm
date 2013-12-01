#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator;
use base 'WWW::Shopify::Liquid::Element';
sub new { 
	my $package = shift;
	my $self = bless { core => shift, operands => undef }, $package;
	$self->{operands} = [@_] if int(@_) >= 1;
	return $self;
}
sub operands { my $self = shift; $self->{operands} = [@_]; return $self->{operands}; }

sub process {
	my ($self, $hash, $action) = @_;
	my ($op1, $op2) = ($self->{operands}->[0], $self->{operands}->[1]);
	$op1 = $op1->$action($hash) unless $self->is_processed($op1);
	$op2 = $op2->$action($hash) unless $self->is_processed($op2);
	if (!$self->is_processed($op1) || !$self->is_processed($op2)) {
		$self->{operands} = [$op1, $op2];
		return $self;
	}
	return $self->operate($hash, $action, $op1, $op2);
}
sub priority { return 0; }
# If we require a grouping, it means that it must be wrapped in parentheses, due to how Shopify works. Only relevant for reconversion.
sub requires_grouping { return 0; }

1;