#!/usr/bin/perl

use strict;
use warnings;

use YAML::Syck;

{
	my %targets = (
		'common' => {
			'WebRoot' => '/var/www/htdocs',
			'Database' => 'testapp',
			'MemcachedServers' => [
				{ 'key' => 'GeneralPool', 'value' => 'memcache1.example.com:11211' },
				{ 'key' => 'GeneralPool', 'value' => 'memcache2.example.com:11211' },
				{ 'key' => 'ObjectPool', 'value' => 'memcache3.example.com:11211' },
				{ 'key' => 'ObjectPool', 'value' => 'memcache4.example.com:11211' },
			]
		},
		'dev' => {
			'rules' => [ { 'type' => 'merge', 'from' => 'common' } ],
			'WebRoot' => '/var/www/dev.htdocs',
		},
		'admin' => {
			'rules' => [ { 'type' => 'merge', 'from' => 'common' } ],
		},
		'qa' => {
			'rules' => [ { 'type' => 'merge', 'from' => 'common' } ],
			'WebRoot' => '/var/www/qa.htdocs',
			'MemcachedServers' => [
				{ 'key' => 'GeneralPool', 'value' => 'localhost:11211' },
			]
		},
		'web' => {
			'rules' => [ { 'type' => 'merge', 'from' => 'common' } ],
		},
	);
	my @targetlist;
	for my $target ( keys %targets ) {
		push @targetlist, $target.'.target.yaml';
		DumpFile('data/'.$target.'.target.yaml', $targets{$target});
	}
	{
		my %metadata = (
			'type' => 'config',
			'terms' => 'terms.yaml',
			'flags' => [qw/strict warnings/],
			'output' => { 'type' => 'yaml', 'spec' => 'default.spec', 'file' => 'config.yaml' },
			'targets' => [ sort @targetlist ],
			'default_target' => 'dev',
			'version' => '1.0',
		);
		DumpFile('data/meta.yaml', \%metadata);
	}
}
