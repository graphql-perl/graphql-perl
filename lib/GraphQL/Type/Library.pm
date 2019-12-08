package GraphQL::Type::Library;

use 5.014;
use strict;
use warnings;
use Type::Library
  -base,
  -declare => qw(
    StrNameValid FieldMapInput ValuesMatchTypes DocumentLocation JSONable
    ErrorResult
  );
use Type::Utils -all;
use Types::TypeTiny -all;
use Types::Standard -all;
use JSON::MaybeXS;

our $VERSION = '0.02';
my $JSON = JSON::MaybeXS->new->allow_nonref;

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
        $_->{$value_key} and !$_->{$type_key}->is_valid($_->{$value_key})
      } values %$_
    }, inline_as {
      (undef, <<EOF);
        !grep {
          \$_->{$value_key} and !\$_->{$type_key}->is_valid(\$_->{$value_key})
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
B<NB> this is a Perl value, not a JSON/GraphQL value.

=item description

Description.

=back

=cut

declare "FieldMapInput", as Map[
  StrNameValid,
  Dict[
    type => ConsumerOf['GraphQL::Role::Input'],
    default_value => Optional[Any],
    directives => Optional[ArrayRef[HashRef]],
    description => Optional[Str],
  ]
] & ValuesMatchTypes['default_value', 'type' ];

=head2 FieldMapOutput

Hash-ref mapping field names to a hash-ref
description. Description keys, all optional except C<type>:

=head3 type

GraphQL output type for the field.

=head3 args

A L</FieldMapInput>.

=head3 subscribe

Code-ref to return a given property from a given source-object.

=head3 deprecation_reason

Reason if deprecated. If given, also sets a boolean key of
C<is_deprecated> to true.

=head3 description

Description.

=head3 resolve

Code-ref to return a given property from a given source-object.
A key concept is to remember that the "object" on which these fields
exist, were themselves returned by other fields.

There are no restrictions on what you can return, so long as it is a
scalar, and if your return type is a L<list|GraphQL::Type::List>, that
scalar is an array-ref.

Emphasis has been put on there being Perl values here. Conversion
between Perl and GraphQL values is taken care of by
L<scalar|GraphQL::Type::Scalar> types, and it is only scalar information
that will be returned to the client, albeit in the shape dictated by
the object types.

An example function that takes a name and GraphQL type, and returns a
field definition, with a resolver that calls read-only L<Moo> accessors,
suitable for placing (several of) inside the hash-ref defining a type's
fields:

  sub _make_moo_field {
    my ($field_name, $type) = @_;
    ($field_name => { resolve => sub {
      my ($root_value, $args, $context, $info) = @_;
      my @passon = %$args ? ($args) : ();
      return undef unless $root_value->can($field_name);
      $root_value->$field_name(@passon);
    }, type => $type });
  }
  # ...
    fields => {
      _make_moo_field(name => $String),
      _make_moo_field(description => $String),
    },
  # ...

The code-ref will be called with these parameters:

=head4 $source

The Perl entity (possibly a blessed object) returned by the resolver
that conjured up this GraphQL object.

=head4 $args

Hash-ref of the arguments passed to the field. The values will be
Perl values.

=head4 $context

The "context" value supplied to the call to
L<GraphQL::Execution/execute>. Can be used for authenticated user
information, or a per-request cache.

=head4 $info

A hash-ref describing this node of the request; see L</info hash> below.

=head3 info hash

=head4 field_name

The real name of this field.

=head4 field_nodes

The array of Abstract Syntax Tree (AST) nodes that refer to this field
in this "selection set" (set of fields) on this object. There may be
more than one such set for a given field, if it is requested more
than once with a given name (not with an alias) - the results will
be combined into one reply.

=head4 return_type

The return type.

=head4 parent_type

The type of which this field is part.

=head4 path

The hierarchy of fields from the query root to this field-resolution.

=head4 schema

L<GraphQL::Schema> object.

=head4 fragments

Any fragments applying to this request.

=head4 root_value

The "root value" given to C<execute>.

=head4 operation

A hash-ref describing the operation (C<query>, etc) being executed.

=head4 variable_values

the operation's arguments, filled out with the variables hash supplied
to the request.

=head4 promise_code

A hash-ref. The relevant value supplied to the C<execute> function.

=cut

declare "FieldMapOutput", as Map[
  StrNameValid,
  Dict[
    type => ConsumerOf['GraphQL::Role::Output'],
    args => Optional[FieldMapInput],
    resolve => Optional[CodeRef],
    subscribe => Optional[CodeRef],
    directives => Optional[ArrayRef],
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

=head2 ExpectObject

A C<Maybe[HashRef]> that produces a GraphQL-like message if it fails,
saying "found not an object".

=cut

declare "ExpectObject",
  as Maybe[HashRef],
  message { "found not an object" };

=head2 DocumentLocation

Hash-ref that has keys C<line> and C<column> which are C<Int>.

=cut

declare "DocumentLocation",
  as Dict[
    line => Int,
    column => Int,
  ];

=head2 JSONable

A value that will be JSON-able.

=cut

declare "JSONable",
  as Any,
    where { $JSON->encode($_); 1 };

=head2 ErrorResult

Hash-ref that has keys C<message>, C<location>, C<path>, C<extensions>.

=cut

declare "ErrorResult",
  as Dict[
    message => Str,
    path => Optional[ArrayRef[Str]],
    locations => Optional[ArrayRef[DocumentLocation]],
    extensions => Optional[HashRef[JSONable]],
  ];

=head2 ExecutionResult

Hash-ref that has keys C<data> and/or C<errors>.

The C<errors>, if present, will be an array-ref of C<ErrorResult>.

The C<data> if present will be the return data, being a hash-ref whose
values are either further hashes, array-refs, or scalars. It will be
JSON-able.

=cut

declare "ExecutionResult",
  as Dict[
    data => Optional[JSONable],
    errors => Optional[ArrayRef[ErrorResult]],
  ];

=head2 ExecutionPartialResult

Hash-ref that has keys C<data> and/or C<errors>. Like L</ExecutionResult>
above, but the C<errors>, if present, will be an array-ref of
L<GraphQL::Error> objects.

=cut

declare "ExecutionPartialResult",
  as Dict[
    data => Optional[JSONable],
    errors => Optional[ArrayRef[InstanceOf['GraphQL::Error']]],
  ];

=head2 Promise

An object that has a C<then> method.

=cut

declare "Promise",
  as HasMethods['then'];

=head2 PromiseCode

A hash-ref with three keys: C<resolve>, C<all>, C<reject>. The values are
all code-refs that take one value (for C<all>, an array-ref), and create
the given kind of Promise.

=cut

declare "PromiseCode",
  as Dict[
    resolve => CodeLike,
    all => CodeLike,
    reject => CodeLike,
  ];

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

=cut

1;
