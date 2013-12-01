#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::If;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';

sub min_arguments { return 1; }
sub max_arguments { return 1; }

sub new { 
	my $package = shift;
	my $self = bless {
		line => shift,
		core => shift,
		arguments => shift,
		true_path => undef,
		false_path => undef
	}, $package;
	$self->interpret_inner_tokens(@{$_[0]});
	return $self;
}
sub inner_tags { return qw(elsif else) }
use List::Util qw(first);
sub interpret_inner_tokens {
	my ($self, @tokens) = @_;
	# Comes in [true_path], [tag, other_path], [tag, other_path], ...
	$self->{true_path} = shift(@tokens)->[0];
	if (int(@tokens) > 0) {
		die new WWW::Shopify::Liquid::Exception::Parser($self, "else cannot be anywhere, except the end tag of an if statement.") if $tokens[0]->[0]->tag eq "else" && int(@tokens) > 1;
		if ($tokens[0]->[0]->tag eq "elsif") {
			$self->{false_path} = WWW::Shopify::Liquid::Tag::If->new($tokens[0]->[0]->{line}, "if", $tokens[0]->[0]->{arguments}, [@tokens[1..$#tokens]]);
		}
		else {
			$self->{false_path} = $tokens[0]->[1];
		}
	}
}

sub render {
	my ($self, $hash) = @_;
	$self->{arguments} = $self->{arguments}->render($hash) if !$self->is_processed($self->{arguments});
	my $path = $self->{$self->{arguments} ? 'true_path' : 'false_path'};
	$path = $path->render($hash) if $path && !$self->is_processed($path);
	return defined $path ? $path : '';
}

sub optimize {
	my ($self, $hash) = @_;
	$self->{arguments} = $self->{arguments}->optimize($hash) if !$self->is_processed($self->{arguments});
	if ($self->is_processed($self->{arguments})) {
		my $path = $self->{$self->{arguments} ? 'true_path' : 'false_path'};
		return $self->is_processed($path) ? $path : $path->optimize($hash);
	}
	$self->{false_path} = $self->{false_path}->optimize($hash) if !$self->is_processed($self->{false_path});
	$self->{true_path} = $self->{true_path}->optimize($hash) if !$self->is_processed($self->{true_path});
	return $self;
}

1;