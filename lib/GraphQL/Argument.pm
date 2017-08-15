package GraphQL::Argument;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str ConsumerOf Any);
extends qw(GraphQL::Type);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Argument - GraphQL argument

=head1 SYNOPSIS

  use GraphQL::Argument;
  my $directive = GraphQL::Argument->new(
    name => 'Object',
    type => $input_type,
  );

=head1 ATTRIBUTES

Inherits C<name>, C<description> from L<GraphQL::Type>.

=head2 type

GraphQL input-type object.

=cut

has type => (is => 'ro', isa => ConsumerOf['GraphQL::Type::Input'], required => 1);

=head2 default_value

Default value for this argument if none supplied. Must be same type as
the C<type>.

=cut

# TODO: change Any to check that is same as supplied "type". Possibly
# with builder?
has default_value => (is => 'ro', isa => Any);

__PACKAGE__->meta->make_immutable();

1;
