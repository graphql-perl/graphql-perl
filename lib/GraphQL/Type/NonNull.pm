package GraphQL::Type::NonNull;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard -all;
use Function::Parameters;
use Return::Type;
extends qw(GraphQL::Type);

our $VERSION = '0.02';

# A-ha
my @TAKE_ON_ME = qw(
  GraphQL::Role::Input
  GraphQL::Role::Output
);

=head1 NAME

GraphQL::Type::NonNull - GraphQL type that is a non-null version of another type

=head1 SYNOPSIS

  use GraphQL::Type::NonNull;
  my $type = GraphQL::Type::NonNull->new(of => $other_type);

=head1 DESCRIPTION

Type that is a wrapper for another type. Means data cannot be a null value.

=head1 ATTRIBUTES

=head2 of

GraphQL type object of which this is a non-null version.

=cut

has of => (
  is => 'ro',
  isa => InstanceOf['GraphQL::Type'],
  required => 1,
  handles => [ qw(name) ],
);

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
  $self->of->to_string . '!';
});

=head2 is_valid

True if given Perl value is a valid value for this type.

=cut

method is_valid(Any $item) :ReturnType(Bool) {
  return if !defined $item or !$self->of->is_valid($item);
  1;
}

method graphql_to_perl(Any $item) :ReturnType(Any) {
  my $of = $self->of;
  $of->graphql_to_perl($item) // die $self->to_string . " given null value.\n";
}

=head2 name

The C<name> of the type this object is a non-null version of.

=cut

__PACKAGE__->meta->make_immutable();

1;
