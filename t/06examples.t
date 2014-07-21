my $string = '<img src=http://cdn.shopify.com/s/files/1/0291/4345/t/2/assets/logo.png?171> <alt=UCC Resources><br><br>
Thanks for purchasing Faith Practices, all the resources can be found here: <a href="http://www.ucc.org/faith-practices/fp-secure/">http://www.ucc.org/faith-practices/fp-secure/</a>.<br><br>
Date {{ date | date: "%m/%d/%Y" }}{% if requires_shipping and shipping_address %}<br><br><b>Shipping address</b><br>
   {{ shipping_address.name }}<br>
   {{ shipping_address.street }}<br>
   {{ shipping_address.city }}, {{ shipping_address.province }}  {{ shipping_address.zip }}<br><br>
  {% endif %}{% if billing_address %}

 <b>Billing address</b><br>
   {{ billing_address.name }}<br>
   {{ billing_address.street }}<br>
   {{ billing_address.city }}, {{ billing_address.province }}  {{ billing_address.zip }}v
{% endif %}<br><br>
 
<b><ul>{% for line in line_items %} <li> <img src="{{ line.product.featured_image | product_img_url: "thumb" }}" /> {{ line.quantity }}x {{ line.title }} for {{ line.price | money }} each {% for note in line.properties %} {{note.first}} : {{note.last}} {% endfor %} </li> {% endfor %}</ul></b><br><br>

{% if discounts %}Discount (code: {{ discounts.first.code }}): {{ discounts_savings | money_with_currency }}{% endif %}<br>
Subtotal  : {{ subtotal_price | money_with_currency  }}{% for tax_line in tax_lines %}
{{ tax_line.title }}       : {{ tax_line.price | money_with_currency  }}{% endfor %}{% if requires_shipping %}<br>
Shipping  : {{ shipping_price | money_with_currency }}{% endif %}<br>
<p>Total : {{ total_price | money_with_currency }}</p><ul style="list-style-type:none"><br>{% assign gift_card_applied = false %}
{% assign gift_card_amount = 0 %}
{% for transaction in transactions %}
 {% if transaction.gateway  == "gift_card" %}
   {% assign gift_card_applied = true %}
   {% assign gift_card_amount = gift_card_amount | plus: transaction.amount %}
 {% endif %}
{% endfor %}
{% if gift_card_amount > 0 %}
<p>Gift cards: {{ gift_card_amount | times: -1 | money_with_currency }}</p>
{% endif %}
<p><b>Total: {{ total_price | minus: gift_card_amount | money_with_currency }}</p></b>

<br><br>Thank you for shopping with UCC Resources!<br>
{{ shop.url }}';

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



my @tokens = $lexer->parse_text($string);
ok(@tokens);

my $ast = $parser->parse_tokens(@tokens);
ok($ast);


my $proverbs = '{% assign a = 0 %}{% for i in order.shipping_lines %}{% assign a = a + i.price %}{% endfor %}{% if line_item.loop_index == 0 %}$ {{ a + (line_item.price * line_item.quantity) + order.total_tax - order.total_discounts }}{% else %}$ {{ line_item.quantity * line_item.price }}{% endif %}';
$ast = $parser->parse_tokens($lexer->parse_text($proverbs));
my $result = $liquid->render_ast({ order => {
	shipping_lines => [{
		price => 10
	}],
	total_tax => 20,
	total_discounts => 1
}, line_item => {
	loop_index => 0,
	price => 10,
	quantity => 2
} }, $ast);
is($result, ('$ ' . '' . (10+(10*2)+20-1)));

done_testing();