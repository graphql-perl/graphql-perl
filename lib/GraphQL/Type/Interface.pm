package GraphQL::Type::Interface;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(HashRef CodeRef);
extends qw(GraphQL::Type::Named);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type::Interface - GraphQL interface type

=head1 SYNOPSIS

  use GraphQL::Type::Interface;
  my $ImplementingType;
  my $InterfaceType = GraphQL::Type::Interface->new(
    name => 'Interface',
    fields => { fieldName => { type => 'GraphQLString' } },
    resolveType => sub {
      return $ImplementingType;
    },
  );

=head1 ATTRIBUTES

Inherits C<name>, C<description> from L<GraphQL::Type::Named>.

=head2 fields

Hash-ref mapping fields to their types.

=cut

has 'fields' => (is => 'ro', isa => HashRef, required => 1);

=head2 resolveType

Optional code-ref to resolve types.

=cut

has 'resolveType' => (is => 'ro', isa => CodeRef);

__PACKAGE__->meta->make_immutable();

1;
