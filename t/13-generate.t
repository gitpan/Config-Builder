#!perl

use Cwd qw/abs_path cwd/;
use Data::Dumper;

use Test::More tests => 10;

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

{
	$cbuilder->generate();
	ok(-f 't/data/output.txt', 'output file exists');
	my $output = $cbuilder->parse('file' => 't/data/output.txt');
	is_deeply($output, {
		'firstname' => {'value' => 'testy','type' => 'SCALAR'},
		'email' => {'value' => [{'value' => 'testy@sixapart.com','key' => 'work'},{'value' => 'testy@testy.name','key' => 'home'},{'value' => 'testy@work.net','key' => 'work'},{'value' => 'testy@gmail.com','key' => 'other'}],'type' => 'HASH'},
		'lastname' => {'value' => 'mctester','type' => 'SCALAR'},
		'username' => {'value' => 'testy','type' => 'SCALAR'}
	}, 'output match');
}

{
	my $files = $cbuilder->files();
	is_deeply($files, [
		'',
		abs_path('t/data/meta.yaml'),
		abs_path('t/data/test_a.target.yaml'),
		abs_path('t/data/user.yaml'),
		abs_path('t/data/test_b.target.yaml'),
		abs_path('t/data/test_c.target.yaml'),
		abs_path('t/data/terms.yaml'),
		abs_path('t/data/output.txt'),
	], 'files match');
}

if (-f 't/data/output.txt') {
	unlink 't/data/output.txt';
}
