#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Liquid::Tag;
use base 'WWW::Shopify::Liquid::Element';

sub inner_tags { return (); }
sub name { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; die unless $package =~ m/::(\w+)$/; my $name = lc($1); $name =~ s/([A-Z])/_$1/g; return $name; }
sub new { 
	my ($package, $line, $tag, $arguments, $contents) = @_;
	my $self = { line => $line, core => $tag, arguments => $arguments, contents => $contents };
	return bless $self, $package;
}
sub is_free { return 0; }
sub is_enclosing { return 0; }
sub min_arguments { return 0; }
sub max_arguments { return undef; }

sub tokens { return ($_[0], map { $_->tokens } grep { defined $_ } (@{$_[0]->{arguments}}, $_[0]->{contents})) }

package WWW::Shopify::Liquid::Tag::Output;
use base 'WWW::Shopify::Liquid::Tag::Free';
sub abstract { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; return ($package eq __PACKAGE__); }

sub max_arguments { return 1; }

sub new { 
	my ($package, $line, $arguments) = @_;
	my $self = { arguments => $arguments, line => $line };
	return bless $self, $package;
}
sub process {
	my ($self, $hash, $action) = @_;
	return '' unless int(@{$self->{arguments}}) > 0;
	my $result = $self->{arguments}->[0]->$action($hash);
	return '' if ref($result) && (ref($result) eq "ARRAY" || ref($result) eq "HASH");
	return $result;
}

1;
