package GraphQL::Role::Instrument;

use 5.014;
use strict;
use warnings;
use Moo::Role;

our $VERSION = '0.01';

=head1 NAME

GraphQL::Role::Instrument - GraphQL object role

=head1 SYNOPSIS

  with qw(GraphQL::Role::Instrument);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::Instrument));

=head1 DESCRIPTION

Make instrumentation with this role.

=cut

requires 'instrument';

__PACKAGE__->meta->make_immutable();

1;
