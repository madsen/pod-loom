#---------------------------------------------------------------------
package Pod::Loom::Parser;
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
# ABSTRACT: Subclass Pod::Eventual for Pod::Loom
#---------------------------------------------------------------------

use 5.008;
our $VERSION = '0.03';
# This file is part of {{$dist}} {{$dist_version}} ({{$date}})

use strict;
use warnings;

use Pod::Eventual ();
our @ISA = qw(Pod::Eventual);
#---------------------------------------------------------------------

=head1 DEPENDENCIES

Pod::Loom::Parser requires L<Pod::Eventual>, which can be found on CPAN.

=for Pod::Loom-sort_method
new

=method new

  $parser = Pod::Loom::Parser->new(\@collect_commands);

Constructs a new Pod::Loom::Parser.  You pass it an arrayref of the
POD commands at which the POD should be chopped.

=cut

sub new
{
  my ($class, $collectCommands) = @_;

  my %collect = map { $_ => [] } @$collectCommands;
  my %groups  = map { $_ => {} } @$collectCommands;

  bless {
    collect => \%collect,
    dest    => undef,
    groups  => \%groups,
  }, $class;
} # end new

#---------------------------------------------------------------------
sub handle_event
{
  my ($self, $event) = @_;

  my $dest = $self->{dest};

  if ($event->{type} eq 'command') {
    my $cmd = $event->{command};
    return if $cmd eq 'cut';

    # See if this changes the output location:
    my $collector = $self->{collect}{ $cmd };

    if (not $collector and $cmd =~ /^(\w+)-(\S+)/ and $self->{collect}{$1}) {
      $collector = $self->{collect}{$cmd} = [];
      $self->{groups}{$1}{$2} = 1;
    } # end if new group

    # Special handling for Pod::Loom sections:
    if ($cmd =~ /^(begin|for)$/ and
        $event->{content} =~ s/^\s*(Pod::Loom\b\S*)\s*//) {
      $collector = ($self->{collect}{$1} ||= []);
      if ($cmd eq 'for') {
        push @$collector, $event->{content};
        return;
      }
      undef $cmd;
    } elsif ($cmd eq 'end' and
             $event->{content} =~ /^\s*Pod::Loom\b/) {
      # Handle =end Pod::Loom:
      $self->{dest} = undef;
      return;
    }

    # Either set output location, or make sure we have one:
    if ($collector) {
      push @$collector, '';
      $dest = $self->{dest} = \$collector->[-1];
    } else {
      die "=$cmd used too soon\n" unless $dest;
    }

    if ($cmd) {
      $$dest .= "=$cmd";
      $$dest .= ' ' unless $event->{content} =~ /^\n/;
    }
  } # end if command event

  $$dest .= $event->{content};
} # end handle_event

#---------------------------------------------------------------------
sub handle_blank
{
  my ($self, $event) = @_;

  if ($self->{dest}) {
    $event->{type} = 'text';
    $self->handle_event($event);
  }
} # end handle_event
#---------------------------------------------------------------------

=method collected

  $hashRef = $parser->collected;

This returns the POD chunks that the document was chopped into.  There
is one entry for each of the C<@collect_commands> that were passed to
the constructor.  The value is an arrayref of strings, one for each
time that command appeared in the document.  Each chunk contains all
the text from the command up to (but not including) the command that
started the next chunk.  Chunks appear in document order.

If one of the commands did not appear in the document, its value will
be an empty arrayref.

In addition, any POD targeted to a format matching C</^Pod::Loom\b/>
will be collected under the format name.

=cut

sub collected { shift->{collect} }
#---------------------------------------------------------------------

=method groups

  $hashRef = $parser->groups;

This returns a hashref with one entry for each of the
C<@collect_commands>.  Each value is a hashref whose keys are the
categories used with that command.  For example, if C<attr> was a
collected command, and the document contained these entries:

  =attr-foo attr1
  =attr-bar attr2
  =attr-foo attr3
  =attr attr4

then C<< keys %{ $parser->groups->{attr} } >> would return C<bar> and
C<foo>.  (The C<=attr> without a category does not get an entry in
this hash.)

=cut

sub groups { shift->{groups} }

#=====================================================================
# Package Return Value:

1;

__END__

=head1 SYNOPSIS

  use Pod::Loom::Parser;

  my $parser = Pod::Loom::Parser->new( ['head1'] );
  $parser->read_file('lib/Foo/Bar.pm');
  my $collectedHash = $parser->collected;

  foreach my $block (@{ $collectedHash->{head1} }) {
    printf "---\n%s\n", $block;
  }

=head1 DESCRIPTION

Pod::Loom::Parser is a subclass of L<Pod::Eventual> intended for use
by L<Pod::Loom::Template>.  It breaks the POD into chunks based on a
list of POD commands.  Each chunk begins with one of the commands, and
contains all the POD up until the next selected command.

The commands do not need to be valid POD commands.  You can invent
commands like C<=attr> or C<=method>.

=head1 METHODS

See L<Pod::Eventual> for the C<read_handle>, C<read_file>, and
C<read_string> methods, which you use to feed POD into the parser.
