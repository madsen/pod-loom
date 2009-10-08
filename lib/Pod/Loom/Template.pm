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
defined by subclasses.  In addition, attributes beginning with
C<sort_> are reserved for indicating whether collected entries should
be sorted.

=attr tmp_collected

This is a hashref of arrayrefs.  The keys are the POD commands
returned by L</"collect_commands">, plus any format names that begin
with C<Pod::Loom>.  Each value is an arrayref of POD blocks.
It is filled in by the L</"weave"> method.

=attr tmp_filename

This is the name of the file being processed.  This is only for
informational purposes; it need not represent an actual file on disk.
(The L</"weave"> method stores the filename here.)

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

=method collect_commands

  $arrayRef = $tmp->collect_commands;

This method should be overriden in subclasses to indicate what POD
commands should be collected for the template to stitch together.
This should include C<head1>, or the template is unlikely to work
properly.  The default method indicates only C<head1> is collected.

=method override_section

  $boolean = $tmp->override_section($section_title);

Normally, if a section appears in the document, it remains unchanged
by the template.  However, a template may want to rewrite certain
sections.  C<override_section> is called when the specified section is
present in the document.  If it returnes true, then the normal
C<section_TITLE> method will be called.  (If it returns true but the
C<section_TITLE> method doesn't exist, the section will be dropped.)

=attr sections

Subclasses must provide a default value for this attribute.  It is an
arrayref of section titles in the order they should appear.  The
special title C<*> indicates where sections that appear in the
document but are not in this list will be placed.  (If C<*> is not in
this list, such sections will be dropped.)

The list can include sections that the template does not provide.  In
that case, it simply indicates where the section should be placed if
the document provides it.

=cut

sub collect_commands { [ 'head1' ] }
sub override_section { 0 }

has sections => (
  is       => 'ro',
  isa      => 'ArrayRef[Str]',
  required => 1,
);

#---------------------------------------------------------------------

=method expect_sections

  @section_titles = $tmp->expect_sections;

This method returns the section titles in the order they should
appear.  By default, this is the list from L</"sections">, but it can
be overriden by the document:

If the document contains C<=for Pod::Loom-sections>, the sections
listed there (one per line) replace the template's normal section
list.

If the document contains C<=for Pod::Loom-omit>, the sections listed
there will not appear in the final document.  (Unless they appeared in
the document, in which case they will be with the other C<*>
sections.)

If the document contains C<=for Pod::Loom-insert_before>, the sections
listed there will be inserted before the last section in the list
(which must already be in the section list).  If the sections were
already in the list, they are moved to the new location.

If the document contains C<=for Pod::Loom-insert_after>, the sections
listed there will be inserted after the first section in the list.

=cut

sub expect_sections
{
  my ($self) = @_;

  my $collected = $self->tmp_collected;

  my @sections;

  foreach my $block (@{ $collected->{'Pod::Loom-sections'} || [] }) {
    push @sections, split /\s*\n/, $block;
  } # end foreach $block

  @sections = @{ $self->sections } unless @sections;

  $self->_insert_sections(\@sections, before => -1);
  $self->_insert_sections(\@sections, after  =>  0);

  my %omit;

  foreach my $block (@{ $collected->{'Pod::Loom-omit'} || [] }) {
    $omit{$_} = 1 for split /\s*\n/, $block;
  } # end foreach $block

  return grep { not $omit{$_} } @sections;
} # end expect_sections

#---------------------------------------------------------------------
# Insert sections before or after other sections:

sub _insert_sections
{
  my ($self, $sectionsList, $type, $index) = @_;

  my $blocks = $self->tmp_collected->{"Pod::Loom-insert_$type"}
      or return;

  my @empty;

  foreach my $block (@$blocks) {
    my @list = split /\s*\n/, $block;

    next unless @list;

    die "Can't insert $type nonexistent section $list[$index]"
        unless grep { $_ eq $list[$index] } @$sectionsList;

=diag C<< Can't insert before/after nonexistent section %s >>

(F) You can't insert sections near a section title that isn't already in
the list of sections.  Make sure you spelled it right.

=cut

    # We remove each section listed:
    my %remap = map { $_ => \@empty } @list;

    # Except the one at $index, where we insert the entire list:
    $remap{ $list[$index] } = \@list;

    @$sectionsList = map { $remap{$_} ? @{$remap{$_}} : $_ } @$sectionsList;
  } # end foreach $block

} # end _insert_sections
#---------------------------------------------------------------------

=method required_attr

  @values = $tmp->required_attr($section_title, @attribute_names);

Returns the value of each attribute specified in C<@attribute_names>.
If any attribute is C<undef>, dies with a message that
C<$section_title> requires that attribute.

=diag C<< The %s section requires you to set `%s' >>

(F) The specified section of the template requires an attribute that
you did not set.

=cut

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
# Sort each arrayref in tmp_collected (if appropriate):

sub _sort_collected
{
  my $self = shift;

  my $collected = $self->tmp_collected;

  foreach my $type (@{ $self->collect_commands }) {
    # Is this type of entry sorted at all?
    my $sort = $self->_find_sort_order($type) or next;

    # Begin Schwartzian transform (entry_name => entry):
    #   We convert the keys to lower case to make it case insensitive.
    my @sortable = map { /^=\w+ \s+ (\S (?:.*\S)? )/x
                             ? [ lc $1 => $_ ]
                             : [ '' => $_ ] # Should this even be allowed?
                       } @{ $collected->{$type} };

    # Set up %special to handle any top-of-the-list entries:
    my $count = 1;
    my %special;
    %special = map { lc $_ => $count++ } @$sort if ref $sort;

    # Sort specials first, then the rest ASCIIbetically:
    my @sorted =
        map { $_->[1] }         # finish the Schwartzian transform
        sort { ($special{$a->[0]} || $count) <=> ($special{$b->[0]} || $count)
               or $a->[0] cmp $b->[0]   # if the keys match
               or $a->[1] cmp $b->[1] } # compare the whole entry
        @sortable;

    $collected->{$type} = \@sorted;
  } # end foreach $type of $collected entry
} # end _sort_collected

#---------------------------------------------------------------------
# Determine whether a collected command should be sorted:
#
# Returns false if they should remain in document order
# Returns true if they should be sorted
#
# If the return value is a reference, it is an arrayref of entry names
# that should appear (in order) before any other entries.

sub _find_sort_order
{
  my ($self, $type) = @_;

  # First, see if the document specifies the sort order:
  my $blocks = $self->tmp_collected->{"Pod::Loom-sort_$type"};

  if ($blocks) {
    my @sortFirst;
    foreach my $block (@$blocks) {
      push @sortFirst, split /\s*\n/, $block;
    } # end foreach $block

    return \@sortFirst;
  } # end if document specifies sort order

  # The document said nothing, so ask the template:
  my $method = $self->can("sort_$type") or return;

  $self->$method;
} # end _find_sort_order
#---------------------------------------------------------------------

=method weave

  $new_pod = $tmp->weave(\$old_pod, $filename);

This is the primary entry point, normally called by Pod::Loom's
C<weave> method.  It splits the POD as defined by C<collect_commands>,
then reassembles it.

=diag C<< Can't find heading in %s >>

(F) Pod::Loom couldn't determine the section title for the specified
section.  Is it formatted properly?

=cut

sub weave
{
  my ($self, $podRef, $filename) = @_;

  $self->tmp_filename($filename);

  {
    my $pe = Pod::Loom::Parser->new( $self->collect_commands );
    $pe->read_string($$podRef);
    $self->tmp_collected( $pe->collected );
  }

  $self->_sort_collected;

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
    } # end if document supplied section and we don't override it
    else {
      my $method = $self->method_for_section($title);

      $pod .= $self->$method($title, $section{$title})
          if $method;
    } # end else let method generate section

    $pod =~ s/\n*\z/\n\n/ if $pod;
  } # end foreach $title in @expectSections

  $pod;
} # end weave
#---------------------------------------------------------------------

=method method_for_section

  $methodRef = $tmp->method_for_section($section_title);

This associates a section title with the template method that
implements it.  By default, it prepends C<section_> to the title, and
then converts any non-alphanumeric characters to underscores.

The special C<*> section is associated with the method C<other_sections>.

=cut

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

=head1 DIAGNOSTICS

The following errors are classified like Perl's built-in diagnostics
(L<perldiag>):

     (S) A severe warning
     (F) A fatal error (trappable)
