#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Liquid::Pipeline;
sub register_tag { }
sub register_operator { }
sub register_filter { }

package WWW::Shopify::Liquid::Element;

sub verify { return 1; }
sub render { 
	my $self = shift;
	my $return = eval { $self->process(@_, "render"); };
	return '' if $@ || !$self->is_processed($return) || !defined $return;
	return $return;
}
sub optimize { return shift->process(@_, "optimize"); }
sub process { return $_[0]; }

sub is_processed { return !ref($_[1]) || ref($_[1]) eq "ARRAY" || ref($_[1]) eq "HASH"; }

package WWW::Shopify::Liquid;
use Clone qw(clone);
use URI::Escape;
use File::Slurp;
use JSON qw(encode_json);
use HTML::Strip;
use List::Util qw(first);
use Digest::MD5 qw(md5_hex);
use List::MoreUtils qw(firstidx part);
use List::Util qw(first);
use Module::Find;

our $VERSION = '0.02';

=head1 NAME

WWW::Shopify::Liquid - Fully featured liquid preprocessor with shopify tags & filters added in.

=cut

=head1 DESCRIPTION

A concise and clear liquid processor. Runs a superset of what Shopify can do. For a strict shopify implementation
see L<Template::Liquid> for one that emulates all the quirks and ridiculousness of the real thing, but without the tags.
(Meaning no actual arithemtic is literal tags without filters, insanity on acutal number processing and conversion,
insane array handling, no real optimization, or partial AST reduction, etc.., etc..).

Combines a lexer, parser, optimizer and a render. Can be invoked in any number of ways. Simplest is to use the sub this module exports,
liquid_render_file.

	use WWW::Shopify::Liquid qw/liquid_render_file/;
	
	$contents = liquid_render_file({ collection => { handle => "test" } }, "myfile.liquid");
	print $contents;
	
This is the simplest method. There are auxiliary methods which provide a lot of flexibility over how you render your
liquid (see below), and an OO interface.

This method represents the whole pipeline, so to get an overview of this module, we'll describe it here.
Fundamentally, what liquid_render_file does, is it slurps the whole file into a string, and then passes that string to
the lexer. This then generates a stream of tokens. These tokens are then transformed into an abstract syntax tree, by the
the paser if the syntax is valid. This AST represents the canonical form of the file, and can, from here, either
transformed back into almost the same file, statically optimized to remove any unecessary calls, or partially optimized to
remove branches of the tree for which you have variables to fill at this time, though both these steps are optional.

Finally, these tokens are passed to the renderer, which interprets the tokens and then produces a string representing the
final content that can be printed.

Has better error handling than Shopify's liquid processor, so if you use this to validate your liquid, you should get better
errors than if you're simply submitting them. This module is integrated into the L<Padre::Plugin::Shopify> module, so if you
use Padre as your Shopify IDE, you can automatically check the liquid of the file you're currently looking at with the click
of a button.

You can invoke each stage individually if you like.

	use WWW::Shopify::Liquid;
	my $text = ...
	my $liquid = WWW::Shopify::Liquid->new;
	my @tokens = $liquid->lexer->parse_text($text);
	my $ast = $liquid->parser->parse_tokens(@tokens);
	
	# Here we have a partial tree optimization. Meaning, if you have some of your
	# variables, but not all of them, you can simplify the template.
	$ast = $liquid->optimizer->optimize({ a => 2 }, $ast);
	
	# Finally, you can render.
	$result = $liquid->renderer->Render({ b => 3 }, $ast);
	
If you're simply looking to check whether a liquid file is valid, you can do the following:

	use WWW::Shopify::Liquid qw/liquid_verify_file/;
	liquid_verify_file("my-snippet.liquid");
	
If sucessful, it'll return nothing, if it fails, it'll throw an exception, detailing the fault's location and description.

=cut

=head1 STATUS

This module is currently in early beta. That means that while it is able to parse and validate liquid documents from Shopify, it may
be missing a few tags. In addition to this, the optimizer is not yet fully complete; it does not do advanced optimizations such as loop
unrolling. However, it does do partial tree rendering. Essentially what's missing is the ability to generate liquid from syntax trees.

This is close to complete, but not quite there yet. When done, this will be extremely beneficial to application proxies, as it will allow
the use of custom liquid syntax, with partial evaluation, before passing the remaining liquid back to Shopify for full evaluation. This
will allow you to do things like have custom tags that a user can customize which will be filled with your data, yet still allow Shopify to
evaluate stuff like asset_urls, includes, and whatnot.

=cut

use WWW::Shopify::Liquid::Parser;
use WWW::Shopify::Liquid::Optimizer;
use WWW::Shopify::Liquid::Lexer;
use WWW::Shopify::Liquid::Renderer;
use WWW::Shopify::Liquid::Operator;
use WWW::Shopify::Liquid::Tag;

sub new {
	my $package = shift;
	my $self = bless {
		filters => [],
		operators => [],
		tags => [],
		
		lexer => WWW::Shopify::Liquid::Lexer->new,
		parser => WWW::Shopify::Liquid::Parser->new,
		optimizer => WWW::Shopify::Liquid::Optimizer->new,
		renderer => WWW::Shopify::Liquid::Renderer->new,
		
		%_
	}, $package;
	
	$self->register_operator($_) for (findallmod WWW::Shopify::Liquid::Operator);
	$self->register_filter($_) for (findallmod WWW::Shopify::Liquid::Filter);
	$self->register_tag($_) for (findallmod WWW::Shopify::Liquid::Tag);
	
	return $self;
}
sub lexer { return $_[0]->{lexer}; }
sub parser { return $_[0]->{parser}; }
sub optimizer { return $_[0]->{optimizer}; }
sub renderer { return $_[0]->{renderer}; }

sub register_tag {
	push(@{$_[0]->tags}, $_[1]);
	$_[0]->lexer->register_tag($_[1]);
	$_[0]->parser->register_tag($_[1]);
}
sub register_filter {
	push(@{$_[0]->filters}, $_[1]);
	$_[0]->lexer->register_filter($_[1]);
	$_[0]->parser->register_filter($_[1]);
}
sub register_operator {
	push(@{$_[0]->operators}, $_[1]);
	$_[0]->lexer->register_operator($_[1]);
	$_[0]->parser->register_operator($_[1]);
}
sub tags { return $_[0]->{tags}; }
sub filters { return $_[0]->{filters}; }
sub operators { return $_[0]->{operators}; }
sub order_of_operations { return $_[0]->{order_of_operations}; }
sub free_tags { return $_[0]->{free_tags}; }
sub enclosing_tags { return $_[0]->{enclosing_tags}; }
sub processing_variables { return $_[0]->{processing_variables}; }
sub money_format { return $_[0]->{money_format}; }
sub money_with_currency_format { return $_[0]->{money_with_currency_format}; }
sub tag_list { return (keys(%{$_[0]->free_tags}), keys(%{$_[0]->enclosing_tags})); }

sub operate { return $_[0]->operators->{$_[3]}->($_[0], $_[1], $_[2], $_[4]); }

sub render_ast { my ($self, $hash, $ast) = @_; return $self->renderer->render($hash, $ast); }
sub unpack_ast { my ($self, $ast) = @_; return $self->parser->unparse_tokens($ast); }
sub optimize_ast { my ($self, $hash, $ast) = @_; return $self->optimizer->optimize($hash, $ast); }
sub tokenize_text { my ($self, $text) = @_; return $self->lexer->parse_text($text); }
sub parse_tokens { my ($self, @tokens) = @_; return $self->parser->parse_tokens(@tokens); }
sub parse_text { my ($self, $text) = @_; return $self->parse_tokens($self->tokenize_text($text)); }

sub verify_text { my ($self, $text) = @_; $self->parse_tokens($self->parse_text($text)); }
sub verify_file { my ($self, $file) = @_; $self->verify_text(scalar(read_file($file))); }
sub render_text { my ($self, $hash, $text) = @_; return $self->render_ast($hash, $self->optimize_ast($hash, $self->parse_tokens($self->tokenize_text($text)))); }
sub render_file { my ($self, $hash, $file) = @_; return $self->render_text($hash, scalar(read_file($file))); }

use Exporter;
use base 'Exporter';
our @EXPORT_OK = qw(liquid_render_file liquid_render_text liquid_verify_file liquid_verify_text);
sub liquid_render_text { my ($hash, $text) = @_; my $self = WWW::Shopify::Liquid->new; return $self->render_text($hash, $text); }
sub liquid_verify_text { my ($text) = @_; my $self = WWW::Shopify::Liquid->new; $self->verify_text($text); }
sub liquid_render_file { my ($hash, $file) = @_; my $self = WWW::Shopify::Liquid->new; return $self->render_file($hash, $file); }
sub liquid_verify_file { my ($file) = @_; my $self = WWW::Shopify::Liquid->new; $self->verify_file($file); }


=head1 SEE ALSO

L<WWW::Shopify>, L<WWW::Shoipfy::Tools::Themer>, L<Padre::Plugin::Shopify>

=head1 AUTHOR

Adam Harrison (adamdharrison@gmail.com)

=head1 LICENSE

Copyright (C) 2013 Adam Harrison

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1;