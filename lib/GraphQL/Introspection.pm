package GraphQL::Introspection;

use 5.014;
use strict;
use warnings;
use Exporter 'import';
use GraphQL::Type::Object;
use GraphQL::Type::Enum;
use GraphQL::Type::Scalar qw($String $Boolean);
use GraphQL::Debug qw(_debug);
use JSON::MaybeXS;

=head1 NAME

GraphQL::Introspection - Perl implementation of GraphQL

=cut

our $VERSION = '0.02';

our @EXPORT_OK = qw(
  $QUERY
  $TYPE_KIND_META_TYPE
  $DIRECTIVE_LOCATION_META_TYPE
  $ENUM_VALUE_META_TYPE
  $INPUT_VALUE_META_TYPE
  $FIELD_META_TYPE
  $DIRECTIVE_META_TYPE
  $TYPE_META_TYPE
  $SCHEMA_META_TYPE
  $SCHEMA_META_FIELD_DEF
  $TYPE_META_FIELD_DEF
  $TYPE_NAME_META_FIELD_DEF
);

use constant DEBUG => $ENV{GRAPHQL_DEBUG};
my $JSON_noutf8 = JSON::MaybeXS->new->utf8(0)->allow_nonref;

=head1 SYNOPSIS

  use GraphQL::Introspection qw($QUERY);
  my $schema_data = execute($schema, $QUERY);

=head1 DESCRIPTION

Provides infrastructure implementing GraphQL's introspection.

=head1 EXPORT

=head2 $QUERY

The GraphQL query to introspect the schema.

=cut

our $QUERY = '
  query IntrospectionQuery {
    __schema {
      queryType { name }
      mutationType { name }
      subscriptionType { name }
      types {
        ...FullType
      }
      directives {
        name
        description
        locations
        args {
          ...InputValue
        }
      }
    }
  }
  fragment FullType on __Type {
    kind
    name
    description
    fields(includeDeprecated: true) {
      name
      description
      args {
        ...InputValue
      }
      type {
        ...TypeRef
      }
      isDeprecated
      deprecationReason
    }
    inputFields {
      ...InputValue
    }
    interfaces {
      ...TypeRef
    }
    enumValues(includeDeprecated: true) {
      name
      description
      isDeprecated
      deprecationReason
    }
    possibleTypes {
      ...TypeRef
    }
  }
  fragment InputValue on __InputValue {
    name
    description
    type { ...TypeRef }
    defaultValue
  }
  fragment TypeRef on __Type {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  kind
                  name
                }
              }
            }
          }
        }
      }
    }
  }
';

=head2 $TYPE_KIND_META_TYPE

The enum type describing kinds of type. The second-most-meta type here,
after C<$TYPE_META_TYPE> itself.

=cut

# TODO sort out is_introspection
our $TYPE_KIND_META_TYPE = GraphQL::Type::Enum->new(
  name => '__TypeKind',
  is_introspection => 1,
  description => 'An enum describing what kind of type a given `__Type` is.',
  values => {
    SCALAR => {
      description => 'Indicates this type is a scalar.'
    },
    OBJECT => {
      description => 'Indicates this type is an object. ' .
                   '`fields` and `interfaces` are valid fields.'
    },
    INTERFACE => {
      description => 'Indicates this type is an interface. ' .
                   '`fields` and `possibleTypes` are valid fields.'
    },
    UNION => {
      description => 'Indicates this type is a union. ' .
                   '`possibleTypes` is a valid field.'
    },
    ENUM => {
      description => 'Indicates this type is an enum. ' .
                   '`enumValues` is a valid field.'
    },
    INPUT_OBJECT => {
      description => 'Indicates this type is an input object. ' .
                   '`inputFields` is a valid field.'
    },
    LIST => {
      description => 'Indicates this type is a list. ' .
                   '`ofType` is a valid field.'
    },
    NON_NULL => {
      description => 'Indicates this type is a non-null. ' .
                   '`ofType` is a valid field.'
    },
  },
);

=head2 $DIRECTIVE_LOCATION_META_TYPE

The enum type describing directive locations.

=cut

# TODO sort out is_introspection
our $DIRECTIVE_LOCATION_META_TYPE = GraphQL::Type::Enum->new(
  name => '__DirectiveLocation',
  is_introspection => 1,
  description =>
    'A Directive can be adjacent to many parts of the GraphQL language, a ' .
    '__DirectiveLocation describes one such possible adjacencies.',
  values => {
    QUERY => {
      description => 'Location adjacent to a query operation.'
    },
    MUTATION => {
      description => 'Location adjacent to a mutation operation.'
    },
    SUBSCRIPTION => {
      description => 'Location adjacent to a subscription operation.'
    },
    FIELD => {
      description => 'Location adjacent to a field.'
    },
    FRAGMENT_DEFINITION => {
      description => 'Location adjacent to a fragment definition.'
    },
    FRAGMENT_SPREAD => {
      description => 'Location adjacent to a fragment spread.'
    },
    INLINE_FRAGMENT => {
      description => 'Location adjacent to an inline fragment.'
    },
    SCHEMA => {
      description => 'Location adjacent to a schema definition.'
    },
    SCALAR => {
      description => 'Location adjacent to a scalar definition.'
    },
    OBJECT => {
      description => 'Location adjacent to an object type definition.'
    },
    FIELD_DEFINITION => {
      description => 'Location adjacent to a field definition.'
    },
    ARGUMENT_DEFINITION => {
      description => 'Location adjacent to an argument definition.'
    },
    INTERFACE => {
      description => 'Location adjacent to an interface definition.'
    },
    UNION => {
      description => 'Location adjacent to a union definition.'
    },
    ENUM => {
      description => 'Location adjacent to an enum definition.'
    },
    ENUM_VALUE => {
      description => 'Location adjacent to an enum value definition.'
    },
    INPUT_OBJECT => {
      description => 'Location adjacent to an input object type definition.'
    },
    INPUT_FIELD_DEFINITION => {
      description => 'Location adjacent to an input object field definition.'
    },
  },
);

=head2 $ENUM_VALUE_META_TYPE

The type describing enum values.

=cut

# makes field-resolver that takes resolver args and calls Moo accessor
# returns field_def
sub _make_moo_field {
  my ($field_name, $type) = @_;
  ($field_name => { resolve => sub {
    my ($root_value, $args, $context, $info) = @_;
    my @passon = %$args ? ($args) : ();
    return undef unless $root_value->can($field_name);
    $root_value->$field_name(@passon);
  }, type => $type });
}

# makes field-resolver that takes resolver args and looks up "real" hash val
# returns field_def
sub _make_hash_bool_field {
  my ($field_name, $type, $real) = @_;
  ($field_name => { resolve => sub {
    my ($root_value, $args, $context, $info) = @_;
    !!$root_value->{$real};
  }, type => $type });
}

# makes field-resolver that takes resolver args and looks up "real" hash val
# returns field_def
sub _make_hash_field {
  my ($field_name, $type, $real) = @_;
  ($field_name => { resolve => sub {
    my ($root_value, $args, $context, $info) = @_;
    $root_value->{$real};
  }, type => $type });
}

# hash, returns array-ref of hashes with keys put in as 'name'
sub _hash2array {
  [ map { +{ name => $_, %{$_[0]->{$_}} } } sort keys %{$_[0]} ];
}

our $ENUM_VALUE_META_TYPE = GraphQL::Type::Object->new(
  name => '__EnumValue',
  is_introspection => 1,
  description =>
    'One possible value for a given Enum. Enum values are unique values, not ' .
    'a placeholder for a string or numeric value. However an Enum value is ' .
    'returned in a JSON response as a string.',
  fields => {
    name => { type => $String->non_null },
    description => { type => $String },
    _make_hash_bool_field(isDeprecated => $Boolean->non_null, 'isDeprecated'),
    _make_hash_field(deprecationReason => $String, 'deprecationReason'),
  },
);

=head2 $INPUT_VALUE_META_TYPE

The type describing input values.

=cut

our $TYPE_META_TYPE; # predeclare so available for thunk
our $INPUT_VALUE_META_TYPE = GraphQL::Type::Object->new(
  name => '__InputValue',
  is_introspection => 1,
  description =>
    'Arguments provided to Fields or Directives and the input fields of an ' .
    'InputObject are represented as Input Values which describe their type ' .
    'and optionally a default value.',
  fields => sub { {
    name => { type => $String->non_null },
    description => { type => $String },
    type => { type => $TYPE_META_TYPE->non_null },
    defaultValue => {
      type => $String,
      description =>
        'A GraphQL-formatted string representing the default value for this ' .
        'input value.',
      resolve => sub {
        DEBUG and _debug('__InputValue.defaultValue.resolve', @_);
        # must be JSON-encoded one time extra as buildClientSchema wants
        # it parseable as though literal in query - hence "GraphQL-formatted"
        return unless defined(my $value = $_[0]->{default_value});
        my $gql = $_[0]->{type}->perl_to_graphql($value);
        return $gql if $_[0]->{type}->isa('GraphQL::Type::Enum');
        $JSON_noutf8->encode($gql);
      },
    },
  } },
);

=head2 $FIELD_META_TYPE

The type describing fields.

=cut

our $FIELD_META_TYPE = GraphQL::Type::Object->new(
  name => '__Field',
  is_introspection => 1,
  description =>
    'Object and Interface types are described by a list of Fields, each of ' .
    'which has a name, potentially a list of arguments, and a return type.',
  fields => sub { {
    name => { type => $String->non_null },
    description => { type => $String },
    args => {
      type => $INPUT_VALUE_META_TYPE->non_null->list->non_null,
      resolve => sub { _hash2array($_[0]->{args}||{}) },
    },
    type => { type => $TYPE_META_TYPE->non_null },
    _make_hash_bool_field(isDeprecated => $Boolean->non_null, 'isDeprecated'),
    _make_hash_field(deprecationReason => $String, 'deprecationReason'),
  } },
);

=head2 $DIRECTIVE_META_TYPE

The type describing directives.

=cut

our $DIRECTIVE_META_TYPE = GraphQL::Type::Object->new(
  name => '__Directive',
  is_introspection => 1,
  description =>
    'A Directive provides a way to describe alternate runtime execution and ' .
    'type validation behavior in a GraphQL document.' .
    "\n\nIn some cases, you need to provide options to alter GraphQL's " .
    'execution behavior in ways field arguments will not suffice, such as ' .
    'conditionally including or skipping a field. Directives provide this by ' .
    'describing additional information to the executor.',
  fields => {
    _make_moo_field(name => $String->non_null),
    _make_moo_field(description => $String),
    _make_moo_field(locations => $DIRECTIVE_LOCATION_META_TYPE->non_null->list->non_null),
    args => {
      type => $INPUT_VALUE_META_TYPE->non_null->list->non_null,
      resolve => sub { _hash2array($_[0]->args) },
    },
    # NOTE onOperation onFragment onField not part of spec -> not implemented
  },
);

=head2 $TYPE_META_TYPE

The type describing a type. "Yo dawg..."

=cut

use constant CLASS2KIND => {
  'GraphQL::Type::Enum' => 'ENUM',
  'GraphQL::Type::Interface' => 'INTERFACE',
  'GraphQL::Type::List' => 'LIST',
  'GraphQL::Type::Object' => 'OBJECT',
  'GraphQL::Type::Union' => 'UNION',
  'GraphQL::Type::InputObject' => 'INPUT_OBJECT',
  'GraphQL::Type::NonNull' => 'NON_NULL',
  'GraphQL::Type::Scalar' => 'SCALAR',
};

$TYPE_META_TYPE = GraphQL::Type::Object->new(
  name => '__Type',
  is_introspection => 1, # and then some
  description =>
    'The fundamental unit of any GraphQL Schema is the type. There are ' .
    'many kinds of types in GraphQL as represented by the `__TypeKind` enum.' .
    "\n\nDepending on the kind of a type, certain fields describe " .
    'information about that type. Scalar types provide no information ' .
    'beyond a name and description, while Enum types provide their values. ' .
    'Object and Interface types provide the fields they describe. Abstract ' .
    'types, Union and Interface, provide the Object types possible ' .
    'at runtime. List and NonNull types compose other types.',
  fields => sub { {
    kind => {
      type => $TYPE_KIND_META_TYPE->non_null,
      resolve => sub { my $c = ref $_[0]; $c =~ s#__.*##; CLASS2KIND->{$c} // die "Unknown kind of type => ".ref $_[0] },
    },
    _make_moo_field(name => $String),
    _make_moo_field(description => $String),
    fields => {
      type => $FIELD_META_TYPE->non_null->list,
      args => { includeDeprecated => { type => $Boolean, default_value => 0 } },
      resolve => sub {
        my ($type, $args) = @_;
        return undef if !$type->DOES('GraphQL::Role::FieldsOutput');
        my $map = $type->fields;
        $map = {
          map { ($_ => $map->{$_}) } grep !$map->{$_}{deprecation_reason}, keys %$map
        } if !$args->{includeDeprecated};
        [ map { +{
          name => $_,
          description => $map->{$_}{description},
          args => $map->{$_}{args},
          type => $map->{$_}{type},
          isDeprecated => $map->{$_}{is_deprecated},
          deprecationReason => $map->{$_}{deprecation_reason},
        } } sort keys %{$map} ];
      }
    },
    interfaces => {
      type => $TYPE_META_TYPE->non_null->list,
      resolve => sub {
        my ($type) = @_;
        return if !$type->isa('GraphQL::Type::Object');
        $type->interfaces || [];
      }
    },
    possibleTypes => {
      type => $TYPE_META_TYPE->non_null->list,
      resolve => sub {
        return if !$_[0]->DOES('GraphQL::Role::Abstract');
        $_[3]->{schema}->get_possible_types($_[0]);
      },
    },
    enumValues => {
      type => $ENUM_VALUE_META_TYPE->non_null->list,
      args => {
        includeDeprecated => { type => $Boolean, default_value => 0 }
      },
      resolve => sub {
        my ($type, $args) = @_;
        return if !$type->isa('GraphQL::Type::Enum');
        my $values = $type->values;
        DEBUG and _debug('enumValues.resolve', $type, $args, $values);
        $values = { map { ($_ => $values->{$_}) } grep !$values->{$_}{is_deprecated}, keys %$values } if !$args->{includeDeprecated};
        [ map { +{
          name => $_,
          description => $values->{$_}{description},
          isDeprecated => $values->{$_}{is_deprecated},
          deprecationReason => $values->{$_}{deprecation_reason},
        } } sort keys %{$values} ];
      },
    },
    inputFields => {
      type => $INPUT_VALUE_META_TYPE->non_null->list,
      resolve => sub {
        my ($type) = @_;
        return if !$type->isa('GraphQL::Type::InputObject');
        _hash2array($type->fields || {});
      },
    },
    ofType => {
      type => $TYPE_META_TYPE,
      resolve => sub { return unless $_[0]->can('of'); $_[0]->of },
    },
  } },
);

=head2 $SCHEMA_META_TYPE

The type describing the schema itself.

=cut

our $SCHEMA_META_TYPE = GraphQL::Type::Object->new(
  name => '__Schema',
  is_introspection => 1,
  description =>
    'A GraphQL Schema defines the capabilities of a GraphQL server. It ' .
    'exposes all available types and directives on the server, as well as ' .
    'the entry points for query, mutation, and subscription operations.',
  fields => {
    types => {
      description => 'A list of all types supported by this server.',
      type => $TYPE_META_TYPE->non_null->list->non_null,
      resolve => sub { [ sort { $a->name cmp $b->name } values %{ $_[0]->name2type } ] },
    },
    queryType => {
      description => 'The type that query operations will be rooted at.',
      type => $TYPE_META_TYPE->non_null,
      resolve => sub { $_[0]->query },
    },
    mutationType => {
      description => 'If this server supports mutation, the type that ' .
                   'mutation operations will be rooted at.',
      type => $TYPE_META_TYPE,
      resolve => sub { $_[0]->mutation },
    },
    subscriptionType => {
      description => 'If this server support subscription, the type that ' .
                   'subscription operations will be rooted at.',
      type => $TYPE_META_TYPE,
      resolve => sub { $_[0]->subscription },
    },
    directives => {
      description => 'A list of all directives supported by this server.',
      type => $DIRECTIVE_META_TYPE->non_null->list->non_null,
      resolve => sub { $_[0]->directives },
    }
  },
);

=head2 $SCHEMA_META_FIELD_DEF

The meta-field existing on the top query.

=cut

our $SCHEMA_META_FIELD_DEF = {
  name => '__schema',
  type => $SCHEMA_META_TYPE->non_null,
  description => 'Access the current type schema of this server.',
  resolve => sub { $_[3]->{schema} }, # the $info
};

=head2 $TYPE_META_FIELD_DEF

The meta-field existing on the top query, describing a named type.

=cut

our $TYPE_META_FIELD_DEF = {
  name => '__type',
  type => $TYPE_META_TYPE,
  description => 'Request the type information of a single type.',
  args => { name => { type => $String->non_null } },
  resolve => sub { $_[3]->{schema}->name2type->{$_[1]->{name}} }, # the $args, $info
};

=head2 $TYPE_NAME_META_FIELD_DEF

The meta-field existing on each object field, naming its type.

=cut

our $TYPE_NAME_META_FIELD_DEF = {
  name => '__typename',
  type => $String->non_null,
  description => 'The name of the current Object type at runtime.',
  resolve => sub { $_[3]->{parent_type}->name }, # the $info
};

1;
