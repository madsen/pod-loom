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

{
  package Pod::Loom::_Logger;
  sub log { printf "%s\n", String::Flogger->flog($_[1]) }
  sub new { bless {} => shift }
}

has logger => (
  is      => 'ro',
  lazy    => 1,
  default => sub { Pod::Loom::_Logger->new },
  handles => [ qw(log) ]
);

has template => (
  is      => 'rw',
  isa     => 'Str',
  default => 'Default',
);

#=====================================================================
sub weave
{
  my ($self, $docRef, $filename, $dataHash) = @_;

  my $ppi = PPI::Document->new($docRef);

  my $sourcePod = join("\n", @{ $ppi->find('PPI::Token::Pod') || [] });

  $ppi->prune('PPI::Token::Pod');

  croak "can't use Pod::Loom on $filename: there is POD inside string literals"
      if $self->_has_pod_events("$ppi");

  # Determine the template to use:
  my $templateClass = $self->template;

  if ($sourcePod =~ /^=for \s+ Pod::Loom \s+ template \s+ (\S+)/mx) {
    $templateClass = $1;
  }

  $templateClass = String::RewritePrefix->rewrite(
    {'=' => q{},  q{} => 'Pod::Loom::Template::'},
    $templateClass
  );

  # Instantiate the template and let it weave the new POD:
  die "Invalid class name $templateClass"
      unless $templateClass =~ /^[:_A-Z0-9]+$/i;
  eval "require $templateClass;" or croak "Unable to load $templateClass: $@";

  my $template = $templateClass->new;

  my $newPod = $template->weave(\$sourcePod, $dataHash);
  $newPod =~ s/\s*\z/\n/;       # ensure it ends with LF

  # Plug the new POD back into the code:

  my $end = do {
    my $end_elem = $ppi->find('PPI::Statement::Data');

    unless ($end_elem) {
      $end_elem = $ppi->find('PPI::Statement::End');

      if (not $end_elem or (@$end_elem == 1 and
                            $end_elem->[0] =~ /^__END__\s*\z/)) {
        $end_elem = [];
      }
    } # end unless found __DATA__

    @$end_elem ? join q{}, @$end_elem : undef;
  };

  $ppi->prune('PPI::Statement::End');
  $ppi->prune('PPI::Statement::Data');

  my $docstr = $ppi->serialize;
  $docstr =~ s/\n*\z/\n/;       # ensure it ends with one LF

  return defined $end
      ? "$docstr\n$newPod\n=cut\n\n$end"
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

1;

__END__

=head1 SYNOPSIS

    use Pod::Loom;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.


=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.

Pod::Loom requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.


=head1 AUTHOR

Christopher J. Madsen  S<< C<< <perl AT cjmweb.net> >> >>

Please report any bugs or feature requests to
S<< C<< <bug-Pod-Loom AT rt.cpan.org> >> >>,
or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Pod-Loom>


=head1 LICENSE AND COPYRIGHT

Copyright 2009 Christopher J. Madsen

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

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