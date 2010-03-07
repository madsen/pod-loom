#---------------------------------------------------------------------
package Pod::Loom::Template::Identity;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created:  7 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Do-nothing template for Pod::Loom
#---------------------------------------------------------------------

use 5.008;
our $VERSION = '0.03';
# This file is part of {{$dist}} {{$dist_version}} ({{$date}})

use strict;
use warnings;

=for Pod::Loom-sort_method
new

=method new

  $template = Pod::Loom::Template::Identity->new($data);

A template must have a constructor named C<new> that takes one argument.
(In this case, we discard it.)

=cut

sub new
{
  bless {}, shift;
} # end new
#---------------------------------------------------------------------

=method weave

  $new_pod = $template->weave(\$old_pod, $filename);

A template must also have a C<weave> method that returns the new POD.
The Identity template simply returns the POD unchanged.

=cut

sub weave
{
  my ($self, $podRef, $filename) = @_;

  $$podRef;
} # end weave

#=====================================================================
# Package Return Value:

1;

__END__

=head1 DESCRIPTION

This is the simplest possible template for L<Pod::Loom>.  It does
absolutely nothing to the collected POD.  The result is simply to
collect all POD sections and move them to the end of the file.

It demonstrates that a Pod::Loom template does not have to be a
subclass of L<Pod::Loom::Template>, and doesn't even need to use L<Moose>.

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT
