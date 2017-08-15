package GraphQL::Role::Abstract;

use 5.014;
use strict;
use warnings;
use Moo::Role;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::Abstract - GraphQL object role

=head1 SYNOPSIS

  with qw(GraphQL::Role::Abstract);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::Abstract));

=head1 DESCRIPTION

Allows type constraints for abstract objects.

=cut

__PACKAGE__->meta->make_immutable();

1;
