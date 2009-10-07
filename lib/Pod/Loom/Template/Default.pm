#---------------------------------------------------------------------
package Pod::Loom::Template::Default;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created:  6 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Default template for Pod::Loom
#---------------------------------------------------------------------

our $VERSION = '0.01';

use 5.008;
use Moose;
extends 'Pod::Loom::Template';

#=====================================================================
sub collect_commands
{
  [ qw(head1 method attr) ];
} # end collect_commands

#---------------------------------------------------------------------
sub sections
{
  (qw(NAME SYNOPSIS DESCRIPTION INTERFACE * DIAGNOSTICS),
   'CONFIGURATION AND ENVIRONMENT',
   qw(DEPENDENCIES INCOMPATIBILITIES),
   'BUGS AND LIMITATIONS',
   'AUTHOR', 'LICENSE AND COPYRIGHT', 'DISCLAIMER OF WARRANTY');
} # end sections

#---------------------------------------------------------------------
sub section_NAME
{
  my ($self, $dataHash) = @_;

  my ($module, $abstract) = $self->required_param($dataHash,
                                                  qw(module abstract));

  return <<"END NAME";
=head1 NAME

$module - $abstract
END NAME
} # end head1_NAME

#=====================================================================
# Package Return Value:

1;
