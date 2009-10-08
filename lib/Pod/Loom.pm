#---------------------------------------------------------------------
package Pod::Loom;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: October 6, 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Weave pseudo-POD into real POD
#---------------------------------------------------------------------

our $VERSION = '0.01';

use 5.008;
use Moose;
use Carp qw(croak);
use PPI ();
use String::RewritePrefix ();

#=====================================================================
{
  package Pod::Loom::_EventCounter;
  our @ISA = 'Pod::Eventual';
  sub new {
    require Pod::Eventual;
    my $events = 0;
    bless \$events => shift;
  }

  sub handle_event { ++${$_[0]} }
  sub events { ${ +shift } }
}

#=====================================================================
# Package Pod::Loom:

has template => (
  is      => 'rw',
  isa     => 'Str',
  default => 'Default',
);
#=====================================================================

=method weave

    $new_doc = $loom->weave(\$doc, $filename, $data);

This method does all the work (see L</"DESCRIPTION">).  You pass it a
reference to a string containing Perl code mixed with POD.  (This
string is not modified.)  It returns a new string containing the
reformatted POD moved to the end of the code.

The C<$filename> is used for error messages.  It does not need to
actually exist on disk.

C<$data> is passed as the only argument to the template class's
constructor (which must be named C<new>).  Pod::Loom does not inspect
it, but for consistency and compatibility between templates it should
be a hashref.

=cut

sub weave
{
  my ($self, $docRef, $filename, $data) = @_;

  my $ppi = PPI::Document->new($docRef);

  my $sourcePod = join("\n", @{ $ppi->find('PPI::Token::Pod') || [] });

  $ppi->prune('PPI::Token::Pod');

  croak "Can't use Pod::Loom on $filename: there is POD inside string literals"
      if $self->_has_pod_events("$ppi");

=diag C<< Can't use Pod::Loom on %s: there is POD inside string literals >>

You have POD commands inside a string literal (probably a here doc).
Since Pod::Loom moves all POD to the end of the file, running it on
your program would change its behavior.  Move the POD outside the
string, or quote any equals sign at the beginning of a line so it no
longer looks like POD.

=cut

  # Determine the template to use:
  my $templateClass = $self->template;

  if ($sourcePod =~ /^=for \s+ Pod::Loom-template \s+ (\S+)/mx) {
    $templateClass = $1;
  }

  $templateClass = String::RewritePrefix->rewrite(
    {'=' => q{},  q{} => 'Pod::Loom::Template::'},
    $templateClass
  );

  # Instantiate the template and let it weave the new POD:
  croak "Invalid class name $templateClass"
      unless $templateClass =~ /^[:_A-Z0-9]+$/i;
  eval "require $templateClass;" or croak "Unable to load $templateClass: $@";

=diag C<< Invalid class name %s >>

A template name may only contain ASCII alphanumerics and underscore.

=diag C<< Unable to load %s: %s >>

Pod::Loom got an error when it tried to C<require> your template class.

=cut

  my $template = $templateClass->new($data);

  my $newPod = $template->weave(\$sourcePod, $filename);
  $newPod =~ s/(?:\s*\n=cut)*\s*\z/\n\n=cut\n/; # ensure it ends with =cut

  # Plug the new POD back into the code:

  my $end = do {
    my $end_elem = $ppi->find('PPI::Statement::Data');

    unless ($end_elem) {
      $end_elem = $ppi->find('PPI::Statement::End');

      # If there's nothing after __END__, we can put the POD there:
      if (not $end_elem or (@$end_elem == 1 and
                            $end_elem->[0] =~ /^__END__\s*\z/)) {
        $end_elem = [];
      } # end if no significant text after __END__
    } # end unless found __DATA__

    @$end_elem ? join q{}, @$end_elem : undef;
  };

  $ppi->prune('PPI::Statement::End');
  $ppi->prune('PPI::Statement::Data');

  my $docstr = $ppi->serialize;
  $docstr =~ s/\n*\z/\n/;       # ensure it ends with one LF

  return defined $end
      ? "$docstr\n$newPod\n$end"
      : "$docstr\n__END__\n\n$newPod";
} # end weave_document

#---------------------------------------------------------------------
sub _has_pod_events
{
  my $pe = Pod::Loom::_EventCounter->new;
  $pe->read_string($_[1]);

  $pe->events;
} # end _has_pod_events

#=====================================================================
# Package Return Value:

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=for Pod::Loom-insert_before
WARNING
SYNOPSIS

=head1 WARNING

This code is still in flux.  Use it at your own risk, and be prepared
to adapt to changes.

=head1 SYNOPSIS

  use Pod::Loom;

  my $document = ...; # Text of Perl program including POD
  my $filename = "filename/of/document.pm"; # For messages
  my %data = ...; # Configuration required by template

  my $loom = Pod::Loom->new(template => 'Custom');
  my $new_doc = $loom->weave(\$document, $filename, \%data);

=head1 DESCRIPTION

Pod::Loom extracts all the POD sections from Perl code, passes the POD
to a template that may reformat it in various ways, and then returns a
copy of the code with the reformatted POD at the end.

A template may convert non-standard POD commands like C<=method> and
C<=attr> into standard POD, reorder sections, and generally do
whatever it likes to the POD.

The document being reformatted can specify the template to use with a
line like this:

  =for Pod::Loom-template TEMPLATE_NAME

Otherwise, you can specify the template in the Pod::Loom constructor:

  $loom = Pod::Loom->new(template => TEMPLATE_NAME);

TEMPLATE_NAME is automatically prefixed with C<Pod::Loom::Template::>
to form a class name.  If you want to use a template outside that
namespace, prefix the class name with C<=> to indicate that.


=for Pod::Loom-sort_method
new

=method new

  $loom = Pod::Loom->new(template => TEMPLATE_NAME);

Constructs a new Pod::Loom.  The C<template> parameter is optional; it
defaults to C<Default> (meaning L<Pod::Loom::Template::Default>).


=head1 REQUIREMENTS OF A TEMPLATE CLASS

A template class must have a constructor named C<new> and a method
named C<weave> that matches the one in L<Pod::Loom::Template>.  It
should be in the C<Pod::Loom::Template::> namespace (to make it easy
to specify the template name), but it does not need to be a subclass
of Pod::Loom::Template.


=head1 DIAGNOSTICS

Pod::Loom may generate the following error messages, in addition to
whatever errors the template class generates.


=head1 DEPENDENCIES

Pod::Loom depends on L<Moose>, L<Pod::Eventual>, L<PPI>, and
L<String::RewritePrefix>, which can be found on CPAN.  The template
class may have additional dependencies.
