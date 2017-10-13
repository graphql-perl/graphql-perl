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

=head2 original_error

If there is an original error to be preserved.

=cut

has original_error => (is => 'ro', isa => Any);

=head2 locations

Array-ref of L<GraphQL::Type::Library/DocumentLocation>s.

=cut

has locations => (is => 'ro', isa => ArrayRef[DocumentLocation]);

=head1 METHODS

=head2 is

Is the supplied scalar an error object?

=cut

method is(Any $item) :ReturnType(Bool) { ref $item eq __PACKAGE__ }

=head2 coerce

If supplied scalar is an error object, return. If not, return one with
it as message. If an object, message will be stringified version of that,
it will be preserved as C<original_error>.

=cut

method coerce(Any $item) :ReturnType(InstanceOf[__PACKAGE__]) {
  return $item if $self->is($item);
  is_InstanceOf($item)
    ? $self->new(message => $item.'', original_error => $item)
    : $self->new(message => $item);
}

=head2 but

Returns a copy of the error object, but with the given properties (as
with a C<new> method, not coincidentally) overriding the existing ones.

=cut

sub but :ReturnType(InstanceOf[__PACKAGE__]) {
  my $self = shift;
  $self->new(%$self, @_);
}

=head2 to_string

Converts to string.

=cut

method to_string() :ReturnType(Str) {
  $self->message;
}

__PACKAGE__->meta->make_immutable();

1;
