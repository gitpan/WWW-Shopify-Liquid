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

package WWW::Shopify::Liquid::Tag::Enclosing;
use base 'WWW::Shopify::Liquid::Tag';
sub is_enclosing { return 1; }
sub inner_tags { return (); }
sub inner_ignore_whitespace { return 0; }
# Interprets the inner of this tag as being completely text. Used for comments and raws.
sub inner_halt_lexing { return 0; }

sub new { 
	my ($package, $line, $tag, $arguments, $contents) = @_;
	my $self = { line => $line, core => $tag, arguments => $arguments, contents => @{$contents->[0]} };
	die new WWW::Shopify::Liquid::Exception::Parser($self, "Uncustomized tags can only have one element following their contents.") unless int(@$contents) == 1;
	return bless $self, $package;
}

package WWW::Shopify::Liquid::Tag::Free;
use base 'WWW::Shopify::Liquid::Tag';
sub is_free { return 1; }
sub new { 
	my ($package, $line, $tag, $arguments) = @_;
	my $self = { line => $line, core => $tag, arguments => $arguments };
	return bless $self, $package;
}

package WWW::Shopify::Liquid::Tag::Output;
use base 'WWW::Shopify::Liquid::Tag::Free';
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
