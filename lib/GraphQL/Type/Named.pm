package GraphQL::Type::Named;

use 5.014;
use strict;
use warnings;
use Moo;
extends qw(GraphQL::Type);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type::Named - GraphQL "named" object type

=head1 SYNOPSIS

  extends qw(GraphQL::Type::Named);

=head1 ATTRIBUTES

Inherits C<name>, C<description> from L<GraphQL::Type>.

=cut

__PACKAGE__->meta->make_immutable();

1;
