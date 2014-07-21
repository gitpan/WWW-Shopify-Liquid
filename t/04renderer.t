use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");
use_ok("WWW::Shopify::Liquid::Optimizer");
use_ok("WWW::Shopify::Liquid::Renderer");
my $liquid = WWW::Shopify::Liquid->new;
my $lexer = $liquid->lexer;
my $parser = $liquid->parser;
my $optimizer = $liquid->optimizer;
my $renderer = $liquid->renderer;

my $text = $renderer->render({}, $optimizer->optimize({}, $parser->parse_tokens($lexer->parse_text("{% for a in (1..10) %}{{ a.b }}{% endfor %}"))));
is($text, '');
$text = $renderer->render({}, $optimizer->optimize({}, $parser->parse_tokens($lexer->parse_text("{% for a in (1..10) %}{{ a }}{% endfor %}"))));
is($text, '12345678910');
$text = $renderer->render({}, $parser->parse_tokens($lexer->parse_text("{% for a in (1..10) %}{{ a }}{% endfor %}")));
is($text, '12345678910');

use WWW::Shopify::Liquid qw(liquid_render_text);
my $email = "Hi {% if customer %}{{ customer.first_name }} {{ customer.last_name }}{%else%}Unknown Customer{%endif %}!";
$text = liquid_render_text({ customer => { first_name => "Adam", last_name => "Harrison" } }, $email);
is($text, "Hi Adam Harrison!");
$text = liquid_render_text({}, $email);
is($text, "Hi Unknown Customer!");

$text = liquid_render_text({ test => "asd" }, "{% case test %}{% when 'a' %}dafsd{% when 'b' %}{%else %}hghgh{% endcase %}"); is($text, 'hghgh');
$text = liquid_render_text({ test => "a" }, "{% case test %}{% when 'a' %}dafsd{% when 'b' %}{%else %}hghgh{% endcase %}"); is($text, 'dafsd');


$text = liquid_render_text({ test => "a" }, "{% assign test = 2 %}{{ test }}"); is($text, '2');

$text = liquid_render_text({ test => "a" }, "{% for a in (1..10) %}{% case a %} {% when 10 %}A {% when 1 %}B{% else %}C{% endcase %}{% endfor %}"); is($text, 'BCCCCCCCCA ');


$text = liquid_render_text({ files => [{ extension => "pdf" }, { extension => "wrd" }, { extension => "png" }] }, "{% for file in files %}{{ file.extension }}{% endfor %}");
is($text, 'pdfwrdpng');

$text = liquid_render_text({ instructions => "" }, "{% if instructions %}A{% else %}B{% endif %}"); is($text, 'B');

$text = liquid_render_text({ duration => "3 months" }, "{{ duration | split: ' ' | first }}"); is($text, '3');

$text = liquid_render_text({ 
	global => { customer_address => { 1234 => 'asd' } }, 
	customer => { id => 1234 } 
}, '{{ global.customer_address[customer.id] }}');
is($text, 'asd');

$text = liquid_render_text({ test_array => [{ src => "asdasf" }, { src => "dfhdfh" }, { src => "5135" }] }, "{{ test_array[1].src }}"); is($text, 'dfhdfh');

done_testing();