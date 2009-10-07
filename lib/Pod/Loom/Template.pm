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

=head1 ATTRIBUTES

All attributes beginning with C<tmp_> are reserved and must not be
defined by subclasses.

=attr tmp_collected

This is a hashref of arrayrefs.  The keys are the POD commands
returned by L</"collect_commands">, plus any format names that begin
with C<Pod::Loom>.

=attr tmp_filename

This is the name of the file being processed.  This is only for
informational purposes; it need not represent an actual file on disk.

=cut

has tmp_collected => (
  is       => 'rw',
  isa      => 'HashRef',
);

has tmp_filename => (
  is       => 'rw',
  isa      => 'Str',
);

#---------------------------------------------------------------------
# Tied hashes for interpolating function calls into strings:

{ package Pod::Loom::_Interpolation;

  sub TIEHASH { bless $_[1], $_[0] }
  sub FETCH   { $_[0]->($_[1]) }
} # end Pod::Loom::_Interpolation

our %E;
tie %E, 'Pod::Loom::_Interpolation', sub { $_[0] }; # eval

use Exporter 'import';
our @EXPORT_OK = qw(%E);

#---------------------------------------------------------------------
# These methods are likely to be overloaded in subclasses:

sub collect_commands { [ 'head1' ] }
sub override_section { 0 }
#sub sections        { return } # A subclass must provide this

#---------------------------------------------------------------------
sub expect_sections
{
  my ($self) = @_;

  my $dataList = $self->tmp_collected->{'Pod::Loom'};

  my @sections;

  foreach my $block (@$dataList) {
    if ($block =~ /^\s*sections\s+(\S.*)/s) {
      push @sections, split '\n', $1;
    }
  } # end foreach $block

  @sections = $self->sections unless @sections;

  my %omit;

  foreach my $block (@$dataList) {
    if ($block =~ /^\s*omit\s+(\S.*)/s) {
      $omit{$_} = 1 for split '\n', $1;
    }
  } # end foreach $block

  return grep { not $omit{$_} } @sections;
} # end expect_sections

#---------------------------------------------------------------------
sub required_attr
{
  my $self     = shift;
  my $section  = shift;

  map {
    my $v = $self->$_;
    defined $v
        ? $v
        : die "The $section section requires you to set `$_'\n"
  } @_;
} # end required_attr

#---------------------------------------------------------------------
sub weave
{
  my ($self, $podRef, $filename) = @_;

  $self->tmp_filename($filename);

  {
    my $pe = Pod::Loom::Parser->new( $self->collect_commands );
    $pe->read_string($$podRef);
    $self->tmp_collected( $pe->collected );
  }

  # Split out the expected sections:
  my @expectSections = $self->expect_sections;

  my %expectedSection = map { $_ => 1 } @expectSections;

  my $heads = $self->tmp_collected->{head1};
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

    $pod .= $self->$method($title, $section{$title})
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

no Moose;
__PACKAGE__->meta->make_immutable;
1;

