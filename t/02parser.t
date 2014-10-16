use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");
my $liquid = WWW::Shopify::Liquid->new;
my $lexer = $liquid->lexer;
my $parser = $liquid->parser;

my $ast = $parser->parse_tokens($lexer->parse_text("{% for a in (1..10) %}sdfasdfds{% endfor %}"));
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::For');
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Operator::In');
isa_ok($ast->{arguments}->[0]->{operands}->[0], 'WWW::Shopify::Liquid::Token::Variable');
isa_ok($ast->{arguments}->[0]->{operands}->[1], 'WWW::Shopify::Liquid::Operator::Array');
isa_ok($ast->{arguments}->[0]->{operands}->[1]->{operands}->[0], 'WWW::Shopify::Liquid::Token::Number');
is($ast->{arguments}->[0]->{operands}->[1]->{operands}->[0]->{core}, 1);
is($ast->{arguments}->[0]->{operands}->[1]->{operands}->[1]->{core}, 10);

$ast = $parser->parse_tokens($lexer->parse_text("{% if a %}asfdsdfds{% else %}sadfsdf{% endif %}"));
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable');
isa_ok($ast->{true_path}, 'WWW::Shopify::Liquid::Token::Text');
isa_ok($ast->{false_path}, 'WWW::Shopify::Liquid::Token::Text');

$ast = $parser->parse_tokens($lexer->parse_text("{% if a %}{% else %}{% endif %}"));
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::If');
ok(!defined $ast->{true_path});
ok(!defined $ast->{false_path});

$ast = $parser->parse_tokens($lexer->parse_text(" {% if a %}asdfsdfdsaf{% else %} {% for a in (1..10) %}{{ a }}{% endfor %}{% endif %}"));
isa_ok($ast, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{operands}->[0], 'WWW::Shopify::Liquid::Token::Text');
isa_ok($ast->{operands}->[1], 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{operands}->[1]->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable');
isa_ok($ast->{operands}->[1]->{true_path}, 'WWW::Shopify::Liquid::Token::Text');
isa_ok($ast->{operands}->[1]->{false_path}, 'WWW::Shopify::Liquid::Operator::Concatenate');

$ast = $parser->parse_tokens($lexer->parse_text("{% for a in (1..10) %}{{ a }}{% endfor %}"));
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::For');
isa_ok($ast->{contents}, 'WWW::Shopify::Liquid::Tag::Output');

eval {}; ok(!$@); eval { $parser->parse_tokens($lexer->parse_text(" {% ifsadfa a %}asdfsdfdsaf{% else %} {% sdfhgdfh a in (1..10) %}{{ a }}{% endfor %}{% endif %}")); }; ok($@);
eval {}; ok(!$@); eval { $parser->parse_tokens($lexer->parse_text(" {% if a %}asdfsdfdsaf{% else %} {% for a in (1..10) %}{{ a }}{% endfor %}{% endif %}")); }; ok(!$@);
eval {}; ok(!$@); eval { $parser->parse_tokens($lexer->parse_text(" {% if a %}asdfsdfdsaf{% else %} {% for a in (1.10) %}{{ a }}{% endfor %}{% endif %}")); }; ok(!$@);

$ast = $parser->parse_tokens($lexer->parse_text("{% if a %}asdfsdfdsaf{% else %}{{ 'asdfsad' | split: 'asd' }}{% endif %}"));
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{true_path}, 'WWW::Shopify::Liquid::Token::Text');
isa_ok($ast->{false_path}, 'WWW::Shopify::Liquid::Tag::Output');

$ast = $parser->parse_tokens($lexer->parse_text("{{ test_array[1].src }}"));
ok($ast);
isa_ok($ast, "WWW::Shopify::Liquid::Tag::Output");

done_testing();