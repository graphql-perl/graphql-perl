package GraphQL::Type;

use 5.014;
use strict;
use warnings;
use Moo;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type - GraphQL type object

=head1 SYNOPSIS

    extends qw(GraphQL::Type);

=head1 DESCRIPTION

Superclass for other GraphQL type classes to inherit from.

=cut

__PACKAGE__->meta->make_immutable();

1;
