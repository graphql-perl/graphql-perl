package GraphQL::Type::List;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard -all;
use Function::Parameters;
use Return::Type;
extends qw(GraphQL::Type);
with qw(GraphQL::Role::Nullable);

# A-ha
my @TAKE_ON_ME = qw(
  GraphQL::Role::Input
  GraphQL::Role::Output
);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type::List - GraphQL type that is a list of another type

=head1 SYNOPSIS

  use GraphQL::Type::List;
  my $type = GraphQL::Type::List->new(of => $other_type);

=head1 DESCRIPTION

Type that is a wrapper for the type it is a list of. If the wrapped type
has any of these roles, it will assume them: L<GraphQL::Role::Input>,
L<GraphQL::Role::Output>, L<GraphQL::Role::Nullable>.

=head1 ATTRIBUTES

=head2 of

GraphQL type object of which this is a list.

=cut

has of => (is => 'ro', isa => InstanceOf['GraphQL::Type'], required => 1);

=head1 METHODS

=head2 BUILD

L<Moo> method that applies the relevant roles.

=cut

sub BUILD {
  my ($self, $args) = @_;
  my $of = $self->of;
  Role::Tiny->apply_roles_to_object($self, grep $of->DOES($_), @TAKE_ON_ME);
}

=head2 to_string

Part of serialisation.

=cut

has to_string => (is => 'lazy', isa => Str, init_arg => undef, builder => sub {
  my ($self) = @_;
  '[' . $self->of->to_string . ']';
});

=head2 is_valid

True if given Perl array-ref is a valid value for this type.

=cut

method is_valid(Maybe[ArrayRef] $item) :ReturnType(Bool) {
  return 1 if !defined $item;
  my $of = $self->of;
  return if grep !$of->is_valid($_), @$item;
  1;
}

=head2 uplift

Turn given Perl entity into valid value for this type if possible.
Mainly to promote single value into a list if type dictates.

=cut

# This is a crime against God. graphql-js does it however.
method uplift(Any $item) :ReturnType(Any) {
  return $item if ref($item) eq 'ARRAY' or !defined $item;
  [ $item ];
}

method graphql_to_perl(Maybe[ArrayRef] $item) :ReturnType(Maybe[ArrayRef]) {
  return $item if !defined $item;
  $item = $self->uplift($item);
  my $of = $self->of;
  my $i = 0;
  my @errors;
  my @values = map {
    my $value = eval { $of->graphql_to_perl($_) };
    push @errors, qq{In element #$i: $@} if $@;
    $i++;
    $value;
  } @$item;
  die @errors if @errors;
  \@values;
}

__PACKAGE__->meta->make_immutable();

1;
