package GraphQL::Type::Library;

use 5.014;
use strict;
use warnings;
use Type::Library
  -base,
  -declare => qw( StrNameValid FieldMapInput FieldMapOutput Int32Signed );
use Type::Utils -all;
use Types::TypeTiny -all;
use Types::Standard -all;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type::Library - GraphQL type library

=head1 SYNOPSIS

    use GraphQL::Type::Library -all;
    has name => (is => 'ro', isa => StrNameValid, required => 1);

=head1 DESCRIPTION

Provides L<Type::Tiny> types.

=head1 TYPES

=head2 StrNameValid

If called with a string that is not a valid GraphQL name, will throw
an exception. Suitable for passing to an C<isa> constraint in L<Moo>.

=cut

declare "StrNameValid", as StrMatch[ qr/^[_a-zA-Z][_a-zA-Z0-9]*$/ ];

=head2 FieldMapInput

Hash-ref mapping field names to a hash-ref description. Description keys,
all optional except C<type>:

=over

=item type

GraphQL input type for the field.

=item default_value

Default value for this argument if none supplied. Must be same type as
the C<type>.

=item description

Description.

=back

=cut

declare "FieldMapInput", as Map[
  StrNameValid,
  Dict[
    type => ConsumerOf['GraphQL::Role::Input'],
    # TODO: change Any to check that is same as supplied "type". Possibly
    # with builder?
    default_value => Optional[Any],
    description => Optional[Str],
  ]
];

=head2 FieldMapOutput

Hash-ref mapping field names to a hash-ref description. Description keys,
all optional except C<type>:

=over

=item type

GraphQL output type for the field.

=item args

Array-ref of L<GraphQL::Argument>s.

=item resolve

Code-ref to return a given property from a given source-object.

=item subscribe

Code-ref to return a given property from a given source-object.

=item deprecation_reason

Reason if deprecated.

=item description

Description.

=back

=cut

declare "FieldMapOutput", as Map[
  StrNameValid,
  Dict[
    type => ConsumerOf['GraphQL::Role::Output'],
    args => Optional[ArrayRef[InstanceOf['GraphQL::Argument']]],
    resolve => Optional[CodeRef],
    subscribe => Optional[CodeRef],
    deprecation_reason => Optional[Str],
    description => Optional[Str],
  ]
];

=head2 Int32Signed

32-bit signed integer.

=cut

declare "Int32Signed", as Int, where { $_ >= -2147483648 and $_ <= 2147483647 };

=head2 ArrayRefNonEmpty

Like L<Types::Standard/ArrayRef> but requires at least one entry.

=cut

declare "ArrayRefNonEmpty", constraint_generator => sub {
  intersection [ ArrayRef[@_], Tuple[Any, slurpy Any] ]
};

=head2 Thunk

Can be either a L<Types::TypeTiny/CodeLike> or the type(s) given as
parameters.

=cut

declare "Thunk", constraint_generator => sub { union [ CodeLike, @_ ] };

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

=cut

1;
