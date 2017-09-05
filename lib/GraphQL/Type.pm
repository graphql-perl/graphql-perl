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

=head1 SUBCLASSES

These subclasses implement part of the GraphQL language
specification. Objects of these classes implement user-defined types
used to implement a GraphQL API.

=over

=item L<GraphQL::Type::Enum>

=item L<GraphQL::Type::InputObject>

=item L<GraphQL::Type::Interface>

=item L<GraphQL::Type::List>

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

=item L<GraphQL::Role::Named> - has a C<name> and C<description>, provided by this role

=item L<GraphQL::Role::NonNull> - must not be null-valued

=item L<GraphQL::Role::Nullable> - can be null-valued

=item L<GraphQL::Role::Output> - type can be an output

=back

=head1 TYPE LIBRARY

L<GraphQL::Type::Library> - implements various L<Type::Tiny>
type constraints, for use in L<Moo> attributes, and
L<Function::Parameters>/L<Return::Type> methods and functions.

=cut

__PACKAGE__->meta->make_immutable();

1;
