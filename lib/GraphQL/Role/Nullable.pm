package GraphQL::Role::Nullable;

use 5.014;
use strict;
use warnings;
use Types::Standard -all;
use Moo::Role;
use GraphQL::Type::NonNull;

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

Returns a wrapped version of the type using L<GraphQL::Type::NonNull>,
i.e. that may not be null.

=cut

has non_null => (
  is => 'lazy',
  isa => InstanceOf['GraphQL::Type::NonNull'],
  builder => sub { GraphQL::Type::NonNull->new(of => $_[0]) },
);

__PACKAGE__->meta->make_immutable();

1;
