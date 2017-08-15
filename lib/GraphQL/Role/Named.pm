package GraphQL::Role::Named;

use 5.014;
use strict;
use warnings;
use Moo::Role;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::Named - GraphQL "named" object role

=head1 SYNOPSIS

  with qw(GraphQL::Role::Named);

=head1 DESCRIPTION

Allows type constraints for named objects.

=cut

__PACKAGE__->meta->make_immutable();

1;
