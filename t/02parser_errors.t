use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");
my $liquid = WWW::Shopify::Liquid->new;
my $lexer = $liquid->lexer;
my $parser = $liquid->parser;

my %errors = (
"{% if customer %}
	{{ customer.first_name }}
	{{ customer.lastname }}
{% endif %}

nadsljkfhlksjdfhkjsdhf

{% sadfsdf %}

{% endif %}" => ['WWW::Shopify::Liquid::Exception::Parser::UnknownTag', 8, 0],
"{% if customer %}
	{% for 1 in (1..10) %}
		{{ customer.first_name }}
		{{ customer.lastname }}
{% endif %}
" => ['WWW::Shopify::Liquid::Exception::Parser::NoClose', 2, 1],
"{% if customer
	{{ customer.first_name }}
	{{ customer.lastname }}
{% endif %}" => ['WWW::Shopify::Liquid::Exception::Parser::NoOpen', 4, 0],
"{% if customer %}
	{{ customer.first_name + + 2 }}
	{{ customer.lastname }}
{% endif %}" => ['WWW::Shopify::Liquid::Exception::Parser::Operands', 2, 1],
"{%else %}{% if customer %}
	{{ customer.first_name + + 2 }}
	{{ customer.lastname }}
{% endif %}" => ['WWW::Shopify::Liquid::Exception::Parser::NakedInnerTag',1,0],
"{{ sdff.hgdd 3 }}" => ['WWW::Shopify::Liquid::Exception::Parser::Operands', 1,0]
);

for (keys(%errors)) {
	my $i = undef;
	eval { $i = $parser->parse_tokens($lexer->parse_text($_)) };
	ok(!$i);
	ok($@);
	isa_ok($@, $errors{$_}->[0], $_);
	is($@->line, $errors{$_}->[1], $_);
	is($@->column, $errors{$_}->[2], $_) if int(@{$errors{$_}}) == 3;
}

done_testing();