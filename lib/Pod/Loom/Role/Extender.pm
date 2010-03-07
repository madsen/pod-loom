#---------------------------------------------------------------------
package Pod::Loom::Role::Extender;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: October 16, 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Role to simplify extending a template
#---------------------------------------------------------------------

use 5.008;
our $VERSION = '0.03';
# This file is part of {{$dist}} {{$dist_version}} ({{$date}})

use Moose::Role;
#---------------------------------------------------------------------

=method remap_sections

If your class provides C<remap_sections>, it should return a hashref
keyed by section title.  The values should be arrayrefs of section
titles.  Each section in the hash will be replaced by the listed
sections.  You can use this to insert or remove sections from the
template you're extending.

=cut

around _build_sections => sub {
  my $orig = shift;
  my $self = shift;

  my $sections = $self->$orig(@_);

  my $remap = $self->can('remap_sections');

  if ($remap) {
    $remap = $self->$remap;

    $sections = [ map { $remap->{$_} ? @{$remap->{$_}} : $_ } @$sections ];
  } # end if remap

  $sections;
}; # end around _build_sections
#---------------------------------------------------------------------

=method additional_commands

If your class provides C<additional_commands>, it should return an
arrayref just like C<collect_commands>.  This list will be merged with
the list of C<collect_commands> from the template being extended.

=cut

around collect_commands => sub {
  my $orig = shift;
  my $self = shift;

  my $commands = $self->$orig(@_);

  if (my $additional = $self->can('additional_commands')) {
    my %command = map { $_ => undef } @$commands;

    $command{$_} = undef for @{ $self->$additional };

    $commands = [ keys %command ];
  } # end if additional_commands

  $commands;
}; # end around collect_commands

#=====================================================================
# Package Return Value:

1;

__END__

=head1 SYNOPSIS

  use Moose;
  extends 'Pod::Loom::Template::Default';
  with 'Pod::Loom::Role::Extender';

  sub remap_sections { {
    AUTHOR => [qw[ AUTHOR ACKNOWLEDGMENTS ]],
  } }

  sub section_ACKNOWLEDGMENTS ...

=head1 DESCRIPTION

The Extender role simplifies creating a custom Pod::Loom template.
You should not use this for templates uploaded to CPAN, because you
can only use it once per template.  It's intended for creating a
custom template for a distribution.

=head1 METHODS

Your template class may provide any or all of the following methods.
(If you don't provide any of these methods, then there's no point in
using Extender.)
