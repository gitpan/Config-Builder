#!/usr/bin/perl

use strict;
use warnings;

use YAML::Syck;

{
	my %testhash = (
		'terms' => {
			'WebRoot' => { 'type' => 'SCALAR' },
			'MemcachedServers' => { 'type' => 'SCALAR' },
			'Database' => { 'type' => 'SCALAR' },
		},
	);
	my $yaml = Dump(\%testhash);
	DumpFile('data/terms.yaml', \%testhash);
}
