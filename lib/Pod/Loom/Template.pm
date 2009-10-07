#---------------------------------------------------------------------
package Pod::Loom::Template;
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
# ABSTRACT: Standard base class for Pod::Loom templates
#---------------------------------------------------------------------

our $VERSION = '0.01';

use 5.008;
use Moose;

use Pod::Loom::Parser ();

#---------------------------------------------------------------------
# These methods are likely to be overloaded in subclasses:

sub collect_commands { [] }
sub override_section { 0 }
#sub sections        { return } # A subclass must provide this

#---------------------------------------------------------------------
sub required_param
{
  my $self     = shift;
  my $dataHash = shift;

  map { my $v = $dataHash->{$_};
        defined $v ? $v : die "Required parameter $_ was not found"
      } @_;
} # end required_param

#---------------------------------------------------------------------
sub weave
{
  my ($self, $podRef, $dataHash) = @_;

  my $collected = do {
    my $pe = Pod::Loom::Parser->new( $self->collect_commands );
    $pe->read_string($$podRef);
    $pe->collected;
  };

  # Split out the expected sections:
  my @expectSections = $self->sections;

  my %expectedSection = map { $_ => 1 } @expectSections;

  my $heads = $collected->{head1};
  my %section;

  foreach my $h (@$heads) {
    $h =~ /^=head1\s+(.+?)(?=\n*\z|\n\n)/ or die "Can't find heading in $h";
    my $title = $1;

    if ($expectedSection{$title}) {
      warn "Duplicate section $title" if $section{$title};
      $section{$title} .= $h;
    } else {
      $section{'*'} .= $h;
    }
  } # end foreach $h in @$heads

  # Now build the new POD:
  my $pod = '';

  foreach my $title (@expectSections) {
    if ($section{$title} and not $self->override_section($title)) {
      $pod .= $section{$title};
      next;
    } # end if document supplied section and we don't override it

    my $method = $self->method_for_section($title);

    $pod .= $self->$method($dataHash, $collected, $title, $section{$title})
        if $method;

    $pod =~ s/\n*\z/\n\n/ if $pod;
  } # end foreach $title in @expectSections

  $pod;
} # end weave

#---------------------------------------------------------------------
sub method_for_section
{
  my ($self, $title) = @_;

  my $method = "section_$title";
  if ($title eq '*') { $method = "other_sections" }
  else {
    $method =~ s/[^A-Z0-9_]/_/gi;
  }

  $self->can($method);
} # end method_for_section

#=====================================================================
# Package Return Value:

1;

