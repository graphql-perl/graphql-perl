package GraphQL::Role::FieldsOutput;

use 5.014;
use strict;
use warnings;
use Moo::Role;
use Types::Standard -all;
use GraphQL::Type::Library -all;
use MooX::Thunking;

with qw(
  GraphQL::Role::FieldDeprecation
  GraphQL::Role::FieldsEither
);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::FieldsOutput - GraphQL object role implementing output fields

=head1 SYNOPSIS

  with qw(GraphQL::Role::FieldsOutput);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::FieldsOutput));

=head1 DESCRIPTION

Implements output fields.

=head1 ATTRIBUTES

=head2 fields

Thunk of hash-ref mapping fields to their types.
See L<GraphQL::Type::Library/FieldMapOutput>.

=cut

has fields => (is => 'thunked', isa => FieldMapOutput, required => 1);
around fields => sub {
  my ($orig, $self) = @_;
  $self->$orig; # de-thunk
  $self->_fields_deprecation_apply('fields');
  $self->{fields};
};

__PACKAGE__->meta->make_immutable();

1;
