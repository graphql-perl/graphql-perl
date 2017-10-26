package GraphQL::Role::FieldsEither;

use 5.014;
use strict;
use warnings;
use Moo::Role;
use GraphQL::Debug qw(_debug);
use Types::Standard -all;
use Function::Parameters;

our $VERSION = '0.02';
use constant DEBUG => $ENV{GRAPHQL_DEBUG};

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
  DEBUG and _debug('FieldsEither._make_field_def', $field_def);
  require GraphQL::Schema;
  my %args;
  %args = (args => +{
    map $self->_make_field_def($name2type, $_, $field_def->{args}{$_}),
      keys %{$field_def->{args}}
  }) if $field_def->{args};
  ($_ => { %$field_def, type => GraphQL::Schema::lookup_type($field_def, $name2type), %args });
}

method _from_ast_fields(
  HashRef $name2type,
  HashRef $ast_node,
  Str $key,
) {
  (
    $key => sub { +{
      map $self->_make_field_def($name2type, $_, $ast_node->{$key}{$_}),
        keys %{$ast_node->{$key}}
    } },
  );
}

method _make_fieldtuples(
  HashRef $fields,
) {
  DEBUG and _debug('FieldsEither._make_fieldtuples', $fields);
  map {
    my $field = $fields->{$_};
    my @argtuples = map $_->[0],
      $self->_make_fieldtuples($field->{args} || {});
    my $type = $field->{type};
    my $line = $_;
    $line .= '('.join(', ', @argtuples).')' if @argtuples;
    $line .= ': ' . $type->to_string;
    [
      $line,
      $field->{description},
    ]
  } sort keys %$fields;
}

__PACKAGE__->meta->make_immutable();

1;
