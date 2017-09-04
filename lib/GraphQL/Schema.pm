package GraphQL::Schema;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard -all;
use GraphQL::Type::Library -all;
use Return::Type;
use Function::Parameters;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Schema - GraphQL schema object

=head1 SYNOPSIS

  use GraphQL::Schema;
  use GraphQL::Type::Object;
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Query',
      fields => {
        getObject => {
          type => $interfaceType,
          resolve => sub {
            return {};
          }
        }
      }
    )
  );

=head1 DESCRIPTION

Class implementing GraphQL schema.

=head1 ATTRIBUTES

=head2 query

=cut

has query => (is => 'ro', isa => InstanceOf['GraphQL::Type::Object'], required => 1);

=head2 mutation

=cut

has mutation => (is => 'ro', isa => InstanceOf['GraphQL::Type::Object']);

=head2 subscription

=cut

has subscription => (is => 'ro', isa => InstanceOf['GraphQL::Type::Object']);

=head2 types

=cut

has types => (
  is => 'ro',
  isa => ArrayRef[ConsumerOf['GraphQL::Role::Named']],
  default => sub { [] },
);

=head2 directives

=cut

has directives => (is => 'ro', isa => ArrayRef[InstanceOf['GraphQL::Directive']]);

=head1 METHODS

=head2 get_possible_types($abstract_type)

In this schema, get all of either the implementation types
(if interface) or possible types (if union) of the C<$abstract_type>.

=cut

has _name2type => (is => 'lazy', isa => Map[StrNameValid, ConsumerOf['GraphQL::Role::Named']]);
sub _build__name2type {
  my ($self) = @_;
  my @types = grep $_, map $self->$_, qw(query mutation subscription); # TODO also __Schema
  push @types, @{ $self->types || [] };
  my %name2type;
  my @bad = map $_->name, grep {
    my $already = $name2type{$_->name}||0;
    $already != ($name2type{$_->name} = $_) and $already
  } map @{ _expand_type($_) }, @types;
  die "non-unique types named @bad" if @bad;
  \%name2type;
}

fun _expand_type(
  (InstanceOf['GraphQL::Type']) $type,
) :ReturnType(ArrayRef[InstanceOf['GraphQL::Type']]) {
  my @types = ($type);
  push @types, ($type, map @{ _expand_type($_) }, @{ $type->interfaces || [] })
    if $type->isa('GraphQL::Type::Object');
  push @types, ($type, map @{ _expand_type($_) }, $type->get_types)
    if $type->isa('GraphQL::Type::Union');
  if (grep $type->DOES($_), qw(GraphQL::Role::FieldsInput GraphQL::Role::FieldsOutput)) {
    my $fields = $type->fields||{};
    push @types, map {
      ($_->{type}, (map @{ _expand_type($_->type) }, @{ $_->{args}||[] }))
    } values %$fields;
  }
  \@types;
}

has _interface2types => (is => 'lazy', isa => Map[StrNameValid, ArrayRef[InstanceOf['GraphQL::Type::Object']]]);
sub _build__interface2types {
  my ($self) = @_;
  my $name2type = $self->_name2type||{};
  my %interface2types;
  map {
    my $o = $_;
    map {
      push @{$interface2types{$_->name}}, $o;
      # TODO assert_object_implements_interface
    } @{ $o->interfaces||[] };
  } grep $_->isa('GraphQL::Type::Object'), values %$name2type;
  \%interface2types;
}

method get_possible_types(
  (ConsumerOf['GraphQL::Role::Abstract']) $abstract_type
) :ReturnType(ArrayRef[InstanceOf['GraphQL::Type::Object']]) {
  return $abstract_type->get_types if $abstract_type->isa('GraphQL::Type::Union');
  $self->_interface2types->{$abstract_type->name} || [];
}

=head2 is_possible_type($abstract_type, $possible_type)

In this schema, is the given C<$possible_type> either an implementation
(if interface) or a possibility (if union) of the C<$abstract_type>?

=cut

has _possible_type_map => (is => 'rw', isa => Map[StrNameValid, Map[StrNameValid, Bool]]);
method is_possible_type(
  (ConsumerOf['GraphQL::Role::Abstract']) $abstract_type,
  (InstanceOf['GraphQL::Type::Object']) $possible_type,
) :ReturnType(Bool) {
  my $map = $self->_possible_type_map || {};
  return $map->{$abstract_type->name}{$possible_type->name}
    if $map->{$abstract_type->name}; # we know about the abstract_type
  my @possibles = @{ $self->get_possible_types($abstract_type)||[] };
  die <<EOF if !@possibles;
Could not find possible implementing types for @{[$abstract_type->name]}
in schema. Check that schema.types is defined and is an array of
all possible types in the schema.
EOF
  $map->{$abstract_type->name} = { map { ($_->name => 1) } @possibles };
  $self->_possible_type_map($map);
  $map->{$abstract_type->name}{$possible_type->name};
}

=head2 assert_object_implements_interface($type, $iface)

In this schema, does the given C<$type> implement interface C<$iface>? If
not, throw exception.

=cut

method assert_object_implements_interface(
  (ConsumerOf['GraphQL::Role::Abstract']) $abstract_type,
  (InstanceOf['GraphQL::Type::Object']) $possible_type,
) {
  my @types = @{ $self->types };
  return;
}

__PACKAGE__->meta->make_immutable();

1;
