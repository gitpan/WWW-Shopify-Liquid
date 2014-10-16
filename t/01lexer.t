use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");

my $lexer = WWW::Shopify::Liquid->new->lexer;

my @tokens = $lexer->parse_text('{% if a %}	bd{%else%} {%if d%}flkdsajglk jfhdl{%else%}sa dfsdf{%endif%} {%endif%}');
is(int(@tokens),11);
is(@{$tokens[0]->{arguments}}, 1);
@tokens = $lexer->parse_text('{% for i in (1..2) %}adlkgjf{% endfor %}');
is(int(@tokens), 3);
is(@{$tokens[0]->{arguments}}, 3);
is(@{$tokens[0]->{arguments}->[2]->{members}}, 3);

@tokens = $lexer->parse_text(' {% for i in (1..2) %}{{ i }}{% endfor %}'); is(int(@tokens), 4);
@tokens = $lexer->parse_text(' {% for i in (1..2) %}{{ i }}{% endfor %} '); is(int(@tokens), 5);
@tokens = $lexer->parse_text('{% for i in (1..2) %}{{ i }}{% endfor %} ');
is(int(@tokens), 4);
is($tokens[0]->{line}->[1], 0);
is($tokens[1]->{line}->[1], 21);
is($tokens[2]->{line}->[1], 28);
is($tokens[3]->{line}->[1], 40);

@tokens = $lexer->parse_text('{% for i in (1..2) %}
	{{ i }}
{% endfor %} ');
is(int(@tokens), 6);
is($tokens[0]->{line}->[1], 0);
is($tokens[1]->{line}->[1], 21);
is($tokens[2]->{line}->[1], 1);
is($tokens[3]->{line}->[1], 8);
is($tokens[4]->{line}->[1], 0);
is($tokens[5]->{line}->[1], 12);

@tokens = $lexer->parse_text(' {{ a }} {{ b }}!'); is(int(@tokens), 5);
@tokens = $lexer->parse_text(' {{ a }} {{ b }}'); is(int(@tokens), 4);
@tokens = $lexer->parse_text('{{ a }} {{ b }}!'); is(int(@tokens), 4);

@tokens = $lexer->parse_text('Hi{% if customer %}{{ customer.first_name }} {{ customer.lastname }}{%endif%}!'); is(int(@tokens), 7);

@tokens = $lexer->parse_text('{% unless template == \'cart\' %}
<div class="cart-overlay" style="display: none;">
<style>
	.cart-body-interior {
		overflow-y: scroll;
	}
</style>
{% endunless %}');
is(int(@tokens), 3);
is(int(@{$tokens[0]->{arguments}}), 3);



@tokens = $lexer->parse_text("{{ variant[1] }}");

is(int(@tokens), 1);
isa_ok($tokens[0]->{core}->[0], "WWW::Shopify::Liquid::Token::Variable");
is(int(@{$tokens[0]->{core}->[0]->{core}}), 2);


@tokens = $lexer->parse_text("{{ variant['option' + 1] }}");
is(int(@tokens), 1);
is(int(@{$tokens[0]->{core}}), 1);
isa_ok($tokens[0]->{core}->[0], "WWW::Shopify::Liquid::Token::Variable");


@tokens = $lexer->parse_text("{% assign color = 1 %}{% if color %}{{ variant['option' + color] }}{% endif %}");

is(int(@tokens), 4);
isa_ok($tokens[0], "WWW::Shopify::Liquid::Token::Tag");
isa_ok($tokens[1], "WWW::Shopify::Liquid::Token::Tag");
isa_ok($tokens[2], "WWW::Shopify::Liquid::Token::Output");
isa_ok($tokens[3], "WWW::Shopify::Liquid::Token::Tag");


done_testing();