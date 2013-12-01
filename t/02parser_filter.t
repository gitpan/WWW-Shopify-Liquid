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
my $ast;

$ast = $parser->parse_tokens($lexer->parse_text("{{ 1 | plus: 1 | minus: 2 }}"));

isa_ok($ast, 'WWW::Shopify::Liquid::Tag::Output');

isa_ok($ast->{arguments}, 'WWW::Shopify::Liquid::Filter::Minus');
isa_ok($ast->{arguments}->{operand}, 'WWW::Shopify::Liquid::Filter::Plus');
isa_ok($ast->{arguments}->{operand}->{operand}, 'WWW::Shopify::Liquid::Token::Number');

$ast = $parser->parse_tokens($lexer->parse_text("{% assign a = 1 | plus: 1 | minus: 2 %}"));
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::Assign');
isa_ok($ast->{arguments}, 'WWW::Shopify::Liquid::Operator::Assignment');

done_testing();