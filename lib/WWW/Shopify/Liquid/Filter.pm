#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;

package WWW::Shopify::Liquid::Filter;
use base 'WWW::Shopify::Liquid::Element';

use List::Util qw(first);

sub new { my $package = shift; return bless { operand => shift, arguments => [@_] }, $package; }
# Determines whether or not this acts as a variable with no arguments, when used in conjucntion to a dot on a variable.
sub transparent { return 0; }
sub name { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; $package =~ s/^.*:://; $package =~ s/([a-z])([A-Z])/$1_$2/g; return lc($package);  }
sub min_arguments { return 0; }
sub max_arguments { return undef; }
sub verify {
	my ($self) = @_;
	my $count = int(@{$self->{arguments}});
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self) if
		$count < $self->min_arguments || (defined $self->max_arguments && $count > $self->max_arguments);
}

sub tokens { return map { $_->tokens } (@{$_[0]->{arguments}}, $_[0]->{operand}->tokens) }

sub render {
	my ($self, $hash) = @_;
	my $operand = !$self->is_processed($self->{operand}) ? $self->{operand}->render($hash) : $self->{opreand};
	my @arguments = map { !$self->is_processed($_) ? $_->render($hash) : $_ } @{$self->{arguments}};
	return $self->operate($hash, $operand, @arguments);
}

sub optimize {
	my ($self, $hash) = @_;
	my $operand = $self->{operand};
	$operand = $self->{operand}->optimize($hash) unless $self->is_processed($self->{operand});
	for (grep { !$self->is_processed($self->{arguments}->[$_]) } 0..int(@{$self->{arguments}})-1) {
		$self->{arguments}->[$_] = $self->{arguments}->[$_]->optimize($hash);
	}
	return $self if (!$self->is_processed($self->{operand}) || (defined first { !$self->is_processed($_) } @{$self->{arguments}}));
	return $self->operate($hash, $operand, @{$self->{arguments}});
}

1;