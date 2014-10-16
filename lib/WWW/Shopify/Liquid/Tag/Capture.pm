#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Capture;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';
sub min_arguments { return 1; }
sub max_arguments { return 1; }
use Scalar::Util qw(blessed);
sub process {
	my ($self, $hash, $action) = @_;
	my @vars = map { $self->is_processed($_) ? $_ : $_->process($hash, $action) } @{$self->{arguments}->[0]->{core}};
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
	my $result = $self->{contents}->$action($hash);
	return $self unless $self->is_processed($result);
	$inner_hash->{$vars[-1]} = $result;
	return '';
}

sub verify {
	my ($self) = @_;
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self, "Requires a variable to be the capture target.") unless
		$self->{arguments}->[0]->isa('WWW::Shopify::Liquid::Token::Variable');
}




1;