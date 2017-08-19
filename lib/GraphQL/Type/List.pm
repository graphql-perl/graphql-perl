package GraphQL::Type::List;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(InstanceOf);
extends qw(GraphQL::Type);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type::List - GraphQL type that is a list of another type

=head1 SYNOPSIS

  use GraphQL::Type::List;
  my $type = GraphQL::Type::List->new(of => $other_type);

=head1 DESCRIPTION

Type that is a wrapper for the type it is a list of. If the wrapped type
has any of these roles, it will assume them: L<GraphQL::Role::Input>,
L<GraphQL::Role::Output>, L<GraphQL::Role::Nullable>,
L<GraphQL::Role::NonNull>.

=head1 ATTRIBUTES

=head2 of

GraphQL type object of which this is a list.

=cut

has of => (is => 'ro', isa => InstanceOf['GraphQL::Type'], required => 1);

__PACKAGE__->meta->make_immutable();

1;
