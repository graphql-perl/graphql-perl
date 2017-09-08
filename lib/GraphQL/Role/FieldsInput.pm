package GraphQL::Role::FieldsInput;

use 5.014;
use strict;
use warnings;
use Moo::Role;
use MooX::Thunking;
use GraphQL::Type::Library qw(FieldMapInput);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::FieldsInput - GraphQL object role implementing input fields

=head1 SYNOPSIS

  with qw(GraphQL::Role::FieldsInput);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::FieldsInput));

=head1 DESCRIPTION

Implements input fields.

=head1 ATTRIBUTES

=head2 fields

Hash-ref mapping fields to their types.
See L<GraphQL::Type::Library/FieldMapInput>.

=cut

has fields => (is => 'thunked', isa => FieldMapInput, required => 1);

__PACKAGE__->meta->make_immutable();

1;
