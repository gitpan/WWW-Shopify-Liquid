#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Unless;
use base 'WWW::Shopify::Liquid::Tag::If';
	
sub render {
	my ($self, $hash) = @_;
	my $arguments = $self->is_processed($self->{arguments}->[0]) ? $self->{arguments}->[0] : $self->{arguments}->[0]->render($hash);
	my $path = $self->{!$arguments ? 'true_path' : 'false_path'};
	$path = $path->render($hash) if $path && !$self->is_processed($path);
	return defined $path ? $path : '';
}

sub optimize {
	my ($self, $hash) = @_;
	$self->{arguments}->[0] = $self->{arguments}->[0]->optimize($hash) if !$self->is_processed($self->{arguments}->[0]);
	if ($self->is_processed($self->{arguments}->[0])) {
		my $path = $self->{!$self->{arguments}->[0] ? 'true_path' : 'false_path'};
		return $self->is_processed($path) ? $path : $path->optimize($hash);
	}
	$self->{false_path} = $self->{false_path}->optimize($hash) if !$self->is_processed($self->{false_path});
	$self->{true_path} = $self->{true_path}->optimize($hash) if !$self->is_processed($self->{true_path});
	return $self;
}

1;