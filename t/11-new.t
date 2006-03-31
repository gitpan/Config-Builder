#!perl

use Data::Dumper;

use Test::More tests => 3;

use_ok( 'Config::Builder' );

my $cbuilder;

{
	$cbuilder = Config::Builder->new;
	ok($cbuilder, 'Config::Builder object created');
	isa_ok($cbuilder, 'Config::Builder', 'Config::Builder object ref match');
}
