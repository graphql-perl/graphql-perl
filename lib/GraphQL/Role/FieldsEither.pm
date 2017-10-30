package GraphQL::Role::FieldsEither;

use 5.014;
use strict;
use warnings;
use Moo::Role;
use GraphQL::Debug qw(_debug);
use Types::Standard -all;
use Function::Parameters;
use JSON::MaybeXS;
with qw(GraphQL::Role::FieldDeprecation);

our $VERSION = '0.02';
use constant DEBUG => $ENV{GRAPHQL_DEBUG};
my $JSON_noutf8 = JSON::MaybeXS->new->utf8(0)->allow_nonref;

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
  ($_ => {
    %$field_def,
    type => GraphQL::Schema::lookup_type($field_def, $name2type),
    %args,
  });
}

method _from_ast_fields(
  HashRef $name2type,
  HashRef $ast_node,
  Str $key,
) {
  my $fields = $ast_node->{$key};
  $fields = $self->_from_ast_field_deprecate($_, $fields) for keys %$fields;
  (
    $key => sub { +{
      map {
        my @pair = eval {
          $self->_make_field_def($name2type, $_, $fields->{$_})
        };
        die "Error in field '$_': $@" if $@;
        @pair;
      } keys %$fields
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
    $line .= ' = ' . $JSON_noutf8->encode(
      $type->perl_to_graphql($field->{default_value})
    ) if exists $field->{default_value};
    [
      $self->_to_doc_field_deprecate($line, $field),
      $field->{description},
    ]
  } sort keys %$fields;
}

__PACKAGE__->meta->make_immutable();

1;
