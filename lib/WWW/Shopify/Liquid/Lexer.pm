#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Liquid::Token;
use base 'WWW::Shopify::Liquid::Element';
sub new { return bless { line => $_[1], core => $_[2] }, $_[0]; };
sub stringify { return $_[0]->{core}; }
sub tokens { return $_[0]; }

package WWW::Shopify::Liquid::Token::Operator;
use base 'WWW::Shopify::Liquid::Token';

package WWW::Shopify::Liquid::Token::Operand;
use base 'WWW::Shopify::Liquid::Token';

package WWW::Shopify::Liquid::Token::String;
use base 'WWW::Shopify::Liquid::Token::Operand';
sub process { my ($self, $hash) = @_; return $self->{core}; }

package WWW::Shopify::Liquid::Token::Number;
use base 'WWW::Shopify::Liquid::Token::Operand';
sub process { my ($self, $hash) = @_; return $self->{core}; }

package WWW::Shopify::Liquid::Token::Bool;
use base 'WWW::Shopify::Liquid::Token::Operand';
sub process { my ($self, $hash) = @_; return $self->{core}; }

package WWW::Shopify::Liquid::Token::Variable;
use base 'WWW::Shopify::Liquid::Token::Operand';

use Data::Dumper;
use Scalar::Util qw(looks_like_number);

sub new { my $package = shift; return bless { line => shift, core => [@_] }, $package; };
sub process {
	my ($self, $hash, $action) = @_;
	my $place = $hash;
	return $self->{core} if $self->is_processed($self->{core});
	foreach my $part (@{$self->{core}}) {
		if (ref($part) eq 'WWW::Shopify::Liquid::Token::Variable::Processing') {
			$place = $part->$action($hash, $place);
		}
		else {
			my $key = $self->is_processed($part) ? $part : $part->$action($hash);
			return $self unless defined $key && $key ne '';
			if (ref($place) eq "HASH" && exists $place->{$key}) {
				$place = $place->{$key};
			} elsif (ref($place) eq "ARRAY" && looks_like_number($key) && defined $place->[$key]) {
				$place = $place->[$key];
			} else {
				return $self;
			}
			
		}
	}
	return $place;
}
sub stringify { return join(".", map { $_->stringify } @{$_[0]->{core}}); }

package WWW::Shopify::Liquid::Token::Variable::Processing;
use base 'WWW::Shopify::Liquid::Token::Operand';
use Data::Dumper;
sub process {
	my ($self, $hash, $argument, $action) = @_;
	return $self if !$self->is_processed($argument);
	my $result = $self->{core}->operate($hash, $argument);
	return $self if !$self->is_processed($result);
	return $result;
}


package WWW::Shopify::Liquid::Token::Grouping;
use base 'WWW::Shopify::Liquid::Token::Operand';
sub new { my $package = shift; return bless { line => shift, members => [@_] }, $package; };
sub members { return @{$_[0]->{members}}; }

package WWW::Shopify::Liquid::Token::Text;
use base 'WWW::Shopify::Liquid::Token::Operand';
sub new { 
	my $self = { line => $_[1], core => $_[2] };
	my $package = $_[0];
	$package = 'WWW::Shopify::Liquid::Token::Text::Whitespace' if !defined $_[2] || $_[2] =~ m/^\s*$/;
	return bless $self, $package;
};
sub process { my ($self, $hash) = @_; return $self->{core}; }

package WWW::Shopify::Liquid::Token::Text::Whitespace;
use base 'WWW::Shopify::Liquid::Token::Text';

package WWW::Shopify::Liquid::Token::Tag;
use base 'WWW::Shopify::Liquid::Token';
sub new { return bless { line => $_[1], tag => $_[2], arguments => $_[3] }, $_[0] };
sub tag { return $_[0]->{tag}; }
sub stringify { return $_[0]->tag; }

package WWW::Shopify::Liquid::Token::Output;
use base 'WWW::Shopify::Liquid::Token';
sub new { return bless { line => $_[1], core => $_[2] }, $_[0]; };

package WWW::Shopify::Liquid::Token::Separator;
use base 'WWW::Shopify::Liquid::Token';


package WWW::Shopify::Liquid::Lexer;
use base 'WWW::Shopify::Liquid::Pipeline';
use Scalar::Util qw(looks_like_number);

sub new { return bless { operators => {}, lexing_halters => {}, transparent_filters => {} }, $_[0]; }
sub operators { return $_[0]->{operators}; }
sub register_operator {	$_[0]->{operators}->{$_} = $_[1] for ($_[1]->symbol); } 
sub register_tag {
	my ($self, $package) = @_;
	$self->{lexing_halters}->{$package->name} = $package if $package->is_enclosing && $package->inner_halt_lexing;
}
sub register_filter {
	my ($self, $package) = @_;
	$self->{transparent_filters}->{$package->name} = $package if ($package->transparent);
}
sub transparent_filters { return $_[0]->{transparent_filters}; }

sub parse_token {
	my ($self, $line, $token) = @_;
	# Strip token of whitespace.
	return undef unless defined $token;
	$token =~ s/^\s*(.*?)\s*$/$1/;
	return WWW::Shopify::Liquid::Token::Operator->new($line, $token) if $self->operators->{$token};
	return WWW::Shopify::Liquid::Token::String->new($line, $1) if $token =~ m/^'(.*)'$/ || $token =~ m/^"(.*)"$/;
	return WWW::Shopify::Liquid::Token::Number->new($line, $1) if looks_like_number($token);
	return WWW::Shopify::Liquid::Token::NULL->new() if $token eq '';
	return WWW::Shopify::Liquid::Token::Separator->new($line, $token) if ($token eq ":" || $token eq ",");
	# We're a variable. Let's see what's going on. Split along non quoted . and [ ] fields.
	my ($squot, $dquot, $start, @parts) = (0,0,0);
	#  customer['test']['b'] 
	my $open_bracket = 0;
	while ($token =~ m/(\.|\[|\]|(?<!\\)\"|(?<!\\)\'|\b$)/g) {
		my $sym = $&;
		if (!$squot && !$dquot) {
			$open_bracket-- if ($sym && $sym eq "]");
			if (($sym eq "." || $sym eq "]" || $sym eq "[" || !$sym) && $open_bracket == 0) {
				my $contents = substr($token, $start, $-[0] - $start);
				if (defined $contents && $contents ne "") {
					my @variables = ();
					if (!$sym || $sym eq "." || $sym eq "[") {
						@variables = $self->transparent_filters->{$contents} ? WWW::Shopify::Liquid::Token::Variable::Processing->new($line, $self->transparent_filters->{$contents}) : WWW::Shopify::Liquid::Token::String->new($line, $contents);
					}
					elsif ($sym eq "]") {
						@variables = $self->parse_expression($line, $contents);
					}
					push(@parts, @variables) if int(@variables) > 0;
				}
			}
			$start = $+[0] if $sym ne '"' && $sym ne "'" && !$open_bracket;
			$open_bracket++ if ($sym && $sym eq "[");
			
		}
		$squot = !$squot if $token eq "'";
		$dquot = !$dquot if $token eq '"';
	}
	return WWW::Shopify::Liquid::Token::Variable->new($line, @parts);
}

# Returns a single token repsending the whole a expression.
sub parse_expression {
	my ($self, $line, $exp) = @_;
	return () if !defined $exp || $exp eq '';
	my @tokens = ();
	my ($start_paren, $start_space, $level, $squot, $dquot) = (undef, 0, 0, 0, 0);
	# We regex along parentheses, quotation marks (both kinds), whitespace, and non-word-operators.
	# We sort along length, so that we make sure to get all the largest operators first, so that way if a larger operator is made from a smaller one (=, ==)
	# There's no confusion, we always try to match the largest first.
	my $non_word_operators = join("|", map { quotemeta($_) } grep { $_ =~ m/^\W+$/; } sort { length($b) <=> length($a) } keys($self->operators));
	while ($exp =~ m/(?:\(|\)|(?<!\\)"|(?<!\\)'|(\s+|$)|($non_word_operators|,|:))/g) {
		my ($rs, $re, $rc, $whitespace, $nword_op) = ($-[0], $+[0], $&, $1, $2);
		if (!$squot && !$dquot) {
			$start_paren = $re if $rc eq "(" && $level++ == 0;
			# Deal with parentheses; always the highest level of operation.
			if ($rc eq ")" && --$level == 0) {
				$start_space = $re;
				push(@tokens, WWW::Shopify::Liquid::Token::Grouping->new($line, $self->parse_expression($line, substr($exp, $start_paren, $rs - $start_paren))));
			}
			if ($level == 0) {
				# If we're only spaces, that means we're a new a token.
				if (defined $whitespace || $nword_op) {
					if (defined $start_space) {
						my $contents = substr($exp, $start_space, $rs - $start_space);
						push(@tokens, $self->parse_token($line, $contents)) if $contents !~ m/^\s*$/;
					}
					push(@tokens, $self->parse_token($line, $nword_op)) if $nword_op;
					$start_space = $re;
				}
			}
		}
		$squot = !$squot if ($rc eq "'" && !$dquot);
		$dquot = !$dquot if ($rc eq '"' && !$squot);
	}
	die WWW::Shopify::Liquid::Exception::Lexer::UnbalancedBrace->new($line) unless $level == 0;
	# Go through and combine any -1 from OP NUM to NUM.
	my @ids = grep { 
		$tokens[$_]->isa('WWW::Shopify::Liquid::Token::Number') &&
		$tokens[$_-1]->isa('WWW::Shopify::Liquid::Token::Operator') && $tokens[$_-1]->{core} eq "-" &&
		($_ == 1 || $tokens[$_-2]->isa('WWW::Shopify::Liquid::Token::Separator'))
	} 1..$#tokens;
	for (@ids) { $tokens[$_]->{core} *= -1; $tokens[$_-1] = undef; } 
	return grep { defined $_ } @tokens;
}

sub parse_text {
	my ($self, $text) = @_;
	return () unless defined $text;
	my @tokens = ();
	my $start = 0;
	my $line = 1;
	my $column = 0;
	my $lexing_halter = undef;
	
	my $start_line = 1;
	my $start_column = 0;
	my $line_position = 0;
	
	return (WWW::Shopify::Liquid::Token::Text->new(1, '')) if $text eq '';
	
	# No need to worry about quotations; liquid overrides everything.
	while ($text =~ m/(?:(?:{%\s*(\w+)\s*(.*?)\s*%})|(?:{{\s*(.*?)\s*}})|(\n)|$)/g) {
		my ($tag, $arguments, $output) = ($1, $2, $3);
		if (defined $4) {
			++$line;
			$line_position = $+[0];
			next;
		};
		my $column = $+[0] - $line_position;
		my $position = [$start_line, $start_column, $-[0]];
		if ($tag && !$lexing_halter && exists $self->{lexing_halters}->{$tag}) {
			$lexing_halter = $tag;
			push(@tokens, WWW::Shopify::Liquid::Token::Tag->new($position, $tag, [$self->parse_expression($position, $arguments)]));
			$start = $+[0];
			$start_line = $line;
			$start_column = $column;
		}
		elsif ($tag && $lexing_halter && $tag eq "end" . $lexing_halter) {
			$lexing_halter = undef;
		}
		if (!$lexing_halter) {
			if ($start < $-[0]) {
				push(@tokens, WWW::Shopify::Liquid::Token::Text->new($position, substr($text, $start, $-[0] - $start)));
				$start_line = $line;
				$start_column = $-[0] - $line_position;
				$position = [$start_line, $start_column, $-[0]];
			}
			push(@tokens, WWW::Shopify::Liquid::Token::Tag->new($position, $tag, [$self->parse_expression($position, $arguments)])) if $tag;
			push(@tokens, WWW::Shopify::Liquid::Token::Output->new($position, [$self->parse_expression($position, $output)])) if $output;
			$start = $+[0];
			$start_line = $line;
			$start_column = $column;
		}
	}
	return @tokens;
}

sub unparse_token {
	my ($self, $token) = @_;
	return '' unless $token;
	return join(".", map { $_->{core} } @{$token->{core}}) if $token->isa('WWW::Shopify::Liquid::Token::Variable');
	return "(" . join("", map { $self->unparse_token($_); } @{$token->{members}}) . ")" if $token->isa('WWW::Shopify::Liquid::Token::Grouping');
	return $token->{core};
}

sub unparse_expression {
	my ($self, @tokens) = @_;
	return join(' ', map { $self->unparse_token($_) } @tokens);
}

sub unparse_text_segment {
	my ($self, $token) = @_;
	if ($token->isa('WWW::Shopify::Liquid::Token::Tag')) {
		return "{%" . $token->{tag} . "%}" if !$token->{arguments};
		return "{%" . $token->{tag} . " " . $self->unparse_expression(@{$token->{arguments}}) . "%}";
	}
	return "{{" . $self->unparse_expression(@{$token->{core}}) . "}}" if $token->isa('WWW::Shopify::Liquid::Token::Output');
	return $token->{core};
}

sub unparse_text {
	my ($self, @tokens) = @_;
	return join('', map { $self->unparse_text_segment($_) } @tokens);
}

1;