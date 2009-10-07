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

our $VERSION = '0.01';

use 5.008;
use strict;
use warnings;

use Pod::Eventual ();
our @ISA = qw(Pod::Eventual);

#---------------------------------------------------------------------
sub new
{
  my ($class, $collectCommands) = @_;

  my %collect = map { $_ => [] } @$collectCommands;

  bless {
    collect => \%collect,
    dest    => undef,
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
sub collected { shift->{collect} }

#=====================================================================
# Package Return Value:

1;

__END__
