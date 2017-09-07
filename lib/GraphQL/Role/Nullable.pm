package GraphQL::Role::Nullable;

use 5.014;
use strict;
use warnings;
use Types::Standard -all;
use Moo::Role;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::Nullable - GraphQL object role

=head1 SYNOPSIS

  with qw(GraphQL::Role::Nullable);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::Nullable));

=head1 DESCRIPTION

Allows type constraints for nullable objects.

=head1 METHODS

=head2 non_null

Returns a version of the type with the role L<GraphQL::Role::NonNull>,
i.e. that may not be null.

=cut

has non_null => (
  is => 'lazy',
  isa => ConsumerOf['GraphQL::Role::NonNull'],
  builder => sub { Role::Tiny->apply_roles_to_object(shift->clone, qw(GraphQL::Role::NonNull)) },
);

__PACKAGE__->meta->make_immutable();

1;
