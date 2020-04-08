package GraphQL::Type::Scalar;

use 5.014;
use strict;
use warnings;
use Moo;
use GraphQL::Type::Library -all;
use GraphQL::Debug qw(_debug);
use Types::Standard -all;
use JSON::MaybeXS qw(JSON is_bool);
use Exporter 'import';
extends qw(GraphQL::Type);
with qw(
  GraphQL::Role::Input
  GraphQL::Role::Output
  GraphQL::Role::Leaf
  GraphQL::Role::Nullable
  GraphQL::Role::Named
  GraphQL::Role::FieldsEither
);
use Function::Parameters;
use Return::Type;
use GraphQL::Plugin::Type;

our $VERSION = '0.02';
our @EXPORT_OK = qw($Int $Float $String $Boolean $ID);

use constant DEBUG => $ENV{GRAPHQL_DEBUG};
my $JSON = JSON::MaybeXS->new->allow_nonref->canonical;

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

Code-ref. Required.

Coerces
B<from> a Perl entity of the required type,
B<to> a GraphQL entity,
or throws an exception.

Must throw an exception if passed a defined (i.e. non-null) but invalid
Perl object of the relevant type. C<undef> must always be valid.

=cut

has serialize => (is => 'ro', isa => CodeRef, required => 1);

=head2 parse_value

Code-ref. Required if is for an input type.

Coerces
B<from> a GraphQL entity,
B<to> a Perl entity of the required type,
or throws an exception.

=cut

has parse_value => (is => 'ro', isa => CodeRef);

=head1 METHODS

=head2 is_valid

True if given Perl entity is valid value for this type. Uses L</serialize>
attribute.

=cut

method is_valid(Any $item) :ReturnType(Bool) {
  return 1 if !defined $item;
  eval { $self->serialize->($item); 1 };
}

method graphql_to_perl(Any $item) :ReturnType(Any) {
  $self->parse_value->($item);
}

method perl_to_graphql(Any $item) :ReturnType(Any) {
  $self->serialize->($item);
}

method from_ast(
  HashRef $name2type,
  HashRef $ast_node,
) :ReturnType(InstanceOf[__PACKAGE__]) {
  DEBUG and _debug('Scalar.from_ast', $ast_node);
  $self->new(
    $self->_from_ast_named($ast_node),
    serialize => sub { require Carp; Carp::croak "Fake serialize called" },
    parse_value => sub { require Carp; Carp::croak "Fake parse_value called" },
  );
}

has to_doc => (is => 'lazy', isa => Str);
sub _build_to_doc {
  my ($self) = @_;
  DEBUG and _debug('Scalar.to_doc', $self);
  join '', map "$_\n",
    $self->_description_doc_lines($self->description),
    "scalar @{[$self->name]}";
}

=head1 EXPORTED VARIABLES

=head2 $Int

=cut

our $Int = GraphQL::Type::Scalar->new(
  name => 'Int',
  description =>
    'The `Int` scalar type represents non-fractional signed whole numeric ' .
    'values. Int can represent values between -(2^31) and 2^31 - 1.',
  serialize => sub { defined $_[0] and !is_Int32Signed($_[0]) and die "Not an Int.\n"; $_[0]+0 },
  parse_value => sub { defined $_[0] and !is_Int32Signed($_[0]) and die "Not an Int.\n"; $_[0]+0 },
);

=head2 $Float

=cut

our $Float = GraphQL::Type::Scalar->new(
  name => 'Float',
  description =>
    'The `Float` scalar type represents signed double-precision fractional ' .
    'values as specified by ' .
    '[IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).',
  serialize => sub { defined $_[0] and !is_Num($_[0]) and die "Not a Float.\n"; $_[0]+0 },
  parse_value => sub { defined $_[0] and !is_Num($_[0]) and die "Not a Float.\n"; $_[0]+0 },
);

=head2 $String

=cut

our $String = GraphQL::Type::Scalar->new(
  name => 'String',
  description =>
    'The `String` scalar type represents textual data, represented as UTF-8 ' .
    'character sequences. The String type is most often used by GraphQL to ' .
    'represent free-form human-readable text.',
  serialize => sub { defined $_[0] and !is_Str($_[0]) and die "Not a String.\n"; $_[0] },
  parse_value => sub { defined $_[0] and !is_Str($_[0]) and die "Not a String.\n"; $_[0] },
);

=head2 $Boolean

=cut

our $Boolean = GraphQL::Type::Scalar->new(
  name => 'Boolean',
  description =>
    'The `Boolean` scalar type represents `true` or `false`.',
  serialize => sub { defined $_[0] and !is_Bool($_[0]) and die "Not a Boolean.\n"; $_[0] ? JSON->true : JSON->false },
  parse_value => sub { defined $_[0] and !is_bool($_[0]) and die "Not a Boolean.\n"; $_[0]+0 },
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
  serialize => sub { defined $_[0] and Str->(@_); $_[0] },
  parse_value => sub { defined $_[0] and Str->(@_); $_[0] },
);

GraphQL::Plugin::Type->register($_) for ($Int, $Float, $String, $Boolean, $ID);

__PACKAGE__->meta->make_immutable();

1;
