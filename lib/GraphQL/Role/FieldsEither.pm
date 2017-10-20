package GraphQL::Role::FieldsEither;

use 5.014;
use strict;
use warnings;
use Moo::Role;
use Types::Standard -all;
use Function::Parameters;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::FieldsEither - GraphQL object role with code common to all fields

=head1 SYNOPSIS

  with qw(GraphQL::Role::FieldsEither);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::FieldsEither));

=head1 DESCRIPTION

Provides code useful to either type of fields.

=cut

method _make_field_def(
  HashRef $name2type,
  Str $field_name,
  HashRef $field_def,
) {
  my %args;
  %args = (args => +{
    map $self->_make_field_def($name2type, $_, $field_def->{args}{$_}),
      keys %{$field_def->{args}}
  }) if $field_def->{args};
  ($_ => { type => $name2type->{$field_def->{type}}, %args });
}

__PACKAGE__->meta->make_immutable();

1;
