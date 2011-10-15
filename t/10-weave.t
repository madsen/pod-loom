#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2011 Christopher J. Madsen
#
# Test Pod::Loom
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.008;
use utf8;

use Test::More 0.88;            # want done_testing

# Load Test::Differences, if available:
BEGIN {
  if (eval "use Test::Differences; 1") {
    # Not all versions of Test::Differences support changing the style:
    eval { Test::Differences::unified_diff() }
  } else {
    eval '*eq_or_diff = \&is;'; # Just use "is" instead
  }
} # end BEGIN

use Encode qw(find_encoding);
use Pod::Loom;

#=====================================================================
my $generateResults;

if (@ARGV and $ARGV[0] eq 'gen') {
  # Just output the actual results, so they can be diffed against this file
  $generateResults = 1;
  open(OUT, '>:utf8', '/tmp/10-weave.t') or die $!;
  printf OUT "#%s\n\n__DATA__\n", '=' x 69;
} else {
  plan tests => 7 * 2;
}

binmode DATA, ':utf8';

while (<DATA>) {
  print OUT $_ if $generateResults;

  next if /^#[^#]/ or not /\S/;

  /^##\s*(.+)/ or die "Expected test name, got $_";
  my $name = $1;

  # Read the constructor parameters:
  my $param = '';
  while (<DATA>) {
    print OUT $_ if $generateResults;
    last if $_ eq "<<'---SOURCE---';\n";
    $param .= $_;
  } # end while <DATA>

  die "Expected <<'---SOURCE---';" unless defined $_;

  # Read the source text:
  my $source = '';
  while (<DATA>) {
    print OUT $_ if $generateResults;
    last if $_ eq "---SOURCE---\n";
    $source .= $_;
  }

  die "Expected ---SOURCE---" unless defined $_;
  $_ = <DATA>;
  die "Expected <<'---EXPECTED---';" unless $_ eq "<<'---EXPECTED---';\n";

  # Read the expected results:
  my $expected = '';
  while (<DATA>) {
    last if $_ eq "---EXPECTED---\n";
    $expected .= $_;
  }

  die "Expected ---EXPECTED---" unless defined $_;

  # Run the test:
  my $hash = eval $param;
  die $@ unless ref $hash;

  my $enc = find_encoding(delete $hash->{-encoding} || 'iso-8859-1')
      or die "$name encoding not found";

  $source = $enc->encode($source);

  my $template = delete $hash->{-template} || 'Default';

  my $loom = Pod::Loom->new(template => $template);

  isa_ok($loom, 'Pod::Loom', $name) unless $generateResults;

  my $got = $enc->decode( $loom->weave(\$source, $name, $hash) );

  $got =~ s/([ \t]*\n)+//;
  $got =~ s/\s+\z/\n/;

  # Either print the actual results, or compare to expected results:
  if ($generateResults) {
    print OUT "<<'---EXPECTED---';\n$got---EXPECTED---\n";
  } else {
    eq_or_diff($got, $expected, "$name output");
  }
} # end while <DATA>

done_testing unless $generateResults;

#=====================================================================

__DATA__

## identity
{
  '-template' => 'Identity',
}
<<'---SOURCE---';
---SOURCE---
<<'---EXPECTED---';
__END__
---EXPECTED---

## simplest default
{
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ['E. Xavier Ample <example@example.org>'],
  license_notice => 'No license.',
}
<<'---SOURCE---';
---SOURCE---
<<'---EXPECTED---';
__END__

=head1 NAME

Foo::Bar - boring description

=head1 CONFIGURATION AND ENVIRONMENT

Foo::Bar requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests to
S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>,
or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar>

=head1 COPYRIGHT AND LICENSE

No license.

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

=cut
---EXPECTED---

## omit lots
{
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ['E. Xavier Ample <example@example.org>'],
}
<<'---SOURCE---';
=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
---SOURCE---
<<'---EXPECTED---';
__END__

=head1 NAME

Foo::Bar - boring description

=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests to
S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>,
or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar>

=cut
---EXPECTED---

## with synopsis
{
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ['E. Xavier Ample <example@example.org>'],
}
<<'---SOURCE---';
=head1 SYNOPSIS

  use Foo::Bar;

=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
---SOURCE---
<<'---EXPECTED---';
__END__

=head1 NAME

Foo::Bar - boring description

=head1 SYNOPSIS

  use Foo::Bar;

=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests to
S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>,
or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar>

=cut
---EXPECTED---

## with Latin-1
{
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ["E. X\xE4vier \xC2mple <example\@example.org>"],
}
<<'---SOURCE---';
=head1 SYNOPSIS

  use Foo::Bar;

=head1 DESCRIPTION

This is ä déscription.

=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
---SOURCE---
<<'---EXPECTED---';
__END__

=head1 NAME

Foo::Bar - boring description

=head1 SYNOPSIS

  use Foo::Bar;

=head1 DESCRIPTION

This is ä déscription.

=head1 AUTHOR

E. Xävier Âmple  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests to
S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>,
or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar>

=cut
---EXPECTED---

## with =encoding Latin-1
{
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ["E. X\xE4vier \xC2mple <example\@example.org>"],
}
<<'---SOURCE---';
=encoding Latin-1

=head1 SYNOPSIS

  use Foo::Bar;

=head1 DESCRIPTION

This is ä déscription.

=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
---SOURCE---
<<'---EXPECTED---';
__END__

=head1 NAME

Foo::Bar - boring description

=head1 SYNOPSIS

  use Foo::Bar;

=head1 DESCRIPTION

This is ä déscription.

=head1 AUTHOR

E. Xävier Âmple  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests to
S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>,
or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar>

=cut
---EXPECTED---

## with encoding utf8
{
  '-encoding'    => 'utf8',
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ["E. X\xE4vier \xC2mple <example\@example.org>"],
}
<<'---SOURCE---';
=encoding utf8

=head1 DESCRIPTION

This is ä déscription.

=head1 SYNOPSIS

  use Foo::Bar;

=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
---SOURCE---
<<'---EXPECTED---';
__END__

=encoding utf8

=head1 NAME

Foo::Bar - boring description

=head1 SYNOPSIS

  use Foo::Bar;

=head1 DESCRIPTION

This is ä déscription.

=head1 AUTHOR

E. Xävier Âmple  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests to
S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>,
or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar>

=cut
---EXPECTED---

# Local Variables:
# compile-command: "perl 10-weave.t gen"
# End:
