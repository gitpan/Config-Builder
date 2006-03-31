#!perl

use Data::Dumper;

use Test::More tests => 7;

use_ok( 'Config::Builder' );

my $cbuilder;

{
	$cbuilder = Config::Builder->new( 'meta_file' => 't/data/meta.yaml', 'user_file' => 't/data/user.yaml' );
	ok($cbuilder, 'Config::Builder object created');
	isa_ok($cbuilder, 'Config::Builder', 'Config::Builder object ref match');
}

{
	is($cbuilder->meta_file, 't/data/meta.yaml', 'meta_file match');
	is($cbuilder->out_file, 't/data/output.txt', 'out_file match');
	is_deeply($cbuilder->{'meta'}->{'targets'}, ['test_a.target.yaml', 'test_b.target.yaml', 'test_c.target.yaml', 'test_d.target.yaml'], 'targets match');
	is($cbuilder->terms_file, 't/data/terms.yaml', 'term_data match');
}
