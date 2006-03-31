#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Config::Builder',
	license             => 'perl',
	create_readme       => 1,
	create_packlist     => 1,
	dist_author         => 'Nick Gerakines <nick@socklabs.com>',
	dist_version_from   => 'lib/Config/Builder.pm',
	build_requires => {
		'Carp' => 0,
		'Cwd' => 0,
		'Data::Dumper' => 0,
		'English' => 0,
		'File::Spec::Functions' => 0,
		'File::Basename' => 0,
		'Hash::Merge' => 0,
		'IO::File' => 0,
		'Text::Template' => 0,
		'XML::Simple' => 0,
		'XML::SAX' => 0,
		'XML::Filter::XInclude' => 0,
		'YAML::Syck' => 0,
	},
	recommends => {
		'Test::Pod' => 0,
		'Test::Pod::Coverage' => 0,
		'Test::Perl::Critic' => 0,
	},
	add_to_cleanup      => [
		'Config-Builder-*',
		'data/*.target.yaml',
		'data/terms.yaml',
		'user.yaml',
		'data/terms.yaml',
		'config.yaml',
		'output.txt',
		't/data/output.*',
	],
);

$builder->create_build_script();
