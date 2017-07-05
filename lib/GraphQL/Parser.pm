package GraphQL::Parser;

use 5.014;
use strict;
use warnings;
use Moo;
use Return::Type;
use Types::Standard qw(Str Bool);
use Function::Parameters;

=head1 NAME

GraphQL::Parser - GraphQL language parser

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

  use GraphQL::Parser;
  my $parsed = GraphQL::Parser->parse(
    $source
  );

=head1 METHODS

=head2 parse

  GraphQL::Parser->parse($source, $noLocation);

=cut

method parse(Str $source, Bool $noLocation = undef) :ReturnType(Str) {
  return 'Yo';
}

__PACKAGE__->meta->make_immutable();

1;
