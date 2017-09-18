package GraphQL::Type::InputObject;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard -all;
use Function::Parameters;
use Return::Type;

extends qw(GraphQL::Type);
with qw(
  GraphQL::Role::Input
  GraphQL::Role::Nullable
  GraphQL::Role::Named
  GraphQL::Role::FieldsInput
);

our $VERSION = '0.02';

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
  return if !defined $item and $self->DOES('GraphQL::Role::NonNull');
  my $fields = $self->fields;
  return if grep !$fields->{$_}{type}->is_valid(
    $item->{$_} // $fields->{$_}{default_value}
  ), keys %$fields;
  1;
}

__PACKAGE__->meta->make_immutable();

1;
