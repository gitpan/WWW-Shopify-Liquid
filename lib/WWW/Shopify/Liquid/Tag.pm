#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Liquid::Tag;
use base 'WWW::Shopify::Liquid::Element';

sub inner_tags { return (); }
sub name { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; die unless $package =~ m/::(\w+)$/; return lc($1); }
sub new { 
	my ($package, $line, $tag, $arguments, $contents) = @_;
	my $self = { line => $line, core => $tag, arguments => $arguments, contents => $contents };
	return bless $self, $package;
}
sub is_free { return 0; }
sub is_enclosing { return 0; }
sub min_arguments { return 0; }
sub max_arguments { return undef; }

package WWW::Shopify::Liquid::Tag::Output;
use base 'WWW::Shopify::Liquid::Tag::Free';
sub abstract { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; return ($package eq __PACKAGE__); }
sub new { 
	my ($package, $line, $arguments) = @_;
	my $self = { arguments => $arguments, line => $line };
	return bless $self, $package;
}
sub process {
	my ($self, $hash, $action) = @_;
	return $self->{arguments}->$action($hash);
}

1;
