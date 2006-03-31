# $Revision: 342 $Source: /myproject/lib/foo.pm $Date: $

package Config::Builder::Parser;

use warnings;
use strict;

our $VERSION = '0.01';

sub new {
	my ($class, $subclass, %args) = @_;
	if ($subclass) { $class = join q{::}, $class, $subclass; }
	my $self = bless { %args }, $class;
	$self->_init();
	return $self;
}

sub _init { return; }

1;
__END__

=pod

=head1 NAME

Config::Builder::Parser - stub description

=head1 DESCRIPTION

This is a stub description. It needs some real attention.

=head1 SUBROUTINES/METHODS

=head2 new

=head1 EXPORTS

This module exports the following: NONE

=head1 DIAGNOSTICS

This module has no recorded diagnostic information.

=head1 SEE ALSO

=head1 COPYRIGHT

(c) Copyright 2006 Nick Gerakines. All rights reserved.

=cut
