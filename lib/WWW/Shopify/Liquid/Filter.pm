
package WWW::Shopify::Liquid::Filter;
sub new { my $package = shift; return bless { operand => shift, arguments => [@_] }, $package; }
sub transparent { return 0; }
sub name { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; $package =~ s/^.*:://; $package =~ s/([a-z])([A-Z])/$1_$2/g; return lc($package);  }
sub min_arguments { return 0; }
sub max_arguments { return undef; }
sub verify {
	my ($self) = @_;
	my $count = int(@{$self->{arguments}});
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self) if
		$count < $self->min_arguments || (defined $self->max_arguments && $count > $self->max_arguments);
}

1;