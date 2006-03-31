# $Revision: 342 $ $Source: /myproject/lib/foo.pm $ $Date: $

package Config::Builder;

use warnings;
use strict;

use Carp;
use Cwd qw/abs_path cwd/;
use Data::Dumper;
use English '-no_match_vars';
use File::Spec::Functions;
use File::Basename;
use Hash::Merge qw( merge );
use IO::File;
use Text::Template;
use XML::Simple;
use XML::SAX;
use XML::Filter::XInclude;
use YAML::Syck;

use Config::Builder::Parser;
use Config::Builder::Parser::YAML;

use base qw(Class::Accessor);

__PACKAGE__->mk_accessors(
	qw/out_type out_file out_spec targets has_meta meta/,
	qw/default_target meta_file target user_file terms_file/,
);

our $VERSION = '0.03';

my @included_files;

sub new {
	my ($class, %args) = @_;
	my $self = bless { %args, 'included_files' => [q//] }, $class;
	# Set some defaults if they aren't passed.
	$self->meta_file('meta.yaml');
	if ($args{'meta_file'}) { $self->meta_file($args{'meta_file'}); }
	$self->parse_meta();
	if ($args{'out_type'}) { $self->out_type($args{'out_type'}); }
	if ($args{'out_file'}) { $self->out_file($args{'out_file'}); }
	if ($args{'out_spec'}) { $self->out_spec($args{'out_spec'}); }
	if ($args{'user_file'}) { $self->user_file($args{'user_file'}); }
	if ($args{'terms_file'}) { $self->terms_file($args{'terms_file'}); }
	if ($args{'target'}) { $self->target($args{'target'}); }
	return $self;
}

sub parse_meta {
	my ($self, %args) = @_;
	my $metainfo = $self->parse('file' => $self->meta_file);
	$self->{'has_meta'} = 1;
	if ($metainfo->{'output'}) {
		if ($metainfo->{'output'}->{'type'}) { $self->out_type($metainfo->{'output'}->{'type'}); }
		if ($metainfo->{'output'}->{'file'}) { $self->out_file($metainfo->{'output'}->{'file'}); }
		if ($metainfo->{'output'}->{'spec'}) { $self->out_spec($metainfo->{'output'}->{'spec'}); }
	}
	if ($metainfo->{'default_target'}) { $self->default_target($metainfo->{'default_target'}); }
	if ($metainfo->{'user_file'}) { $self->user_file($metainfo->{'user_file'}); }
	if ($metainfo->{'terms'}) { $self->terms_file($metainfo->{'terms'}); }
	$self->meta($metainfo);
	return;
}

sub generate {
	my ($self) = @_;
	my (@targets, %mergeconfig);
	my $target = $self->{'target'} ? $self->target(): $self->default_target();
	my $metainfo = $self->meta();
	push @targets, $target;
	# hack: Check to see if a user file exists. If it does its data will over-
	#       ride and be inherited from everything.
	if (my $file = $self->find_file( $self->user_file())) {
		push @targets, $self->user_file();
	}
	my $rulecount = 0;
	foreach my $configitem (@targets) {
		my $config = $self->parse( 'file' => $configitem);
		# hack: try to break out of any loops or circular rules
		if ($mergeconfig{$configitem}) { next; }
		$mergeconfig{$configitem} = $config;
		if ($config->{'rules'}) {
			foreach my $rule ( @{$config->{'rules'}} ) {
				if ($rule->{'type'} && $rule->{'type'} eq 'merge') {
					if ($rule->{'from'}) {
						push @targets, $rule->{'from'};
						$mergeconfig{'rules'}{$rulecount++} = 'merge from '.$rule->{'from'}.' to '.$configitem;
					}
				}
				if ($rule->{'type'} && $rule->{'type'} eq 'inherit') {
					$mergeconfig{'rules'}{$rulecount++} = 'inherit '.$configitem;
				}
			}
		}
	}
	$mergeconfig{'rules'}{$rulecount++} = 'init merge';
	# Start from the end rule and work our way forward.
	for my $cr (reverse 0 .. $rulecount) {
		my $rule = $mergeconfig{'rules'}{$cr};
		if (! $rule) { next; }
		if ($rule eq 'init merge') {
			$mergeconfig{'last'} = {};
		}
		if ($rule =~ m/merge\sfrom\s([^ ]*)\sto\s(.*)/ixm) {
			my $tmp = merge( $mergeconfig{$2}, $mergeconfig{$1} );
			$mergeconfig{'last'} = merge( $mergeconfig{'last'}, $tmp );
		}
		if ($rule =~ m/inherit\s+(.*)/ixm) {
			$mergeconfig{'last'} = merge( $mergeconfig{'last'}, $mergeconfig{$1} );
		}
		delete $mergeconfig{'last'}{'rules'};
	}
	
	my %mergehash;
	# $mergehash = $mergeconfig{'last'};
	# hack: cleanup the mergeconfig file since it is no longer being used.
	# map { delete $mergeconfig{$_} } keys %{ $mergeconfig };

	my $terms = $self->parse( file => $self->terms_file() );
	if (! $terms) {
		print STDERR "Could not load terms file.\n";
		return;
	}
	
	for my $term ( sort keys %{$terms->{'terms'}} ) {
		# find if the term is being used
		if ($mergeconfig{'last'}{$term}) {
			# set the term hash ( type, value)
			$mergehash{'vars'}{$term}{'type'} = $terms->{'terms'}{$term}{'type'};
			$mergehash{'vars'}{$term}{'value'} = $mergeconfig{'last'}{$term};
			delete $mergeconfig{'last'}{$term};
		}
	}

	if ($self->out_type eq 'yaml'){ $self->_write_yaml($mergehash{'vars'}); }
	if ($self->out_type eq 'template'){ $self->_write_template($mergehash{'vars'}); }

	return 1;
}

sub _write_yaml {
	my ($self, $vars) = @_;
	DumpFile($self->out_file, $vars);
	return;
}

sub _write_template {
	my ($self, $vars) = @_;
	my @configkeys = keys %{$vars};
	my %vars = (
		'configkeys' => [ @configkeys ],
		'vars' => $vars,
	);
	my $tmpl = $self->find_file($self->out_spec());
	my $template = Text::Template->new( SOURCE => $tmpl);
	if (! $template) {
		die "Couldn't construct template: $Text::Template::ERROR";
	}
	my $result = $template->fill_in(HASH => \%vars);
	if (! $result) {
		die "Couldn't fill in template: $Text::Template::ERROR";
	}
	my $fh = new IO::File '> '.$self->out_file;
	if (defined $fh) {
		print $fh $result;
		$fh->close;
	}
	return;
}

sub parse {
	my ($self, %args) = @_;
	my $file = $self->find_file($args{'file'} || undef);
	if (! $file) {
		carp("File $args{'file'} not found.");
		return;
	}
	my $parser_type = exists $args{'type'} ? delete $args{'type'} : 'YAML';
	$args{'file'} = abs_path($file);
	$self->add_file($args{'file'});
	my $parser = Config::Builder::Parser->new($parser_type, %args);
	return $parser->parse();
}

sub add_file {
	my ($self, $filename) = @_;
	push @{ $self->{'included_files'} }, $filename;
	return 1;
}

sub files {
	my ($self) = @_;
	return $self->{'included_files'};
}

sub find_file {
	my ($self, $file, $path) = @_;
	my $bindir = dirname($EXECUTABLE_NAME);
	my $cwd = cwd();
	my ($x, @filenames);
	if ($file) {
		if ($file =~ m/(yaml|tmpl|xml|txt)$/mx) { push @filenames, $file; }
		push @filenames, $file.'.target.yaml';
		push @filenames, $file.'.tmpl';
	}
	if (! $self->{'has_meta'}) {
		push @filenames, 'meta.yaml', 'config.yaml', 'configbuilderrc';
	}
	foreach my $filename (@filenames) {
		if ($path && -e ($x = catfile($path, $filename))) { return $x; }
		if (-e ($x = catfile($cwd, 'data/', $filename))) { return $x; }
		if (-e ($x = catfile($cwd, $filename))) { return $x; }
		if (-e ($x = catfile($cwd, 't/data/', $filename))) { return $x; }
		if (-e ($x = catfile($cwd, 'templates/', $filename))) { return $x; }
	}
	return;
}

1;
__END__

=head1 NAME

Config::Builder - A configuration builder

=head1 SYNOPSIS

  use Config::Builder;
  my $cbuilder = Config::Builder->new();
  $cbuilder->generate();

=head1 DESCRIPTION

This module is a configuration builder. It takes in gramar and spec files to
create a single point of configuration for other applications.

It primarily uses YAML.

=head1 GETTING STARTED

To get started, follow these steps:

  ./bin/termbuilder.pl - build the term list
  ./bin/targetbuilder.pl - build the target files
  ./bin/buildconfig.pl - generate a config based on data/meta.yaml

=head1 META

This module does have a set of defaults but doesn't really know what it is
doing without a meta file. In this case it uses meta.yaml to point it in the
right direction.

The meta.yaml file contains the following.

=over

=item default_target

This value defines the default target to build if none is specified.

=item flags

This value is an array of flags that are applied to the config builder.

=item output

This value is a hash containing output specs.

The key/values are:

  file - The file to write to
  type - The output type. Can be either 'template' or 'yaml'.
  spec - The template file to use.

=item targets

An array of *.target.yaml files that can be used.

=item terms

This value points to the terms file to use.

=item version

This is not currently being used.

=back

This is an example meta.yaml file.

  --- 
  default_target: dev
  flags: 
    - strict
    - warnings
  output: 
    file: Config.pm
    spec: perlmodule
    type: template
  targets: 
    - dev.target.yaml
    - common.target.yaml
  terms: terms.yaml
  version: 1.0

=head1 TERMS

Terms are allowed variables. During the postproccessing phase it cycles
through the list of known and current variables to make sure that all
references match.

The strict and warnings flags define if the unkown config directives will
cause warnings or be pruned.

This is an example term.yaml file.

  --- 
  terms: 
    AboutStyles: 
      type: HASH
    AcceptRichTextMail: 
      default: 0
      type: SCALAR

Note that there are 4 distinct types: SCALAR, ARRAY, HASH and HASHARRAY. Only
scalars can have default values.

=head1 TARGETS

Targets are sections of config data that are parses and processed. They are
identified by name and contain actual variables and variable values.

Targets can also contain rules.

This is an example target.yaml file.

  --- 
  MemcachedServers: 
    - 
      key: GeneralPool
      value: memcache1.example.com:11211
    - 
      key: GeneralPool
      value: memcache2.example.com:11211
  NoTempFiles: 1
  WebServers: 
    - 192.168.30.1
    - 192.168.30.1
  rules: 
    - 
      type: merge
      from: common.target.yaml

=head2 RULES

Rules define the complex behavior of targets.

There are 3 types of rules: merge, init and inherit.

The init rule simply tells the processor that the merge hash needs to be
initilized.

The merge rule tells the processor that it needs to merge target x and y
before it can absorb the values.

The inherit rule is for user.yaml files and tells the processor that its rules
override everything else.

=head1 OVERIDING TARGETS

In order to overide a target's config you must touch a user.yaml file.

The user.yaml file MUST contain the following rule:

  rules: 
    - 
      type: inherit

For all intensive purposes a user.yaml file is exactly like a target.yaml
file in all other respects.


=head1 SUBROUTINES / METHODS

=head2 files

=head2 new

=head2 parse

=head2 parse_meta

=head2 generate

=head2 add_file

=head2 find_file

=head1 AUTHOR

Nick Gerakines, C<< <nick at socklabs.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Config-Builder at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Builder>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Builder

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Builder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-Builder>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Builder>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-Builder>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

