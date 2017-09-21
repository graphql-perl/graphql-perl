package GraphQL::Role::Listable;

use 5.014;
use strict;
use warnings;
use Types::Standard -all;
use Moo::Role;
use GraphQL::Type::List;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::Listable - GraphQL object role

=head1 SYNOPSIS

  with qw(GraphQL::Role::Listable);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::Listable));

=head1 DESCRIPTION

Provides shortcut method for getting a type object's list wrapper.

=head1 METHODS

=head2 list

Returns a wrapped version of the type using L<GraphQL::Type::List>.

=cut

has list => (
  is => 'lazy',
  isa => InstanceOf['GraphQL::Type::List'],
  builder => sub { GraphQL::Type::List->new(of => $_[0]) },
);

__PACKAGE__->meta->make_immutable();

1;
