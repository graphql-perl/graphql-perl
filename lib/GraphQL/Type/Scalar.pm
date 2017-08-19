package GraphQL::Type::Scalar;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(HashRef CodeRef);
extends qw(GraphQL::Type);
with qw(
  GraphQL::Role::Input
  GraphQL::Role::Output
  GraphQL::Role::Leaf
  GraphQL::Role::Nullable
  GraphQL::Role::Named
);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type::Scalar - GraphQL scalar type

=head1 SYNOPSIS

  use GraphQL::Type::Scalar;
  my $int_type = GraphQL::Type::Scalar->new(
    name => 'Int',
    description => 
      'The `Int` scalar type represents non-fractional signed whole numeric ' .
      'values. Int can represent values between -(2^31) and 2^31 - 1. ',
    serialize => \&coerce_int,
    parse_value => \&coerce_int,
    parse_literal => \&parse_literal,
  );

=head1 ATTRIBUTES

Has C<name>, C<description> from L<GraphQL::Role::Named>.

=head2 serialize

Code-ref. Should throw an exception if not passed a Perl object of the
relevant type. Returns that object turned into JSON.

=cut

has serialize => (is => 'ro', isa => CodeRef, required => 1);

=head2 parse_value

Code-ref. Required if is for an input type. Coerces a Perl entity into
one of the required type, or throws an exception.

=cut

has parse_value => (is => 'ro', isa => CodeRef);

# TODO does not take AST node yet

=head2 parse_literal

Code-ref. Required if is for an input type. Coerces an AST node into
a Perl entity of the required type, or throws an exception.

=cut

has parse_literal => (is => 'ro', isa => CodeRef);

__PACKAGE__->meta->make_immutable();

1;
