package GraphQL::Type::InputObject;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(ArrayRef InstanceOf);
use GraphQL::Utilities qw(FieldMapInput);
extends qw(GraphQL::Type);
with qw(
  GraphQL::Role::Input
  GraphQL::Role::Nullable
  GraphQL::Role::Named
);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type::InputObject - GraphQL input object type

=head1 SYNOPSIS

  use GraphQL::Type::InputObject;
  my $type = GraphQL::Type::InputObject->new(
    name => 'InputObject',
    fields => { fieldName => { type => $scalar_type, resolve => sub { '' } }},
  );

=head1 ATTRIBUTES

Has C<name>, C<description> from L<GraphQL::Role::Named>.

=head2 fields

Hash-ref mapping field names to a hash-ref description. See
L<GraphQL::Utilities/FieldMapInput>.

=cut

has fields => (is => 'ro', isa => FieldMapInput, required => 1);

=head2 interfaces

Optional array-ref of interface type objects implemented.

=cut

has interfaces => (is => 'ro', isa => ArrayRef[InstanceOf['GraphQL::Type::Interface']]);

__PACKAGE__->meta->make_immutable();

1;
