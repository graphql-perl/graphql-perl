package GraphQL::Type::Object;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(ArrayRef);
extends qw(GraphQL::Type);
with qw(
  GraphQL::Role::Output
  GraphQL::Role::Composite
  GraphQL::Role::Nullable
  GraphQL::Role::Named
  GraphQL::Role::FieldsOutput
);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type::Object - GraphQL object type

=head1 SYNOPSIS

  use GraphQL::Type::Object;
  my $interface_type;
  my $implementing_type = GraphQL::Type::Object->new(
    name => 'Object',
    interfaces => [ $interface_type ],
    fields => { fieldName => { type => $scalar_type, resolve => sub { '' } }},
  );

=head1 ATTRIBUTES

Has C<name>, C<description> from L<GraphQL::Role::Named>.
Has C<fields> from L<GraphQL::Role::FieldsOutput>.

=head2 interfaces

Optional array-ref of interface type objects implemented.

=cut

has interfaces => (is => 'ro', isa => ArrayRef);

__PACKAGE__->meta->make_immutable();

1;
