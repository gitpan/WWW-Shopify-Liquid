#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::For;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';

sub min_arguments { return 1; }
sub max_arguments { return 1; }

sub verify {
	my ($self) = @_;
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self, "Requires in operator to be part of loop.") unless
		$self->{arguments}->[0]->isa('WWW::Shopify::Liquid::Operator::In');
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self, "Requires the opening variable of a loop to be a simple variable.") unless
		$self->{arguments}->[0]->{operands}->[0] && $self->{arguments}->[0]->{operands}->[0]->isa('WWW::Shopify::Liquid::Token::Variable') &&
		int(@{$self->{arguments}->[0]->{operands}->[0]->{core}}) == 1 && $self->{arguments}->[0]->{operands}->[0]->{core}->[0]->isa('WWW::Shopify::Liquid::Token::String');
}

# Should eventually support loop unrolling.
sub process {
	my ($self, $hash, $action) = @_;
	my ($op1, $op2) = @{$self->{arguments}->[0]->{operands}};
	my $var = $op1->{core}->[0]->{core};
	$op2 = $op2->$action($hash) if !$self->is_processed($op2);
	$self->{arguments}->[0]->{operands}->[1] = $op2 if $self->is_processed($op2) && $action eq 'optimize';
	return $self if (!$self->is_processed($op2) && $action eq "optimize");
	return '' if (!$self->is_processed($op2) && $action eq "render");
	die new WWW::Shopify::Liquid::Exception::Renderer::Arguments($self, "Requires an array in for loop.") unless ref($op2) eq "ARRAY";
	my @array = @$op2;
	my @texts = ();
	my ($all_processed, $content) = (1, undef);
	
	# Since we're looping, we can't optimize the loop stuff, unless we unroll. Since we're not unrolling yet, only throw in the loop stuff during rendering.
	for (0..$#array) {
		my ($backup, $existed);
		if ($action eq "render") {
			$hash->{$var} = $array[$_];
			$hash->{forloop} = { 
				index => ($_+1), index0 => $_, first => $_ == 0, last => $_ == $#array,
				length => int(@array), rindex0 => (($#array - $_) + 1),	rindex => (($#array - $_)),
			};
		}
		else {
			$existed = exists $hash->{$var};
			if ($existed) {
				$backup = $hash->{$var};
				$hash->{$var} = undef;
			}
			$hash->{forloop} = undef;
		}
		$content = $self->{contents}->$action($hash);
		if ($action ne "render") {
			$hash->{$var} = $backup if !defined $hash->{$var} && $existed;
		}
		$all_processed = 0 if !$self->is_processed($content);
		push(@texts, $content);
	}
	return join('', @texts) if $all_processed;
	return $self;
	
}



1;