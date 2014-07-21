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
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable');

$ast = $parser->parse_tokens($lexer->parse_text("{% assign a.b = 1 %}"));
ok($ast);

$ast = $parser->parse_tokens($lexer->parse_text("{% if global.total_orders > 1000 %}{% assign global.total_orders = 0 %}{% endif %}{% assign global.total_orders = global.total_orders + order.total_price %}"));
$liquid->verify_text("{% if global.total_orders > 1000 %}{% assign global.total_orders = 0 %}{% endif %}{% assign global.total_orders = global.total_orders + order.total_price %}");
ok($ast);

$ast = $parser->parse_tokens($lexer->parse_text("{% for note in order.note_attributes %}{% if note.name == 'Edition' %}{% assign notes = note | split: '\\n' %}{% for line in notes %}{% if line contains line_item.title %}{% assign parts = line | split: 'edition: ' %}{{ parts | last }}{% endif %}{% endfor %}{% endif %}{% endfor %}"));
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::For');
isa_ok($ast->{contents}, 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{contents}->{true_path}, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{contents}->{true_path}->{operands}->[0], 'WWW::Shopify::Liquid::Tag::Assign');

$ast = $parser->parse_tokens($lexer->parse_text('{% unless global.customer_address[customer.id] %}{% assign global.customer_address[customer.id] = json %}{% endunless %}'));
ok($ast);

$ast = $parser->parse_tokens($lexer->parse_text('{% assign json = customer.addresses | json %}{% unless global.customer_address[customer.id] %}{% assign global.customer_address[customer.id] = json %}{% endunless %}{% if global.customer_address[customer.id] != json %}{% assign global.customer_address[customer.id] = json %}1{% else %}0{% endif %}'));

done_testing();
