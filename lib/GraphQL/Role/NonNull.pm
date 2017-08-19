package GraphQL::Role::NonNull;

use 5.014;
use strict;
use warnings;
use Moo::Role;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::NonNull - GraphQL object role

=head1 SYNOPSIS

  with qw(GraphQL::Role::NonNull);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::NonNull));

=head1 DESCRIPTION

Allows type constraints for input objects.

=cut

__PACKAGE__->meta->make_immutable();

1;
