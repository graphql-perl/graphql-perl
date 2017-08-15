package GraphQL::Role::Output;

use 5.014;
use strict;
use warnings;
use Moo::Role;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::Output - GraphQL "output" object role

=head1 SYNOPSIS

  with qw(GraphQL::Role::Output);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::Output));

=head1 DESCRIPTION

Allows type constraints for output objects.

=cut

__PACKAGE__->meta->make_immutable();

1;
