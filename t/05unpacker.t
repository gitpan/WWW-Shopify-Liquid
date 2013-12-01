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
use_ok("WWW::Shopify::Liquid::Optimizer");
use_ok("WWW::Shopify::Liquid::Renderer");
my $liquid = WWW::Shopify::Liquid->new;
my $lexer = $liquid->lexer;
my $parser = $liquid->parser;
my $optimizer = $liquid->optimizer;
my $renderer = $liquid->renderer;


# my $original_text = " {%if a.b%}asdfsdfdsaf{%else%} {%for a in (1..10)%}{{a}} fdsfds{%if b%}{{b}}{%else%}sfasdf{%endif%}{%endfor%}{%endif%}";
# my @tokens = $lexer->parse_text($original_text);

# my $ast = $parser->parse_tokens(@tokens);
# @tokens = $parser->unparse_tokens($ast);

# my $text = $lexer->unparse_text(@tokens);
# is($text, $original_text);

done_testing();