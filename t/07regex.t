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


use WWW::Shopify::Liquid qw(liquid_render_text);

my $text = liquid_render_text({}, "{% assign test = ('asd' =~ '(a)') %}{{ test[0] }}"); is($text, 'a');
$text = liquid_render_text({}, "{% assign test = ('asd' =~ '(a)') %}{% if test %}1{% endif %}"); is($text, '1');
$text = liquid_render_text({}, "{% assign test = ('asd' =~ 'a') %}{% if test %}{{ test[0] }}{% endif %}"); is($text, '1');


done_testing();