package GraphQL::Type::List;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard -all;
extends qw(GraphQL::Type);

# A-ha
my @TAKE_ON_ME = qw(
  GraphQL::Role::Input
  GraphQL::Role::Output
  GraphQL::Role::Nullable
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

has to_string => (is => 'lazy', isa => Str, init_arg => '_noclone_to_string', builder => sub {
  my ($self) = @_;
  '[' . $self->of->to_string . ']' . ($self->does('GraphQL::Role::NonNull') ? '!' : '');
});

__PACKAGE__->meta->make_immutable();

1;
