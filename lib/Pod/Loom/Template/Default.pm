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
\=head1 NAME

$module - $abstract
END NAME
} # end section_NAME

#---------------------------------------------------------------------
sub section_CONFIGURATION_AND_ENVIRONMENT
{
  my ($self, $dataHash) = @_;

  my ($module) = $self->required_param($dataHash, 'module');

  return <<"END CONFIGURATION";
\=head1 CONFIGURATION AND ENVIRONMENT

$module requires no configuration files or environment variables.
END CONFIGURATION
} # end section_CONFIGURATION_AND_ENVIRONMENT

#---------------------------------------------------------------------
sub section_INCOMPATIBILITIES
{
  "=head1 INCOMPATIBILITIES\n\nNone reported.\n";
} # end section_INCOMPATIBILITIES

#---------------------------------------------------------------------
sub section_BUGS_AND_LIMITATIONS
{
  "=head1 BUGS AND LIMITATIONS\n\nNo bugs have been reported.\n";
} # end section_BUGS_AND_LIMITATIONS

#---------------------------------------------------------------------
sub section_AUTHOR
{
  my ($self, $dataHash) = @_;

  my ($dist, $authors) = $self->required_param($dataHash,
                                               qw(dist authors));

  my $pod = "=head1 AUTHOR\n\n";

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
sub section_LICENSE_AND_COPYRIGHT
{
  my ($self, $dataHash) = @_;

  my ($notice) = $self->required_param($dataHash, 'license_notice');

  #FIXME other license
  "=head1 LICENSE AND COPYRIGHT\n\n$notice";
} # end section_LICENSE_AND_COPYRIGHT

#---------------------------------------------------------------------
sub section_DISCLAIMER_OF_WARRANTY
{
  return <<"END DISCLAIMER";
\=head1 DISCLAIMER OF WARRANTY

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

1;
