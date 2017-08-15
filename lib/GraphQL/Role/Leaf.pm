package GraphQL::Role::Leaf;

use 5.014;
use strict;
use warnings;
use Moo::Role;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::Leaf - GraphQL "leaf" object role

=head1 SYNOPSIS

  with qw(GraphQL::Role::Leaf);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::Leaf));

=head1 DESCRIPTION

Allows type constraints for leaf objects.

=cut

__PACKAGE__->meta->make_immutable();

1;
