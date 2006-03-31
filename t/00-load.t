#!perl

use Test::More tests => 3;

use_ok( 'Config::Builder' );
use_ok( 'Config::Builder::Parser' );
use_ok( 'Config::Builder::Parser::YAML' );

diag( "Testing Config::Builder $Config::Builder::VERSION, Perl $], $^X" );
