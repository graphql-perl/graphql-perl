package GraphQL::Type::Union;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(ArrayRef CodeRef InstanceOf);
extends qw(GraphQL::Type);
with qw(
  GraphQL::Role::Output
  GraphQL::Role::Composite
  GraphQL::Role::Abstract
  GraphQL::Role::Nullable
  GraphQL::Role::Named
);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type::Union - GraphQL union type

=head1 SYNOPSIS

  use GraphQL::Type::Union;
  my $union_type = GraphQL::Type::Union->new(
    name => 'Union',
    types => [ $type1, $type2 ],
    resolve_type => sub {
      return $type1 if ref $_[0] eq 'Type1';
      return $type2 if ref $_[0] eq 'Type2';
    },
  );

=head1 ATTRIBUTES

Inherits C<name>, C<description> from L<GraphQL::Type>.

=head2 types

Array-ref of L<GraphQL::Type::Object> objects.

=cut

has types => (is => 'ro', isa => ArrayRef[InstanceOf['GraphQL::Type::Object']], required => 1);

=head2 resolve_type

Optional code-ref. Input is a value, returns a GraphQL type object for
it. If not given, relies on its possible type objects having a provided
C<is_type_of>.

=cut

has resolve_type => (is => 'ro', isa => CodeRef);

__PACKAGE__->meta->make_immutable();

1;
