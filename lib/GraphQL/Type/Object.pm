package GraphQL::Type::Object;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard -all;
use GraphQL::Type::Library -all;
use MooX::Thunking;
use Function::Parameters;
use Return::Type;
extends qw(GraphQL::Type);
with qw(
  GraphQL::Role::Output
  GraphQL::Role::Composite
  GraphQL::Role::Nullable
  GraphQL::Role::Named
  GraphQL::Role::FieldsOutput
  GraphQL::Role::HashMappable
);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type::Object - GraphQL object type

=head1 SYNOPSIS

  use GraphQL::Type::Object;
  my $interface_type;
  my $implementing_type = GraphQL::Type::Object->new(
    name => 'Object',
    interfaces => [ $interface_type ],
    fields => { field_name => { type => $scalar_type, resolve => sub { '' } }},
  );

=head1 ATTRIBUTES

Has C<name>, C<description> from L<GraphQL::Role::Named>.
Has C<fields> from L<GraphQL::Role::FieldsOutput>.

=head2 interfaces

Optional, thunked array-ref of interface type objects implemented.

=cut

has interfaces => (is => 'thunked', isa => ArrayRef[InstanceOf['GraphQL::Type::Interface']]);

=head2 is_type_of

Optional code-ref. Input is a value, an execution context hash-ref,
and resolve-info hash-ref.

=cut

has is_type_of => (is => 'ro', isa => CodeRef);

method graphql_to_perl(Maybe[HashRef] $item) :ReturnType(Maybe[HashRef]) {
  return $item if !defined $item;
  $item = $self->uplift($item);
  my $fields = $self->fields;
  $self->hashmap($item, $fields, sub {
    my ($key, $value) = @_;
    $fields->{$key}{type}->graphql_to_perl(
      $value // $fields->{$key}{default_value}
    );
  });
}

=head2 to_doc($doc)

Returns Schema Definition Language (SDL) document that describes this
object.

=cut

has to_doc => (is => 'lazy', isa => Str);
sub _build_to_doc {
  my ($self) = @_;
  join '', map "$_\n",
    "type @{[$self->name]} {",
      (map "  $_: @{[$self->fields->{$_}{type}->to_string]}",
        sort keys %{$self->fields}),
    "}";
}

__PACKAGE__->meta->make_immutable();

1;
