use Module::Build;

my $build = Module::Build->new(
	module_name => 'WWW-Shopify-Liquid',
	license_from => 'lib/WWW/Shopify/Liquid.pm',
	dist_author_from => 'lib/WWW/Shopify/Liquid.pm',
	dist_version_from => 'lib/WWW/Shopify/Liquid.pm',
	configure_requires => { 'Module::Build' => 0.38 },
	requires => {
		'Scalar::Util' => 0,
		'Clone' => 0,
		'URI::Escape' => 0,
		'File::Slurp' => 0,
		'JSON' => 0,
		'HTML::Strip' => 0,
		'List::Util' => 0,
		'List::MoreUtils' => 0,
		'Digest::MD5' => 0,
		'Module::Find' => 0,
		'Devel::StackTrace' => 0,
		'Data::Compare' => 0
	}
);
$build->create_build_script;
