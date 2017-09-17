package GraphQL::Error;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard -all;
use GraphQL::Type::Library -all;
use Return::Type;
use Function::Parameters;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Error - GraphQL error object

=head1 SYNOPSIS

  use GraphQL::Error;
  die GraphQL::Error->new(message => 'Something is not right...');

=head1 DESCRIPTION

Class implementing GraphQL error object.

=head1 ATTRIBUTES

=head2 message

=cut

has message => (is => 'ro', isa => Str, required => 1);

=head1 METHODS

=cut

__PACKAGE__->meta->make_immutable();

1;
