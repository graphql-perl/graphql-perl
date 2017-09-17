package GraphQL::Type::Scalar;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(CodeRef Num Str Bool);
use GraphQL::Type::Library qw(Int32Signed);
use Types::Standard -all;
use JSON::MaybeXS;
use Exporter qw(import);
extends qw(GraphQL::Type);
with qw(
  GraphQL::Role::Input
  GraphQL::Role::Output
  GraphQL::Role::Leaf
  GraphQL::Role::Nullable
  GraphQL::Role::Named
);
use Function::Parameters;
use Return::Type;

our $VERSION = '0.02';
our @EXPORT_OK = qw($Int $Float $String $Boolean $ID);

my $JSON = JSON::MaybeXS->new->allow_nonref;

=head1 NAME

GraphQL::Type::Scalar - GraphQL scalar type

=head1 SYNOPSIS

  use GraphQL::Type::Scalar;
  my $int_type = GraphQL::Type::Scalar->new(
    name => 'Int',
    description =>
      'The `Int` scalar type represents non-fractional signed whole numeric ' .
      'values. Int can represent values between -(2^31) and 2^31 - 1. ',
    serialize => \&coerce_int,
    parse_value => \&coerce_int,
  );

=head1 ATTRIBUTES

Has C<name>, C<description> from L<GraphQL::Role::Named>.

=head2 serialize

Code-ref. Should throw an exception if not passed a Perl object of the
relevant type. Returns that object turned into JSON.

=cut

has serialize => (is => 'ro', isa => CodeRef, required => 1);

=head2 parse_value

Code-ref. Required if is for an input type. Coerces a Perl entity into
one of the required type, or throws an exception.

=cut

has parse_value => (is => 'ro', isa => CodeRef);

=head1 METHODS

=head2 is_valid

True if given Perl entity is valid value for this type. Uses L</serialize>
attribute.

=cut

method is_valid(Any $item) :ReturnType(Bool) {
  eval { $self->serialize->($item); 1 };
}

=head1 EXPORTED VARIABLES

=head2 $Int

=cut

our $Int = GraphQL::Type::Scalar->new(
  name => 'Int',
  description =>
    'The `Int` scalar type represents non-fractional signed whole numeric ' .
    'values. Int can represent values between -(2^31) and 2^31 - 1.',
  serialize => sub { Int32Signed->(@_); $JSON->encode($_[0]) },
  parse_value => sub { Int32Signed->(@_); $JSON->encode($_[0]) },
);

=head2 $Float

=cut

our $Float = GraphQL::Type::Scalar->new(
  name => 'Float',
  description =>
    'The `Float` scalar type represents signed double-precision fractional ' .
    'values as specified by ' .
    '[IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).',
  serialize => sub { Num->(@_); $JSON->encode($_[0]) },
  parse_value => sub { Num->(@_); $JSON->encode($_[0]) },
);

=head2 $String

=cut

our $String = GraphQL::Type::Scalar->new(
  name => 'String',
  description =>
    'The `String` scalar type represents textual data, represented as UTF-8 ' .
    'character sequences. The String type is most often used by GraphQL to ' .
    'represent free-form human-readable text.',
  serialize => sub { Str->(@_); $JSON->encode($_[0]) },
  parse_value => sub { Str->(@_); $JSON->encode($_[0]) },
);

=head2 $Boolean

=cut

our $Boolean = GraphQL::Type::Scalar->new(
  name => 'Boolean',
  description =>
    'The `Boolean` scalar type represents `true` or `false`.',
  serialize => sub { Bool->(@_); $_[0] ? 'true' : 'false' },
  parse_value => sub { Bool->(@_); $_[0] ? 'true' : 'false' },
);

=head2 $ID

=cut

our $ID = GraphQL::Type::Scalar->new(
  name => 'ID',
  description =>
    'The `ID` scalar type represents a unique identifier, often used to ' .
    'refetch an object or as key for a cache. The ID type appears in a JSON ' .
    'response as a String; however, it is not intended to be human-readable. ' .
    'When expected as an input type, any string (such as `"4"`) or integer ' .
    '(such as `4`) input value will be accepted as an ID.',
  serialize => sub { Str->(@_); $JSON->encode($_[0]) },
  parse_value => sub { Str->(@_); $JSON->encode($_[0]) },
);

__PACKAGE__->meta->make_immutable();

1;
