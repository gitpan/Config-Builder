# $Revision: 342 $Source: /myproject/lib/foo.pm $Date: $

package Config::Builder::Parser::YAML;

use warnings;
use strict;

use base qw/Config::Builder::Parser/;

our $VERSION = '0.01';

use YAML::Syck;

sub _init {
	my ($self) = @_;
	return;
}

sub parse {
	my ($self, $config) = @_;
	if ($self->{'string'}) {
		$config = Load($self->{'string'});
	} elsif($self->{'file'}) {
		$config = LoadFile($self->{'file'});
	}
	return %{$config} if wantarray;
	return $config;
}

1;
__END__

=pod

=head1 NAME

Config::Builder::Output - stub description

=head1 DESCRIPTION

This is a stub description. It needs some real attention.

=head1 SUBROUTINES/METHODS

=head2 parse

=head1 EXPORTS

This module exports the following: NONE

=head1 DIAGNOSTICS

This module has no recorded diagnostic information.

=head1 SEE ALSO

=head1 COPYRIGHT

(c) Copyright 2006 Nick Gerakines. All rights reserved.

=cut
