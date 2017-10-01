package GraphQL::Directive;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard -all;
use GraphQL::Type::Library -all;
use GraphQL::Type::Scalar qw($Boolean $String);
with qw(GraphQL::Role::Named);

our $VERSION = '0.02';

my @LOCATIONS = qw(
  QUERY
  MUTATION
  SUBSCRIPTION
  FIELD
  FRAGMENT_DEFINITION
  FRAGMENT_SPREAD
  INLINE_FRAGMENT
  SCHEMA
  SCALAR
  OBJECT
  FIELD_DEFINITION
  ARGUMENT_DEFINITION
  INTERFACE
  UNION
  ENUM
  ENUM_VALUE
  INPUT_OBJECT
  INPUT_FIELD_DEFINITION
);

=head1 NAME

GraphQL::Directive - GraphQL directive

=head1 SYNOPSIS

  use GraphQL::Directive;
  my $directive = GraphQL::Directive->new(
    name => 'Object',
    interfaces => [ $interfaceType ],
    fields => { field_name => { type => $scalar_type, resolve => sub { '' } }},
  );

=head1 ATTRIBUTES

Has C<name>, C<description> from L<GraphQL::Role::Named>.

=head2 locations

Array-ref of locations where the directive can occur. Must be one of
these strings:

  QUERY
  MUTATION
  SUBSCRIPTION
  FIELD
  FRAGMENT_DEFINITION
  FRAGMENT_SPREAD
  INLINE_FRAGMENT
  SCHEMA
  SCALAR
  OBJECT
  FIELD_DEFINITION
  ARGUMENT_DEFINITION
  INTERFACE
  UNION
  ENUM
  ENUM_VALUE
  INPUT_OBJECT
  INPUT_FIELD_DEFINITION

=cut

has locations => (is => 'ro', isa => ArrayRef[Enum[@LOCATIONS]], required => 1);

=head2 args

Hash-ref of arguments. See L<GraphQL::Type::Library/FieldMapInput>.

=cut

has args => (is => 'ro', isa => FieldMapInput, required => 1);

__PACKAGE__->meta->make_immutable();

=head1 PACKAGE VARIABLES

=head2 @GraphQL::Directive::SPECIFIED_DIRECTIVES

Not exported. Contains the three GraphQL-specified directives: C<@skip>,
C<@if>, C<@deprecated>. Use if you want to have these plus your own
directives in your schema:

  my $schema = GraphQL::Schema->new(
    # ...
    directives => [ @GraphQL::Directive::SPECIFIED_DIRECTIVES, $my_directive ],
  );

=cut

@GraphQL::Directive::SPECIFIED_DIRECTIVES = (
  GraphQL::Directive->new(
    name => 'include',
    description => 'Directs the executor to include this field or fragment only when the `if` argument is true.',
    locations => [ qw(FIELD FRAGMENT_SPREAD INLINE_FRAGMENT) ],
    args => {
      if => {
        type => $Boolean->non_null,
        description => 'Included when true.',
      },
    },
  ),
  GraphQL::Directive->new(
    name => 'skip',
    description => 'Directs the executor to skip this field or fragment when the `if` argument is true.',
    locations => [ qw(FIELD FRAGMENT_SPREAD INLINE_FRAGMENT) ],
    args => {
      if => {
        type => $Boolean->non_null,
        description => 'Skipped when true.',
      },
    },
  ),
  GraphQL::Directive->new(
    name => 'deprecated',
    description => 'Marks an element of a GraphQL schema as no longer supported.',
    locations => [ qw(FIELD_DEFINITION ENUM_VALUE) ],
    args => {
      reason => {
        type => $String,
        description =>
          'Explains why this element was deprecated, usually also including ' .
          'a suggestion for how to access supported similar data. Formatted ' .
          'in [Markdown](https://daringfireball.net/projects/markdown/).',
        default_value => 'No longer supported',
      },
    },
  ),
);

1;
