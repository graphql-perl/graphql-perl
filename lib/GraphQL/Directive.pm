package GraphQL::Directive;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(ArrayRef InstanceOf Enum);
extends qw(GraphQL::Type);

our $VERSION = '0.02';

my @LOCATIONS = qw(
  QUERY
  MUTATION
  SUBSCRIPTION
  FIELD
  FRAGMENT_DEFINITION
  FRAGMENT_SPREAD
  INLINE_FRAGMENT
  SCHEMA
  SCALAR
  OBJECT
  FIELD_DEFINITION
  ARGUMENT_DEFINITION
  INTERFACE
  UNION
  ENUM
  ENUM_VALUE
  INPUT_OBJECT
  INPUT_FIELD_DEFINITION
);

=head1 NAME

GraphQL::Directive - GraphQL directive

=head1 SYNOPSIS

  use GraphQL::Directive;
  my $directive = GraphQL::Directive->new(
    name => 'Object',
    interfaces => [ $interfaceType ],
    fields => { fieldName => { type => 'GraphQLString', resolve => sub { '' } }},
  );

=head1 ATTRIBUTES

Inherits C<name>, C<description> from L<GraphQL::Type>.

=head2 locations

Array-ref of locations where the directive can occur. Must be one of
these strings:

  QUERY
  MUTATION
  SUBSCRIPTION
  FIELD
  FRAGMENT_DEFINITION
  FRAGMENT_SPREAD
  INLINE_FRAGMENT
  SCHEMA
  SCALAR
  OBJECT
  FIELD_DEFINITION
  ARGUMENT_DEFINITION
  INTERFACE
  UNION
  ENUM
  ENUM_VALUE
  INPUT_OBJECT
  INPUT_FIELD_DEFINITION

=cut

has locations => (is => 'ro', isa => ArrayRef[Enum[@LOCATIONS]], required => 1);

=head2 args

Array-ref of arguments.

=cut

has args => (is => 'ro', isa => ArrayRef[InstanceOf['GraphQL::Argument']], required => 1);

__PACKAGE__->meta->make_immutable();

1;
