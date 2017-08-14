package GraphQL::Type::Object;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(HashRef ArrayRef);
extends qw(GraphQL::Type);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type::Object - Perl implementation of a GraphQL object type

=head1 SYNOPSIS

  use GraphQL::Type::Object;
  my $interfaceType;
  my $ImplementingType = GraphQL::Type::Object->new(
    name => 'Object',
    interfaces => [ $interfaceType ],
    fields => { fieldName => { type => 'GraphQLString', resolve => sub { '' } }},
  );

=head1 ATTRIBUTES

Inherits C<name>, C<description> from L<GraphQL::Type>.

=head2 fields

Hash-ref mapping fields to their types.

=cut

has fields => (is => 'ro', isa => HashRef, required => 1);

=head2 interfaces

Optional array-ref of interface type objects implemented.

=cut

has interfaces => (is => 'ro', isa => ArrayRef);

__PACKAGE__->meta->make_immutable();

1;
