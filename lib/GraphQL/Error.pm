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

=head2 is

Is the supplied scalar an error object?

=cut

method is(Any $item) :ReturnType(Bool) { ref $item eq __PACKAGE__ }

=head2 coerce

If supplied scalar is an error object, return. If not, return one with
it as message.

=cut

method coerce(Any $item) :ReturnType(InstanceOf[__PACKAGE__]) {
  return $item if $self->is($item);
  $self->new(message => $item);
}

__PACKAGE__->meta->make_immutable();

1;
