#!/usr/bin/perl
use strict;
use warnings;

use HTML::Strip;

package WWW::Shopify::Liquid::Filter::StripHtml; use base 'WWW::Shopify::Liquid::Filter';
sub operate { my $hs = HTML::Strip->new(); my $text = $hs->parse($_[2]); $hs->eof; return $text; }

1;