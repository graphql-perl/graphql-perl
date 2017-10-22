package GraphQL::Type::Interface;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard -all;
use Function::Parameters;
use Return::Type;
extends qw(GraphQL::Type);
with qw(
  GraphQL::Role::Output
  GraphQL::Role::Composite
  GraphQL::Role::Abstract
  GraphQL::Role::Nullable
  GraphQL::Role::Named
  GraphQL::Role::FieldsOutput
  GraphQL::Role::FieldsEither
);

our $VERSION = '0.02';
use constant DEBUG => $ENV{GRAPHQL_DEBUG};

=head1 NAME

GraphQL::Type::Interface - GraphQL interface type

=head1 SYNOPSIS

  use GraphQL::Type::Interface;
  my $ImplementingType;
  my $InterfaceType = GraphQL::Type::Interface->new(
    name => 'Interface',
    fields => { field_name => { type => $scalar_type } },
    resolve_type => sub {
      return $ImplementingType;
    },
  );

=head1 ATTRIBUTES

Has C<name>, C<description> from L<GraphQL::Role::Named>.
Has C<fields> from L<GraphQL::Role::FieldsOutput>.

=head2 resolve_type

Optional code-ref to resolve types.

=cut

has resolve_type => (is => 'ro', isa => CodeRef);

method from_ast(
  HashRef $name2type,
  HashRef $ast_node,
) :ReturnType(InstanceOf[__PACKAGE__]) {
  $self->new(
    $self->_from_ast_named($ast_node),
    fields => sub { +{
      map $self->_make_field_def($name2type, $_, $ast_node->{fields}{$_}),
        keys %{$ast_node->{fields}}
    } },
  );
}

has to_doc => (is => 'lazy', isa => Str);
sub _build_to_doc {
  my ($self) = @_;
  DEBUG and _debug('Interface.to_doc', $self);
  my @fieldlines = map {
    (
      ($_->[1] ? ("# $_->[1]") : ()),
      $_->[0],
    )
  } $self->_make_fieldtuples($self->fields);
  join '', map "$_\n",
    ($self->description ? (map "# $_", split /\n/, $self->description) : ()),
    "interface @{[$self->name]} {",
      (map "  $_", @fieldlines),
    "}";
}

__PACKAGE__->meta->make_immutable();

1;
