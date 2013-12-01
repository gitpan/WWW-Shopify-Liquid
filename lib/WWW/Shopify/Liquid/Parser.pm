#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Liquid::Parser;
use base 'WWW::Shopify::Liquid::Pipeline';
use Module::Find;
use List::MoreUtils qw(firstidx part);
use List::Util qw(first);
use WWW::Shopify::Liquid::Exception;

useall WWW::Shopify::Liquid::Operator;
useall WWW::Shopify::Liquid::Tag;
useall WWW::Shopify::Liquid::Filter;

sub new { return bless {
	order_of_operations => [],
	operators => {},
	enclosing_tags => {},
	free_tags => {},
	filters => {},
	inner_tags => {}
}, $_[0]; }
sub operators { return $_[0]->{operators}; }
sub order_of_operations { return @{$_[0]->{order_of_operations}}; }
sub free_tags { return $_[0]->{free_tags}; }
sub enclosing_tags { return $_[0]->{enclosing_tags}; }
sub inner_tags { return $_[0]->{inner_tags}; }
sub filters { return $_[0]->{filters}; }

sub register_tag {
	$_[0]->free_tags->{$_[1]->name} = $_[1] if $_[1]->is_free;
	if ($_[1]->is_enclosing) {
		$_[0]->enclosing_tags->{$_[1]->name} = $_[1];
		foreach my $tag ($_[1]->inner_tags) {
			$_[0]->inner_tags->{$tag} = 1;
		}
	}
}


sub register_operator {
	$_[0]->operators->{$_} = $_[1] for($_[1]->symbol);
	my $ooo = $_[0]->{order_of_operations};
	my $element = first { $_->[0]->priority == $_[1]->priority } @$ooo;
	if ($element) {
		push(@$element, $_[1]);
	}
	else {
		push(@$ooo, [$_[1]]);
	}
	$_[0]->{order_of_operations} = [sort { $a->[0]->priority <=> $b->[0]->priority } @$ooo];
}
sub register_filter {
	$_[0]->filters->{$_[1]->name} = $_[1];
}



sub parse_filter_tokens {
	my ($self, $initial, @tokens) = @_;
	my $filter = shift(@tokens);
	my $filter_name = $filter->{core}->[0]->{core};
	die new WWW::Shopify::Liquid::Exception::Parser::UnknownFilter($filter) unless $self->{filters}->{$filter_name};
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($filter, "In order to have arguments, filter must be followed by a colon.") if int(@tokens) > 0 && $tokens[0]->{core} ne ":";
	
	my @arguments = ();
	if (shift(@tokens)) {
		my $i = 0;
		@arguments = map { shift(@{$_}) if $_->[0]->{core} eq "|"; $self->parse_argument_tokens(@{$_}) } part { $i++ if $_->isa('WWW::Shopify::Liquid::Token::Separator') && $_->{core} eq ","; $i; } @tokens;
	}
	$filter = $self->{filters}->{$filter_name}->new($initial, @arguments);
	$filter->verify;
	return $filter;
}

# Similar, but doesn't deal with tags; deals solely with order of operations.
sub parse_argument_tokens {
	my ($self, @tokens) = @_;
	# First, pull together filters. These are the highest priority operators, after parentheses. They also have their own weird syntax.
	my $top = undef;
	
	# Use the order of operations to create a binary tree structure.
	foreach my $operators ($self->order_of_operations) {
		# If we have pipes, we deal with those, and prase their lower level arguments.
		foreach my $operator (@$operators) {
			my %ops = map { $_ => 1 } $operator->symbol;
			if ($operator eq 'WWW::Shopify::Liquid::Operator::Pipe') {
				if ((my $idx = firstidx { $_->isa('WWW::Shopify::Liquid::Token::Operator') && $_->{core} eq "|" } @tokens) != -1) {
					die new WWW::Shopify::Liquid::Exception::Parser($tokens[0]) if $idx == 0;
					my $i = 0;
					# Part should consist of the first token before a pipe, and then split on all pipes after this.,
					my @parts = map { shift(@{$_}) if $_->[0]->{core} eq "|"; $_ } part { $i++ if $_->isa('WWW::Shopify::Liquid::Token::Operator') && $_->{core} eq "|"; $i; } splice(@tokens, $idx-1);
					my $next = undef;
					$top = $self->parse_filter_tokens($self->parse_argument_tokens(@{shift(@parts)}), @{shift(@parts)});
					while (my $part = shift(@parts)) {
						$top = $self->parse_filter_tokens($top, @$part);
					}
					push(@tokens, $top);
				}
			}
			else {
				while ((my $idx = firstidx { $_->isa('WWW::Shopify::Liquid::Token::Operator') && exists $ops{$_->{core}} } @tokens) != -1) {
					my ($op1, $op, $op2) = @tokens[$idx-1..$idx+1];
					die new WWW::Shopify::Liquid::Exception::Parser::Operands($tokens[0]) unless
						$idx > 0 && $idx < $#tokens && 
						($op1->isa('WWW::Shopify::Liquid::Operator') || $op1->isa('WWW::Shopify::Liquid::Token::Operand') || $op1->isa('WWW::Shopify::Liquid::Filter')) &&
						($op2->isa('WWW::Shopify::Liquid::Operator') || $op2->isa('WWW::Shopify::Liquid::Token::Operand') || $op2->isa('WWW::Shopify::Liquid::Filter'));
					$op1 = $self->parse_argument_tokens($op1->members) if $op1->isa('WWW::Shopify::Liquid::Token::Grouping');
					$op2 = $self->parse_argument_tokens($op2->members) if $op2->isa('WWW::Shopify::Liquid::Token::Grouping');
					splice(@tokens, $idx-1, 3, $self->operators->{$op->{core}}->new($op->{core}, $op1, $op2));
				}
			}
		}
	}
	die new WWW::Shopify::Liquid::Exception::Parser::Operands($tokens[0]) unless int(@tokens) == 1 || int(@tokens) == 0;
	($top) = @tokens;
	return $top;
}

sub parse_tokens {
	my ($self, @tokens) = @_;
	
	return () if int(@tokens) == 0;
	
	my @tags = ();	
	# First we take a look and start matching up opening and ending tags. Those which are free tags we can leave as is.
	while (my $token = shift(@tokens)) {
		my $line = $token->{line};
		if ($token->isa('WWW::Shopify::Liquid::Token::Tag')) {
			my $tag = undef;
			if ($self->enclosing_tags->{$token->tag}) {
				my @internal = ();
				my @contents = ();
				my %allowed_internal_tags = map { $_ => 1 } $self->enclosing_tags->{$token->tag}->inner_tags;
				my $level = 1;
				for (0..$#tokens) {
					if ($tokens[$_]->isa('WWW::Shopify::Liquid::Token::Tag')) {
						if ($tokens[$_]->tag eq $token->tag) {
							$level++;
						} elsif (exists $allowed_internal_tags{$tokens[$_]->tag} && $level == 1) {
							$tokens[$_]->{arguments} = $self->parse_argument_tokens(@{$tokens[$_]->{arguments}});
							push(@internal, $_);
						} elsif ($tokens[$_]->tag eq "end" . $token->tag && --$level == 0) {
							my $last_int = 0;
							foreach my $int (@internal, $_) {
								push(@contents, [splice(@tokens, 0, $int-$last_int)]);
								shift(@{$contents[0]}) if $self->enclosing_tags->{$token->tag}->inner_ignore_whitespace && int(@contents) > 0 && int(@{$contents[0]}) > 0 && $contents[0]->[0]->isa('WWW::Shopify::Liquid::Token::Text::Whitespace');
								@contents = map {
									my @array = @$_;
									if (int(@array) > 0 && $array[0]->isa('WWW::Shopify::Liquid::Token::Tag') && $allowed_internal_tags{$array[0]->tag}) {
										[$array[0], $self->parse_tokens(@array[1..$#array])];
									}
									else {
										[$self->parse_tokens(@array)]
									}
								} @contents;
								$last_int = $int;
							}
							# Remove the endtag.
							shift(@tokens);
							last;
						}
					}
					die new WWW::Shopify::Liquid::Exception::Parser::NoClose($token) if $_ == $#tokens && $level > 0;
				}
				$tag = $self->enclosing_tags->{$token->tag}->new($line, $token->tag, $self->parse_argument_tokens(@{$token->{arguments}}), \@contents);
				$tag->verify;
			}
			elsif ($self->free_tags->{$token->tag}) {
				$tag = $self->free_tags->{$token->tag}->new($line, $token->tag, $self->parse_argument_tokens(@{$token->{arguments}}));
				$tag->verify;
			}
			else {
				die new WWW::Shopify::Liquid::Exception::Parser::NoOpen($token) if ($token->tag =~ m/^end(\w+)$/ && $self->enclosing_tags->{$1});
				die new WWW::Shopify::Liquid::Exception::Parser::NakedInnerTag($token) if (exists $self->inner_tags->{$token->tag});
				die new WWW::Shopify::Liquid::Exception::Parser::UnknownTag($token);
			}
			push(@tags, $tag);
		}
		elsif ($token->isa('WWW::Shopify::Liquid::Token::Output')) {
			push(@tags, WWW::Shopify::Liquid::Tag::Output->new($line, $self->parse_argument_tokens(@{$token->{core}})));
		}
		else {
			push(@tags, $token);
		}
	}
	
	my $top = undef;
	if (int(@tags) > 1) {
		$top = WWW::Shopify::Liquid::Operator::Concatenate->new;
		$top->{operands}->[0] = shift(@tags);
		my $next = $top;
		while (my $tag = shift(@tags)) {
			if (int(@tags) == 0) {
				$next->{operands}->[1] = $tag;
			}
			else {
				$next->{operands}->[1] = WWW::Shopify::Liquid::Operator::Concatenate->new;
				$next = $next->{operands}->[1];
				$next->{operands}->[0] = $tag;
			}
		}
	}
	else {
		($top) = @tags;
	}
	return $top;
}

sub unparse_argument_tokens {
	my ($self, $ast) = @_;
	return $ast if $ast->isa('WWW::Shopify::Liquid::Token');
	my @optokens = ($self->unparse_argument_tokens($ast->{operands}->[0]), WWW::Shopify::Liquid::Token::Operator->new($ast->{core}), $self->unparse_argument_tokens($ast->{operands}->[1]));
	return WWW::Shopify::Liquid::Token::Grouping->new(@optokens) if $ast->requires_grouping;
	return @optokens;
}

sub unparse_tokens {
	my ($self, $ast) = @_;
	return $ast if $ast->isa('WWW::Shopify::Liquid::Token');
	if ($ast->isa('WWW::Shopify::Liquid::Tag')) {
		my @arguments = $ast->{arguments} ? $self->unparse_argument_tokens($ast->{arguments}) : ();
		if ($ast->isa('WWW::Shopify::Liquid::Tag::Enclosing')) {
			if ($ast->isa('WWW::Shopify::Liquid::Tag::If')) {
				return (WWW::Shopify::Liquid::Token::Tag->new('if', \@arguments), $self->unparse_tokens($ast->{true_path}), WWW::Shopify::Liquid::Token::Tag->new('endif')) if !$ast->{false_path};
				return (WWW::Shopify::Liquid::Token::Tag->new('if', \@arguments), $self->unparse_tokens($ast->{true_path}), WWW::Shopify::Liquid::Token::Tag->new('else'), $self->unparse_tokens($ast->{false_path}), WWW::Shopify::Liquid::Token::Tag->new('endif'));
			}
			else {
				return (WWW::Shopify::Liquid::Token::Tag->new($ast->{core}, \@arguments), $self->unparse_tokens($ast->{contents}), WWW::Shopify::Liquid::Token::Tag->new('end' . $ast->{core}));
			}
		}
		elsif ($ast->isa('WWW::Shopify::Liquid::Tag::Output')) {
			return (WWW::Shopify::Liquid::Token::Output->new([$self->unparse_argument_tokens($ast->{arguments})]));
		}
		else  {
			return (WWW::Shopify::Liquid::Token::Tag->new($ast->{core}, \@arguments));
		}
		return $ast;
	}
	if ($ast->isa('WWW::Shopify::Liquid::Filter')) {
		return $ast;
	}
	return ($self->unparse_tokens($ast->{operands}->[0]), $self->unparse_tokens($ast->{operands}->[1])) if ($ast->isa('WWW::Shopify::Liquid::Operator::Concatenate'));
	
}

1;