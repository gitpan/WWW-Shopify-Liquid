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

my $ast = $parser->parse_tokens($lexer->parse_text("{{ a.b }}"));
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::Output');
isa_ok($ast->{arguments}, 'WWW::Shopify::Liquid::Token::Variable');

done_testing();
