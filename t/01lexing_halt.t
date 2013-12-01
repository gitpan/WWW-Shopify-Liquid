use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");

my $lexer = WWW::Shopify::Liquid->new->lexer;

my @tokens = $lexer->parse_text("{% if a %}
	{{ a }}
	{% raw %}
	sadflsjdfksdfd {% if b %}
	{% endif %}
	{% endraw %}
{% endif %}");

is(int(@tokens), 8);

@tokens = $lexer->parse_text("{% comment %}
	{{ a }}
	{% raw %}
	sadflsjdfksdfd {% if b %}
	{% endif %}
	{% endraw %}
{% endcomment %}");

is(int(@tokens), 3);

done_testing();