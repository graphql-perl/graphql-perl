package GraphQL::Type::Library;

use 5.014;
use strict;
use warnings;
use Type::Library
  -base,
  -declare => qw( StrNameValid FieldMapInput ValuesMatchTypes );
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

=head2 ValuesMatchTypes

Subtype of L<Types::Standard/HashRef>, whose values are hash-refs. Takes
two parameters:

=over

=item value keyname

Optional within the second-level hashes.

=item type keyname

Values will be a L<GraphQL::Type>. Mandatory within the second-level hashes.

=back

In the second-level hashes, the values (if given) must pass the GraphQL
type constraint.

=cut

declare "ValuesMatchTypes",
  constraint_generator => sub {
    my ($value_key, $type_key) = @_;
    declare as HashRef[Dict[
      $type_key => ConsumerOf['GraphQL::Role::Input'],
      slurpy Any,
    ]], where {
      !grep {
        $_->{$value_key} and
          !eval { $_->{$type_key}->serialize->($_->{$value_key}); 1 }
      } values %$_
    }, inline_as {
      (undef, <<EOF);
        !grep {
          \$_->{$value_key} and
            !eval { \$_->{$type_key}->serialize->(\$_->{$value_key}); 1 }
        } values %{$_[1]}
EOF
    };
};

=head2 FieldMapInput

Hash-ref mapping field names to a hash-ref
description. Description keys, all optional except C<type>:

=over

=item type

GraphQL input type for the field.

=item default_value

Default value for this argument if none supplied. Must be same type as
the C<type> (implemented with type L</ValuesMatchTypes>.

=item description

Description.

=back

=cut

declare "FieldMapInput", as Map[
  StrNameValid,
  Dict[
    type => ConsumerOf['GraphQL::Role::Input'],
    default_value => Optional[Any],
    description => Optional[Str],
  ]
] & ValuesMatchTypes['default_value', 'type' ];

=head2 FieldMapOutput

Hash-ref mapping field names to a hash-ref
description. Description keys, all optional except C<type>:

=over

=item type

GraphQL output type for the field.

=item args

A L</FieldMapInput>.

=item resolve

Code-ref to return a given property from a given source-object.

=item subscribe

Code-ref to return a given property from a given source-object.

=item deprecation_reason

Reason if deprecated. If given, also sets a boolean key of
C<is_deprecated> to true.

=item description

Description.

=back

=cut

declare "FieldMapOutput", as Map[
  StrNameValid,
  Dict[
    type => ConsumerOf['GraphQL::Role::Output'],
    args => Optional[FieldMapInput],
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

=head2 UniqueByProperty

An ArrayRef, its members' property (the one in the parameter) can occur
only once.

  use Moo;
  use GraphQL::Type::Library -all;
  has types => (
    is => 'ro',
    isa => UniqueByProperty['name'] & ArrayRef[InstanceOf['GraphQL::Type::Object']],
    required => 1,
  );

=cut

declare "UniqueByProperty",
  constraint_generator => sub {
    die "must give one property name" unless @_ == 1;
    my ($prop) = @_;
    declare as ArrayRef[HasMethods[$prop]], where {
      my %seen;
      !grep $seen{$_->$prop}++, @$_;
    }, inline_as {
      (undef, "my %seen; !grep \$seen{\$_->$prop}++, \@{$_[1]};");
    };
  };

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

=cut

1;
