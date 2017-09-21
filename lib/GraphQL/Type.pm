package GraphQL::Type;

use 5.014;
use strict;
use warnings;
use Moo;
use Return::Type;
use Function::Parameters;
use Types::Standard qw(InstanceOf Any); # if -all causes objects to be class 'Object'!
with 'GraphQL::Role::Listable';

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type - GraphQL type object

=head1 SYNOPSIS

    extends qw(GraphQL::Type);

=head1 DESCRIPTION

Superclass for other GraphQL type classes to inherit from.

=head1 ENCODING

Those Perl classes each implement a GraphQL type. Each item of
GraphQL data has a GraphQL type.  Such an item of data can also be
represented within Perl. Objects of that Perl class take responsibility
for translating between the Perl representation and the "GraphQL
representation". A "GraphQL representation" means something
JSON-encodeable: an "object" (in Perl terms, a hash), an array (Perl:
array-reference), string, number, boolean, or null.

See L</METHODS> for generic methods to translate back and forth between
these worlds.

Code that you provide to do this translation must return things that
I<can> be JSON-encoded, not things that I<have been> so encoded: this
means, among other things, do not surround strings in C<">, and for
boolean values, use the mechanism in L<JSON::MaybeXS>: C<JSON->true> etc.

=head1 SUBCLASSES

These subclasses implement part of the GraphQL language
specification. Objects of these classes implement user-defined types
used to implement a GraphQL API.

=over

=item L<GraphQL::Type::Enum>

=item L<GraphQL::Type::InputObject>

=item L<GraphQL::Type::Interface>

=item L<GraphQL::Type::List>

=item L<GraphQL::Type::NonNull>

=item L<GraphQL::Type::Object>

=item L<GraphQL::Type::Scalar> - also implements example types such as C<String>

=item L<GraphQL::Type::Union>

=back

=head1 ROLES

These roles implement part of the GraphQL language
specification. They are applied to objects of L<GraphQL::Type> classes,
either to facilitate type constrants, or as noted below.

=over

=item L<GraphQL::Role::FieldsInput> - provides C<fields> attribute for an input type

=item L<GraphQL::Role::FieldsOutput> - provides C<fields> attribute for an output type

=item L<GraphQL::Role::Abstract> - abstract type

=item L<GraphQL::Role::Composite> - type has fields

=item L<GraphQL::Role::Input> - type can be an input

=item L<GraphQL::Role::Leaf> - simple type - enum or scalar

=item L<GraphQL::Role::Listable> - can be list-wrapped; provides convenience method

=item L<GraphQL::Role::Named> - has a C<name> and C<description>, provided by this role

=item L<GraphQL::Role::Nullable> - can be null-valued

=item L<GraphQL::Role::Output> - type can be an output

=back

=head1 TYPE LIBRARY

L<GraphQL::Type::Library> - implements various L<Type::Tiny>
type constraints, for use in L<Moo> attributes, and
L<Function::Parameters>/L<Return::Type> methods and functions.

=head1 METHODS

=head2 clone

Shallow copy of the object, suitable for reblessing without affecting
the original object.

=cut

method clone() :ReturnType(InstanceOf['GraphQL::Type']) {
  ref($self)->new(%$self)
}

=head2 uplift

Turn given Perl entity into valid Perl value for this type if possible.

=cut

method uplift(Any $item) :ReturnType(Any) { $item; }

=head2 graphql_to_perl

Turn given GraphQL entity into Perl entity.

=head2 perl_to_graphql

Turn given Perl entity into GraphQL entity.

=cut

__PACKAGE__->meta->make_immutable();

1;
