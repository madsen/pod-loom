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

use Pod::Loom::Template '%E';

#=====================================================================
has qw(sort_attr   is ro), isa => 'Int | ArrayRef[Str]';
has qw(sort_diag   is ro), isa => 'Int | ArrayRef[Str]';
has qw(sort_method is ro), isa => 'Int | ArrayRef[Str]';

sub collect_commands
{
  [ qw(head1 attr method diag) ];
} # end collect_commands

#---------------------------------------------------------------------
our @sections =
  (qw(NAME VERSION SYNOPSIS DESCRIPTION ATTRIBUTES METHODS * DIAGNOSTICS),
   'CONFIGURATION AND ENVIRONMENT',
   qw(DEPENDENCIES INCOMPATIBILITIES),
   'BUGS AND LIMITATIONS',
   'AUTHOR', 'COPYRIGHT AND LICENSE', 'DISCLAIMER OF WARRANTY');

has qw(+sections default) => sub { \@sections };

#---------------------------------------------------------------------
has qw(abstract is ro  isa Str);
has qw(module   is ro  isa Str);

sub section_NAME
{
  my ($self, $title) = @_;

  my ($module, $abstract) = $self->required_attr($title, qw(module abstract));

  "=head1 $title\n\n$module - $abstract\n";
} # end section_NAME

#---------------------------------------------------------------------
has qw(version      is ro  isa Str);
has qw(version_desc is ro  isa Str);

sub section_VERSION
{
  my ($self, $title) = @_;

  if ($self->version_desc) {
    return "=head1 $title\n\n$E{$self->version_desc}\n";
  }

  my $version = $self->version;

  return "=head1 $title\n\nversion $version\n" if defined $version;

  '';                           # Otherwise, omit VERSION
} # end section_VERSION

#---------------------------------------------------------------------
sub section_ATTRIBUTES
{
  my $self = shift;

  $self->joined_section(attr => @_);
} # end section_ATTRIBUTES

#---------------------------------------------------------------------
sub section_METHODS
{
  my $self = shift;

  $self->joined_section(method => @_);
} # end section_METHODS

#---------------------------------------------------------------------
sub override_section
{
  my ($self, $title) = @_;

  return ($title eq 'ATTRIBUTES' or
          $title eq 'DIAGNOSTICS' or
          $title eq 'METHODS');
} # end override_section

#---------------------------------------------------------------------
sub joined_section
{
  my ($self, $cmd, $title, $pod) = @_;

  my $entries = $self->tmp_collected->{$cmd};

  return ($pod || '') unless $entries and @$entries;

  $pod = "=head1 $title\n" unless $pod;

  foreach (@$entries) {
    s/^=\w+/=head2/ or die "Bad entry $_";
    $pod .= "\n$_";
  } # end foreach

  return $pod;
} # end joined_section

#---------------------------------------------------------------------
sub section_DIAGNOSTICS
{
  my ($self, $title, $pod) = @_;

  my $entries = $self->tmp_collected->{diag};

  return ($pod || '') unless $entries and @$entries;

  $pod = "=head1 $title\n" unless $pod;

  $pod .= "\n=over\n";

  foreach (@$entries) {
    s/^=\w+/=item/ or die "Bad entry $_";
    $pod .= "\n$_";
  } # end foreach

  return $pod . "\n=back\n";
} # end joined_section

#---------------------------------------------------------------------
sub section_CONFIGURATION_AND_ENVIRONMENT
{
  my ($self, $title) = @_;

  my ($module) = $self->required_attr($title, 'module');

  return <<"END CONFIGURATION";
\=head1 $title

$module requires no configuration files or environment variables.
END CONFIGURATION
} # end section_CONFIGURATION_AND_ENVIRONMENT

#---------------------------------------------------------------------
sub section_INCOMPATIBILITIES
{
  my ($self, $title) = @_;

  "=head1 $title\n\nNone reported.\n";
} # end section_INCOMPATIBILITIES

#---------------------------------------------------------------------
sub section_BUGS_AND_LIMITATIONS
{
  my ($self, $title) = @_;

  "=head1 $title\n\nNo bugs have been reported.\n";
} # end section_BUGS_AND_LIMITATIONS

#---------------------------------------------------------------------
has qw(dist    is ro  isa Str);
has qw(authors is ro  isa ArrayRef[Str]);

sub section_AUTHOR
{
  my ($self, $title) = @_;

  my ($dist, $authors) = $self->required_attr($title, qw(dist authors));

  my $pod = "=head1 $title\n\n";

  foreach my $authorCredit (@$authors) {
    if ($authorCredit =~ /(.*\S)\s*(<.*>)$/) {
      my ($author, $email) = ($1, $2);
      $email =~ s/@/ AT /g;
      $pod .= "$author  S<< C<< <$email> >> >>\n";
    } else {
      $pod .= "$authorCredit\n";
    }
  } # end foreach $authorCredit in @$authors

  return $pod . <<"END AUTHOR";

Please report any bugs or feature requests to
S<< C<< <bug-$dist AT rt.cpan.org> >> >>,
or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=$dist>
END AUTHOR
} # end section_AUTHOR

#---------------------------------------------------------------------
has qw(license_notice is ro  isa Str);

sub section_COPYRIGHT_AND_LICENSE
{
  my ($self, $title) = @_;

  my ($notice) = $self->required_attr($title, 'license_notice');

  #FIXME other license
  "=head1 $title\n\n$notice";
} # end section_COPYRIGHT_AND_LICENSE

#---------------------------------------------------------------------
sub section_DISCLAIMER_OF_WARRANTY
{
  my ($self, $title) = @_;

  return <<"END DISCLAIMER";
\=head1 $title

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
END DISCLAIMER
} # end section_DISCLAIMER_OF_WARRANTY

#=====================================================================
# Package Return Value:

no Moose;
__PACKAGE__->meta->make_immutable;
1;
