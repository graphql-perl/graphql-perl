package GraphQL::Role::Input;

use 5.014;
use strict;
use warnings;
use Moo::Role;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::Input - GraphQL "input" object role

=head1 SYNOPSIS

  with qw(GraphQL::Role::Input);

=head1 DESCRIPTION

Allows type constraints for input objects.

=cut

__PACKAGE__->meta->make_immutable();

1;
