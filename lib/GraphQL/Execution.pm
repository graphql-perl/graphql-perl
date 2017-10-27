package GraphQL::Execution;

use 5.014;
use strict;
use warnings;
use Return::Type;
use Types::Standard -all;
use Types::TypeTiny -all;
use GraphQL::Type::Library -all;
use Function::Parameters;
use GraphQL::Language::Parser qw(parse);
use GraphQL::Error;
use JSON::MaybeXS;
use GraphQL::Debug qw(_debug);
use GraphQL::Introspection qw(
  $SCHEMA_META_FIELD_DEF $TYPE_META_FIELD_DEF $TYPE_NAME_META_FIELD_DEF
);
use GraphQL::Directive;
use GraphQL::Schema qw(lookup_type);
use Exporter 'import';

=head1 NAME

GraphQL::Execution - Execute GraphQL queries

=cut

our @EXPORT_OK = qw(
  execute
);
our $VERSION = '0.02';

my $JSON = JSON::MaybeXS->new->allow_nonref;
use constant DEBUG => $ENV{GRAPHQL_DEBUG}; # "DEBUG and" gets optimised out if false

=head1 SYNOPSIS

  use GraphQL::Execution qw(execute);
  my $result = execute($schema, $doc, $root_value);

=head1 DESCRIPTION

Executes a GraphQL query, returns results.

=head1 METHODS

=head2 execute

  my $result = execute(
    $schema,
    $doc, # can also be AST
    $root_value,
    $context_value,
    $variable_values,
    $operation_name,
    $field_resolver,
  );

=cut

fun execute(
  (InstanceOf['GraphQL::Schema']) $schema,
  Str | ArrayRef[HashRef] $doc,
  Any $root_value = undef,
  Any $context_value = undef,
  Maybe[HashRef] $variable_values = undef,
  Maybe[Str] $operation_name = undef,
  Maybe[CodeLike] $field_resolver = undef,
) :ReturnType(HashRef) {
  my $context = eval {
    my $ast = ref($doc) ? $doc : parse($doc);
    _build_context(
      $schema,
      $ast,
      $root_value,
      $context_value,
      $variable_values,
      $operation_name,
      $field_resolver,
    );
  };
  return { errors => [ GraphQL::Error->coerce($@)->to_json ] } if $@;
  (my $result, $context) = eval {
    _execute_operation(
      $context,
      $context->{operation},
      $root_value,
    );
  };
  $context = _context_error($context, GraphQL::Error->coerce($@)) if $@;
  my $wrapped = { data => $result };
  if (@{ $context->{errors} || [] }) {
    return { errors => [ map $_->to_json, @{$context->{errors}} ], %$wrapped };
  } else {
    return $wrapped;
  }
}

fun _context_error(
  HashRef $context,
  Any $error,
) :ReturnType(HashRef) {
  # like push but no mutation
  +{ %$context, errors => [ @{$context->{errors} || []}, $error ] };
}

fun _build_context(
  (InstanceOf['GraphQL::Schema']) $schema,
  ArrayRef[HashRef] $ast,
  Any $root_value,
  Any $context_value,
  Maybe[HashRef] $variable_values,
  Maybe[Str] $operation_name,
  Maybe[CodeLike] $field_resolver,
) :ReturnType(HashRef) {
  my %fragments = map {
    ($_->{name} => $_)
  } grep $_->{kind} eq 'fragment', @$ast;
  my @operations = grep $_->{kind} eq 'operation', @$ast;
  die "No operations supplied.\n" if !@operations;
  die "Can only execute document containing fragments or operations\n"
    if @$ast != keys(%fragments) + @operations;
  my $operation = _get_operation($operation_name, \@operations);
  {
    schema => $schema,
    fragments => \%fragments,
    root_value => $root_value,
    context_value => $context_value,
    operation => $operation,
    variable_values => _variables_apply_defaults(
      $schema,
      $operation->{variables} || {},
      $variable_values || {},
    ),
    field_resolver => $field_resolver || \&_default_field_resolver,
    errors => [],
  };
}

# takes each operation var: query q(a: String)
#  applies to it supplied variable from web request
#  if none, applies any defaults in the operation var: query q(a: String = "h")
#  converts with graphql_to_perl (which also validates) to Perl values
# return { varname => { value => ..., type => $type } }
fun _variables_apply_defaults(
  (InstanceOf['GraphQL::Schema']) $schema,
  HashRef $operation_variables,
  HashRef $variable_values,
) :ReturnType(HashRef) {
  my @bad = grep {
    ! lookup_type($operation_variables->{$_}, $schema->name2type)->DOES('GraphQL::Role::Input');
  } keys %$operation_variables;
  die "Variable '\$$bad[0]' is type '@{[
    lookup_type($operation_variables->{$bad[0]}, $schema->name2type)->to_string
  ]}' which cannot be used as an input type.\n" if @bad;
  +{ map {
    my $opvar = $operation_variables->{$_};
    my $opvar_type = lookup_type($opvar, $schema->name2type);
    my $parsed_value;
    my $maybe_value = $variable_values->{$_} // $opvar->{default_value};
    eval { $parsed_value = $opvar_type->graphql_to_perl($maybe_value) };
    die "Variable '\$$_' got invalid value @{[$JSON->canonical->encode($maybe_value)]}.\n$@"
      if $@;
    ($_ => { value => $parsed_value, type => $opvar_type })
  } keys %$operation_variables };
}

fun _get_operation(
  Maybe[Str] $operation_name,
  ArrayRef[HashRef] $operations,
) {
  DEBUG and _debug('_get_operation', @_);
  if (!$operation_name) {
    die "Must provide operation name if query contains multiple operations.\n"
      if @$operations > 1;
    return $operations->[0];
  }
  my @matching = grep $_->{name} eq $operation_name, @$operations;
  return $matching[0] if @matching == 1;
  die "No operations matching '$operation_name' found.\n";
}

fun _execute_operation(
  HashRef $context,
  HashRef $operation,
  Any $root_value,
) {
  my $op_type = $operation->{operationType} || 'query';
  my $type = $context->{schema}->$op_type;
  my ($fields) = _collect_fields(
    $context,
    $type,
    $operation->{selections},
    {},
    {},
  );
  my $path = [];
  my $execute = $op_type eq 'mutation'
    ? \&_execute_fields_serially : \&_execute_fields;
  (my $result, $context) = eval {
    $execute->($context, $type, $root_value, $path, $fields);
  };
  return ({}, _context_error($context, GraphQL::Error->coerce($@))) if $@;
  ($result, $context);
}

fun _collect_fields(
  HashRef $context,
  (InstanceOf['GraphQL::Type']) $runtime_type,
  ArrayRef $selections,
  Map[StrNameValid,ArrayRef[HashRef]] $fields_got,
  Map[StrNameValid,Bool] $visited_fragments,
) {
  DEBUG and _debug('_collect_fields', $runtime_type->to_string, $fields_got, $selections);
  for my $selection (@$selections) {
    my $node = $selection;
    next if !_should_include_node($context->{variable_values}, $node);
    if ($selection->{kind} eq 'field') {
      my $use_name = $node->{alias} || $node->{name};
      $fields_got = {
        %$fields_got,
        $use_name => [ @{$fields_got->{$use_name} || []}, $node ],
      }; # like push but no mutation
    } elsif ($selection->{kind} eq 'inline_fragment') {
      next if !_fragment_condition_match($context, $node, $runtime_type);
      ($fields_got, $visited_fragments) = _collect_fields(
        $context,
        $runtime_type,
        $node->{selections},
        $fields_got,
        $visited_fragments,
      );
    } elsif ($selection->{kind} eq 'fragment_spread') {
      my $frag_name = $node->{name};
      next if $visited_fragments->{$frag_name};
      $visited_fragments = { %$visited_fragments, $frag_name => 1 }; # !mutate
      my $fragment = $context->{fragments}{$frag_name};
      next if !$fragment;
      next if !_fragment_condition_match($context, $fragment, $runtime_type);
      DEBUG and _debug('_collect_fields(fragment_spread)', $fragment);
      ($fields_got, $visited_fragments) = _collect_fields(
        $context,
        $runtime_type,
        $fragment->{selections},
        $fields_got,
        $visited_fragments,
      );
    }
  }
  ($fields_got, $visited_fragments);
}

fun _should_include_node(
  HashRef $variables,
  HashRef $node,
) :ReturnType(Bool) {
  DEBUG and _debug('_should_include_node', $variables, $node);
  my $skip = _get_directive_values($GraphQL::Directive::SKIP, $node, $variables);
  return '' if $skip and $skip->{if};
  my $include = _get_directive_values($GraphQL::Directive::INCLUDE, $node, $variables);
  return '' if $include and !$include->{if};
  1;
}

fun _get_directive_values(
  (InstanceOf['GraphQL::Directive']) $directive,
  HashRef $node,
  HashRef $variables,
) {
  DEBUG and _debug('_get_directive_values', $directive->name, $node, $variables);
  my ($d) = grep $_->{name} eq $directive->name, @{$node->{directives} || []};
  return if !$d;
  _get_argument_values($directive, $d, $variables);
}

fun _fragment_condition_match(
  HashRef $context,
  HashRef $node,
  (InstanceOf['GraphQL::Type']) $runtime_type,
) :ReturnType(Bool) {
  DEBUG and _debug('_fragment_condition_match', $runtime_type->to_string, $node);
  return 1 if !$node->{on};
  return 1 if $node->{on} eq $runtime_type->name;
  my $condition_type = $context->{schema}->name2type->{$node->{on}} //
    die GraphQL::Error->new(
      message => "Unknown type for fragment condition '$node->{on}'."
    );
  return '' if !$condition_type->DOES('GraphQL::Role::Abstract');
  $context->{schema}->is_possible_type($condition_type, $runtime_type);
}

fun _execute_fields(
  HashRef $context,
  (InstanceOf['GraphQL::Type']) $parent_type,
  Any $root_value,
  ArrayRef $path,
  Map[StrNameValid,ArrayRef[HashRef]] $fields,
) :ReturnType(Map[StrNameValid,Any]){
  my %results;
  DEBUG and _debug('_execute_fields', $parent_type->to_string, $fields, $root_value);
  map {
    my $result_name = $_;
    my $result;
    eval {
      ($result, $context) = _resolve_field(
        $context,
        $parent_type,
        $root_value,
        [ @$path, $result_name ],
        $fields->{$result_name},
      );
    };
    if ($@) {
      $context = _context_error(
        $context,
        _located_error($@, $fields->{$result_name}, [ @$path, $result_name ])
      );
    } else {
      $results{$result_name} = $result;
      # TODO promise stuff
    }
  } keys %$fields; # TODO ordering of fields
  (\%results, $context);
}

fun _execute_fields_serially(
  HashRef $context,
  (InstanceOf['GraphQL::Type']) $parent_type,
  Any $root_value,
  ArrayRef $path,
  Map[StrNameValid,ArrayRef[HashRef]] $fields,
) {
  DEBUG and _debug('_execute_fields_serially', $parent_type->to_string, $fields, $root_value);
  # TODO implement
  goto &_execute_fields;
}

# NB same ordering as _execute_fields - graphql-js switches last 2
fun _resolve_field(
  HashRef $context,
  (InstanceOf['GraphQL::Type']) $parent_type,
  Any $root_value,
  ArrayRef $path,
  ArrayRef[HashRef] $nodes,
) {
  my $field_node = $nodes->[0];
  my $field_name = $field_node->{name};
  DEBUG and _debug('_resolve_field', $parent_type->to_string, $nodes, $root_value);
  my $field_def = _get_field_def($context->{schema}, $parent_type, $field_name);
  my $resolve = $field_def->{resolve} || $context->{field_resolver};
  my $info = _build_resolve_info(
    $context,
    $parent_type,
    $field_def,
    $path,
    $nodes,
  );
  my $result = _resolve_field_value_or_error(
    $context,
    $field_def,
    $nodes,
    $resolve,
    $root_value,
    $info,
  );
  _complete_value_catching_error(
    $context,
    $field_def->{type},
    $nodes,
    $info,
    $path,
    $result,
  );
}

use constant FIELDNAME2SPECIAL => {
  map { ($_->{name} => $_) } $SCHEMA_META_FIELD_DEF, $TYPE_META_FIELD_DEF
};
fun _get_field_def(
  (InstanceOf['GraphQL::Schema']) $schema,
  (InstanceOf['GraphQL::Type']) $parent_type,
  StrNameValid $field_name,
) :ReturnType(HashRef) {
  return $TYPE_NAME_META_FIELD_DEF
    if $field_name eq $TYPE_NAME_META_FIELD_DEF->{name};
  return FIELDNAME2SPECIAL->{$field_name}
    if FIELDNAME2SPECIAL->{$field_name} and $parent_type == $schema->query;
  $parent_type->fields->{$field_name} //
    die GraphQL::Error->new(
      message => "No field @{[$parent_type->name]}.$field_name."
    );
}

# NB similar ordering as _execute_fields - graphql-js switches
fun _build_resolve_info(
  HashRef $context,
  (InstanceOf['GraphQL::Type']) $parent_type,
  HashRef $field_def,
  ArrayRef $path,
  ArrayRef[HashRef] $nodes,
) {
  {
    field_name => $nodes->[0]{name},
    field_nodes => $nodes,
    return_type => $field_def->{type},
    parent_type => $parent_type,
    path => $path,
    schema => $context->{schema},
    fragments => $context->{fragments},
    root_value => $context->{root_value},
    operation => $context->{operation},
    variable_values => $context->{variable_values},
  };
}

fun _resolve_field_value_or_error(
  HashRef $context,
  HashRef $field_def,
  ArrayRef[HashRef] $nodes,
  Maybe[CodeLike] $resolve,
  Maybe[Any] $root_value,
  HashRef $info,
) {
  DEBUG and _debug('_resolve_field_value_or_error', $nodes, $root_value, $field_def, eval { $JSON->encode($nodes->[0]) });
  my $result = eval {
    my $args = _get_argument_values($field_def, $nodes->[0], $context->{variable_values});
    DEBUG and _debug("_resolve_field_value_or_error(resolve)", $args, $JSON->encode($args));
    $resolve->($root_value, $args, $context->{context_value}, $info);
  };
  return GraphQL::Error->coerce($@) if $@;
  $result;
}

fun _complete_value_catching_error(
  HashRef $context,
  (InstanceOf['GraphQL::Type']) $return_type,
  ArrayRef[HashRef] $nodes,
  HashRef $info,
  ArrayRef $path,
  Any $result,
) {
  if ($return_type->isa('GraphQL::Type::NonNull')) {
    return _complete_value_with_located_error(@_);
  }
  my $result = eval {
    (my $completed, $context) = _complete_value_with_located_error(@_);
    # TODO promise stuff
    $completed;
  };
  return (undef, _context_error($context, GraphQL::Error->coerce($@))) if $@;
  ($result, $context);
}

fun _complete_value_with_located_error(
  HashRef $context,
  (InstanceOf['GraphQL::Type']) $return_type,
  ArrayRef[HashRef] $nodes,
  HashRef $info,
  ArrayRef $path,
  Any $result,
) {
  my $result = eval {
    (my $completed, $context) = _complete_value(@_);
    # TODO promise stuff
    $completed;
  };
  die _located_error($@, $nodes, $path) if $@;
  ($result, $context);
}

fun _complete_value(
  HashRef $context,
  (InstanceOf['GraphQL::Type']) $return_type,
  ArrayRef[HashRef] $nodes,
  HashRef $info,
  ArrayRef $path,
  Any $result,
) {
  DEBUG and _debug('_complete_value', $return_type->to_string, $result);
  # TODO promise stuff
  die $result if GraphQL::Error->is($result);
  if ($return_type->isa('GraphQL::Type::NonNull')) {
    (my $completed, $context) = _complete_value(
      $context,
      $return_type->of,
      $nodes,
      $info,
      $path,
      $result,
    );
    die GraphQL::Error->new(
      message => "Cannot return null for non-nullable field @{[$info->{parent_type}->name]}.@{[$info->{field_name}]}."
    ) if !defined $completed;
    return ($completed, $context);
  }
  return ($result, $context) if !defined $result;
  return _complete_list_value(@_) if $return_type->isa('GraphQL::Type::List');
  return (_complete_leaf_value($return_type, $result), $context)
    if $return_type->DOES('GraphQL::Role::Leaf');
  return _complete_abstract_value(@_) if $return_type->DOES('GraphQL::Role::Abstract');
  return _complete_object_value(@_) if $return_type->isa('GraphQL::Type::Object');
  # shouldn't get here
  die GraphQL::Error->new(
    message => "Cannot complete value of unexpected type '@{[$return_type->to_string]}'."
  );
}

fun _complete_list_value(
  HashRef $context,
  (InstanceOf['GraphQL::Type::List']) $return_type,
  ArrayRef[HashRef] $nodes,
  HashRef $info,
  ArrayRef $path,
  ArrayRef $result,
) {
  # TODO promise stuff
  my $item_type = $return_type->of;
  my $index = 0;
  my @completed_results = map {
    (my $r, $context) = _complete_value_catching_error(
      $context,
      $item_type,
      $nodes,
      $info,
      [ @$path, $index++ ],
      $_,
    );
    $r;
  } @$result;
  (\@completed_results, $context);
}

fun _complete_leaf_value(
  (ConsumerOf['GraphQL::Role::Leaf']) $return_type,
  Any $result,
) {
  DEBUG and _debug('_complete_leaf_value', $return_type->to_string, $result);
  my $serialised = $return_type->perl_to_graphql($result);
  die GraphQL::Error->new(message => "Expected a value of type '@{[$return_type->to_string]}' but received: '$result'.\n$@") if $@;
  $serialised;
}

fun _complete_abstract_value(
  HashRef $context,
  (ConsumerOf['GraphQL::Role::Abstract']) $return_type,
  ArrayRef[HashRef] $nodes,
  HashRef $info,
  ArrayRef $path,
  Any $result,
) {
  my $runtime_type = ($return_type->resolve_type || \&_default_resolve_type)->(
    $result, $context->{context_value}, $info, $return_type
  );
  # TODO promise stuff
  _complete_object_value(
    $context,
    _ensure_valid_runtime_type(
      $runtime_type,
      $context,
      $return_type,
      $nodes,
      $info,
      $result,
    ),
    $nodes,
    $info,
    $path,
    $result,
  );
}

fun _ensure_valid_runtime_type(
  (Str | InstanceOf['GraphQL::Type::Object']) $runtime_type_or_name,
  HashRef $context,
  (ConsumerOf['GraphQL::Role::Abstract']) $return_type,
  ArrayRef[HashRef] $nodes,
  HashRef $info,
  Any $result,
) :ReturnType(InstanceOf['GraphQL::Type::Object']) {
  my $runtime_type = is_InstanceOf($runtime_type_or_name)
    ? $runtime_type_or_name
    : $context->{schema}->name2type->{$runtime_type_or_name};
  die GraphQL::Error->new(
    message => "Abstract type @{[$return_type->name]} must resolve to an " .
      "Object type at runtime for field @{[$info->{parent_type}->name]}." .
      "@{[$info->{field_name}]} with value $result, received '@{[$runtime_type->name]}'.",
    nodes => [ $nodes ],
  ) if !$runtime_type->isa('GraphQL::Type::Object');
  die GraphQL::Error->new(
    message => "Runtime Object type '@{[$runtime_type->name]}' is not a possible type for " .
      "'@{[$return_type->name]}'.",
    nodes => [ $nodes ],
  ) if !$context->{schema}->is_possible_type($return_type, $runtime_type);
  $runtime_type;
}

fun _default_resolve_type(
  Any $value,
  Any $context,
  HashRef $info,
  (ConsumerOf['GraphQL::Role::Abstract']) $abstract_type,
) {
  my @possibles = @{ $info->{schema}->get_possible_types($abstract_type) };
  # TODO promise stuff
  (grep $_->is_type_of->($value, $context, $info), grep $_->is_type_of, @possibles)[0];
}

fun _complete_object_value(
  HashRef $context,
  (InstanceOf['GraphQL::Type::Object']) $return_type,
  ArrayRef[HashRef] $nodes,
  HashRef $info,
  ArrayRef $path,
  Any $result,
) {
  if ($return_type->is_type_of) {
    my $is_type_of = $return_type->is_type_of->($result, $context->{context_value}, $info);
    # TODO promise stuff
    die GraphQL::Error->new(message => "Expected a value of type '@{[$return_type->to_string]}' but received: '@{[ref($result)||$result]}'.") if !$is_type_of;
  }
  _collect_and_execute_subfields(
    $context,
    $return_type,
    $nodes,
    $info,
    $path,
    $result,
  );
}

fun _collect_and_execute_subfields(
  HashRef $context,
  (InstanceOf['GraphQL::Type::Object']) $return_type,
  ArrayRef[HashRef] $nodes,
  HashRef $info,
  ArrayRef $path,
  Any $result,
) {
  my $subfield_nodes = {};
  my $visited_fragment_names = {};
  for (grep $_->{selections}, @$nodes) {
    ($subfield_nodes, $visited_fragment_names) = _collect_fields(
      $context,
      $return_type,
      $_->{selections},
      $subfield_nodes,
      $visited_fragment_names,
    );
  }
  DEBUG and _debug('_collect_and_execute_subfields', $return_type->to_string, $subfield_nodes, $result);
  _execute_fields($context, $return_type, $result, $path, $subfield_nodes);
}

fun _located_error(
  Any $error,
  ArrayRef[HashRef] $nodes,
  ArrayRef $path,
) {
  GraphQL::Error->coerce($error)->but(
    locations => [ map $_->{location}, @$nodes ],
    path => $path,
  );
}

fun _get_argument_values(
  (HashRef | InstanceOf['GraphQL::Directive']) $def,
  HashRef $node,
  Maybe[HashRef] $variable_values = {},
) {
  my $arg_defs = $def->{args};
  my $arg_nodes = $node->{arguments};
  DEBUG and _debug("_get_argument_values", $arg_defs, $arg_nodes, $variable_values, eval { $JSON->encode($node) });
  return {} if !$arg_defs;
  my @bad = grep { !exists $arg_nodes->{$_} and !defined $arg_defs->{$_}{default_value} and $arg_defs->{$_}{type}->isa('GraphQL::Type::NonNull') } keys %$arg_defs;
  die GraphQL::Error->new(
    message => "Argument '$bad[0]' of type ".
      "'@{[$arg_defs->{$bad[0]}{type}->to_string]}' not given.",
    nodes => [ $node ],
  ) if @bad;
  @bad = grep {
    ref($arg_nodes->{$_}) eq 'SCALAR' and
    $variable_values->{${$arg_nodes->{$_}}} and
    !_type_will_accept($arg_defs->{$_}{type}, $variable_values->{${$arg_nodes->{$_}}}{type})
  } keys %$arg_defs;
  die GraphQL::Error->new(
    message => "Variable '\$${$arg_nodes->{$bad[0]}}' of type '@{[$variable_values->{${$arg_nodes->{$bad[0]}}}{type}->to_string]}'".
      " where expected '@{[$arg_defs->{$bad[0]}{type}->to_string]}'.",
    nodes => [ $node ],
  ) if @bad;
  my @novar = grep {
    ref($arg_nodes->{$_}) eq 'SCALAR' and
    (!$variable_values or !exists $variable_values->{${$arg_nodes->{$_}}}) and
    !defined $arg_defs->{$_}{default_value} and
    $arg_defs->{$_}{type}->isa('GraphQL::Type::NonNull')
  } keys %$arg_defs;
  die GraphQL::Error->new(
    message => "Argument '$novar[0]' of type ".
      "'@{[$arg_defs->{$novar[0]}{type}->to_string]}'".
      " was given variable '\$${$arg_nodes->{$novar[0]}}' but no runtime value.",
    nodes => [ $node ],
  ) if @novar;
  my @enumfail = grep {
    ref($arg_nodes->{$_}) eq 'REF' and
    ref(${$arg_nodes->{$_}}) eq 'SCALAR' and
    !$arg_defs->{$_}{type}->isa('GraphQL::Type::Enum')
  } keys %$arg_defs;
  die GraphQL::Error->new(
    message => "Argument '$enumfail[0]' of type ".
      "'@{[$arg_defs->{$enumfail[0]}{type}->to_string]}'".
      " was given ${${$arg_nodes->{$enumfail[0]}}} which is enum value.",
    nodes => [ $node ],
  ) if @enumfail;
  my @enumstring = grep {
    defined($arg_nodes->{$_}) and
    !ref($arg_nodes->{$_})
  } grep $arg_defs->{$_}{type}->isa('GraphQL::Type::Enum'), keys %$arg_defs;
  die GraphQL::Error->new(
    message => "Argument '$enumstring[0]' of type ".
      "'@{[$arg_defs->{$enumstring[0]}{type}->to_string]}'".
      " was given '$arg_nodes->{$enumstring[0]}' which is not enum value.",
    nodes => [ $node ],
  ) if @enumstring;
  return {} if !$arg_nodes;
  my %coerced_values;
  for my $name (keys %$arg_defs) {
    my $arg_def = $arg_defs->{$name};
    my $arg_type = $arg_def->{type};
    my $argument_node = $arg_nodes->{$name};
    my $default_value = $arg_def->{default_value};
    DEBUG and _debug("_get_argument_values($name)", $arg_def, $arg_type, $argument_node, $default_value);
    if (!exists $arg_nodes->{$name}) {
      # none given - apply type arg's default if any. already validated perl
      $coerced_values{$name} = $default_value if exists $arg_def->{default_value};
      next;
    } elsif (ref($argument_node) eq 'SCALAR') {
      # scalar ref means it's a variable. already validated perl
      $coerced_values{$name} =
        ($variable_values && $variable_values->{$$argument_node} && $variable_values->{$$argument_node}{value})
        // $default_value;
      next;
    } elsif (ref($argument_node) eq 'REF') {
      # double ref means it's an enum value. JSON land, needs convert/validate
      $coerced_values{$name} = $$$argument_node;
    } else {
      # query literal. JSON land, needs convert/validate
      $coerced_values{$name} = $argument_node;
    }
    next if !exists $coerced_values{$name};
    DEBUG and _debug("_get_argument_values($name after initial)", $arg_def, $arg_type, $argument_node, $default_value, $JSON->encode(\%coerced_values));
    eval { $coerced_values{$name} = $arg_type->graphql_to_perl($coerced_values{$name}) };
    DEBUG and _debug("_get_argument_values($name after coerce)", $JSON->encode(\%coerced_values));
    if ($@) {
      die GraphQL::Error->new(
        message => "Argument '$name' got invalid value"
          . " @{[$JSON->encode($coerced_values{$name})]}.\nExpected '"
          . $arg_type->to_string . "'.",
        nodes => [ $node ],
      );
    }
  }
  \%coerced_values;
}

fun _type_will_accept(
  (ConsumerOf['GraphQL::Role::Input']) $arg_type,
  (ConsumerOf['GraphQL::Role::Input']) $var_type,
) {
  return 1 if $arg_type == $var_type;
  $arg_type = $arg_type->of if $arg_type->isa('GraphQL::Type::NonNull');
  $var_type = $var_type->of if $var_type->isa('GraphQL::Type::NonNull');
  return 1 if $arg_type == $var_type;
  '';
}

# $root_value is either a hash with fieldnames as keys and either data
#   or coderefs as values
# OR it's just a coderef itself
# OR it's an object which gets tried for fieldname as method
# any code gets called with obvious args
fun _default_field_resolver(
  CodeLike | HashRef | InstanceOf $root_value,
  HashRef $args,
  Any $context,
  HashRef $info,
) {
  my $field_name = $info->{field_name};
  my $property = is_HashRef($root_value)
    ? $root_value->{$field_name}
    : $root_value;
  DEBUG and _debug('_default_field_resolver', $root_value, $field_name, $args, $property);
  if (eval { CodeLike->($property); 1 }) {
    DEBUG and _debug('_default_field_resolver', 'codelike');
    return $property->($args, $context, $info);
  }
  if (is_InstanceOf($root_value) and $root_value->can($field_name)) {
    DEBUG and _debug('_default_field_resolver', 'method');
    return $root_value->$field_name($args, $context, $info);
  }
  $property;
}

1;
