package GraphQL::Type::InputObject;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard -all;
use GraphQL::Type::Library -all;
use Function::Parameters;
use Return::Type;
use GraphQL::Debug qw(_debug);
extends qw(GraphQL::Type);
with qw(
  GraphQL::Role::Input
  GraphQL::Role::Nullable
  GraphQL::Role::Named
  GraphQL::Role::FieldsInput
  GraphQL::Role::HashMappable
  GraphQL::Role::FieldsEither
);

our $VERSION = '0.02';
use constant DEBUG => $ENV{GRAPHQL_DEBUG};

=head1 NAME

GraphQL::Type::InputObject - GraphQL input object type

=head1 SYNOPSIS

  use GraphQL::Type::InputObject;
  my $type = GraphQL::Type::InputObject->new(
    name => 'InputObject',
    fields => { field_name => { type => $scalar_type, resolve => sub { '' } }},
  );

=head1 ATTRIBUTES

Has C<name>, C<description> from L<GraphQL::Role::Named>.
Has C<fields> from L<GraphQL::Role::FieldsInput>.

=head2 interfaces

Optional array-ref of interface type objects implemented.

=cut

has interfaces => (is => 'ro', isa => ArrayRef[InstanceOf['GraphQL::Type::Interface']]);

=head1 METHODS

=head2 is_valid

True if given Perl hash-ref is a valid value for this type.

=cut

method is_valid(Maybe[HashRef] $item) :ReturnType(Bool) {
  return 1 if !defined $item;
  my $fields = $self->fields;
  return if grep !$fields->{$_}{type}->is_valid(
    $item->{$_} // $fields->{$_}{default_value}
  ), keys %$fields;
  1;
}

=head2 uplift

Turn given Perl entity into valid value for this type if possible. Applies
default values.

=cut

method uplift(Maybe[HashRef] $item) :ReturnType(Maybe[HashRef]) {
  return $item if !defined $item;
  my $fields = $self->fields;
  $self->hashmap($item, $fields, sub {
    my ($key, $value) = @_;
    $fields->{$key}{type}->uplift(
      $value // $fields->{$key}{default_value}
    );
  });
}

method graphql_to_perl(ExpectObject $item) :ReturnType(Maybe[HashRef]) {
  return $item if !defined $item;
  $item = $self->uplift($item);
  my $fields = $self->fields;
  $self->hashmap($item, $fields, sub {
    $fields->{$_[0]}{type}->graphql_to_perl($_[1]);
  });
}

method from_ast(
  HashRef $name2type,
  HashRef $ast_node,
) :ReturnType(InstanceOf[__PACKAGE__]) {
  $self->new(
    $self->_from_ast_named($ast_node),
    $self->_from_ast_fields($name2type, $ast_node, 'fields'),
  );
}

has to_doc => (is => 'lazy', isa => Str);
sub _build_to_doc {
  my ($self) = @_;
  DEBUG and _debug('InputObject.to_doc', $self);
  my @fieldlines = map {
    (
      ($_->[1] ? ("# $_->[1]") : ()),
      $_->[0],
    )
  } $self->_make_fieldtuples($self->fields);
  join '', map "$_\n",
    ($self->description ? (map "# $_", split /\n/, $self->description) : ()),
    "input @{[$self->name]} {",
      (map "  $_", @fieldlines),
    "}";
}

__PACKAGE__->meta->make_immutable();

1;
