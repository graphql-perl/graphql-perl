package GraphQL::Directive;

use 5.014;
use strict;
use warnings;
use Moo;
use MooX::Thunking;
use Function::Parameters;
use GraphQL::Debug qw(_debug);
use Types::Standard -all;
use GraphQL::Type::Library -all;
use GraphQL::Type::Scalar qw($Boolean $String);
with qw(
  GraphQL::Role::Named
  GraphQL::Role::FieldsEither
);

our $VERSION = '0.02';
use constant DEBUG => $ENV{GRAPHQL_DEBUG};

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

has args => (is => 'thunked', isa => FieldMapInput, required => 1);

=head1 METHODS

=head2 from_ast

See L<GraphQL::Type/from_ast>.

=cut

method from_ast(
  HashRef $name2type,
  HashRef $ast_node,
) :ReturnType(InstanceOf[__PACKAGE__]) {
  DEBUG and _debug('Directive.from_ast', $ast_node);
  $self->new(
    $self->_from_ast_named($ast_node),
    locations => $ast_node->{locations},
    $self->_from_ast_fields($name2type, $ast_node, 'args'),
  );
}

has to_doc => (is => 'lazy', isa => Str);
sub _build_to_doc {
  my ($self) = @_;
  DEBUG and _debug('Directive.to_doc', $self);
  my @start = (
    ($self->description ? (map "# $_", split /\n/, $self->description) : ()),
    "directive \@@{[$self->name]}(",
  );
  my @argtuples = $self->_make_fieldtuples($self->args);
  DEBUG and _debug('Directive.to_doc(args)', \@argtuples);
  my $end = ") on " . join(' | ', @{$self->locations});
  return join("\n", @start).join(
    ', ', map $_->[0], @argtuples
  ).$end."\n" if !grep $_->[1], @argtuples; # no descriptions
  # if descriptions
  join '', map "$_\n",
    @start,
      (map {
        my ($main, @description) = @$_;
        (
          map "  $_", @description, $main,
        )
      } @argtuples),
    $end;
}

=head1 PACKAGE VARIABLES

=head2 $GraphQL::Directive::DEPRECATED

=cut

$GraphQL::Directive::DEPRECATED = GraphQL::Directive->new(
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
);

=head2 $GraphQL::Directive::INCLUDE

=cut

$GraphQL::Directive::INCLUDE = GraphQL::Directive->new(
  name => 'include',
  description => 'Directs the executor to include this field or fragment only when the `if` argument is true.',
  locations => [ qw(FIELD FRAGMENT_SPREAD INLINE_FRAGMENT) ],
  args => {
    if => {
      type => $Boolean->non_null,
      description => 'Included when true.',
    },
  },
);

=head2 $GraphQL::Directive::SKIP

=cut

$GraphQL::Directive::SKIP = GraphQL::Directive->new(
  name => 'skip',
  description => 'Directs the executor to skip this field or fragment when the `if` argument is true.',
  locations => [ qw(FIELD FRAGMENT_SPREAD INLINE_FRAGMENT) ],
  args => {
    if => {
      type => $Boolean->non_null,
      description => 'Skipped when true.',
    },
  },
);

=head2 @GraphQL::Directive::SPECIFIED_DIRECTIVES

Not exported. Contains the three GraphQL-specified directives: C<@skip>,
C<@include>, C<@deprecated>, each of which are available with the
variables above. Use if you want to have these plus your own directives
in your schema:

  my $schema = GraphQL::Schema->new(
    # ...
    directives => [ @GraphQL::Directive::SPECIFIED_DIRECTIVES, $my_directive ],
  );

=cut

@GraphQL::Directive::SPECIFIED_DIRECTIVES = (
  $GraphQL::Directive::INCLUDE,
  $GraphQL::Directive::SKIP,
  $GraphQL::Directive::DEPRECATED,
);

method _get_directive_values(
  HashRef $node,
  HashRef $variables,
) {
  DEBUG and _debug('_get_directive_values', $self->name, $node, $variables);
  my ($d) = grep $_->{name} eq $self->name, @{$node->{directives} || []};
  return if !$d;
  GraphQL::Execution::_get_argument_values($self, $d, $variables);
}

__PACKAGE__->meta->make_immutable();

1;
