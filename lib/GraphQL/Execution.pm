package GraphQL::Execution;

use 5.014;
use strict;
use warnings;
use Return::Type;
use Types::Standard -all;
use Types::TypeTiny -all;
use GraphQL::Type::Library -all;
use Function::Parameters;
use GraphQL::Parser;
use GraphQL::Error;
use JSON::MaybeXS;

=head1 NAME

GraphQL::Execution - Execute GraphQL queries

=cut

our $VERSION = '0.02';

my $JSON = JSON::MaybeXS->new->allow_nonref;

=head1 SYNOPSIS

  use GraphQL::Execution;
  my $result = GraphQL::Execution->execute($schema, $doc, $root_value);

=head1 DESCRIPTION

Executes a GraphQL query, returns results.

=head1 METHODS

=head2 execute

  my $result = GraphQL::Execution->execute(
    $schema,
    $doc,
    $root_value,
    $context_value,
    $variable_values,
    $operation_name,
    $field_resolver,
  );

=cut

method execute(
  (InstanceOf['GraphQL::Schema']) $schema,
  Str $doc,
  Any $root_value = undef,
  Any $context_value = undef,
  Maybe[HashRef] $variable_values = undef,
  Maybe[Str] $operation_name = undef,
  Maybe[CodeLike] $field_resolver = undef,
) :ReturnType(HashRef) {
  my $ast = GraphQL::Parser->parse($doc);
  my $context = eval {
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
  return { errors => [ $@ ] } if $@;
  my $result = eval {
    scalar _execute_operation(
      $context,
      $context->{operation},
      $root_value,
    );
  };
  if ($@) {
    push @{ $context->{errors} }, GraphQL::Error->coerce($@); # TODO no mutate $context
  }
  my $wrapped = { data => $result };
  if (@{ $context->{errors} }) {
    return { errors => [ map $_->to_string, @{$context->{errors}} ], %$wrapped };
  } else {
    return $wrapped;
  }
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
  } map $_->{node}, grep $_->{kind} eq 'fragment', @$ast;
  my @operations = grep $_->{kind} eq 'operation', @$ast;
  die "No operations supplied." if !@operations;
  die "Can only execute document containing fragments or operations"
    if @$ast != keys(%fragments) + @operations;
  my $operation = _get_operation($operation_name, \@operations);
  {
    schema => $schema,
    fragments => \%fragments,
    root_value => $root_value,
    context_value => $context_value,
    operation => $operation->{node},
    variable_values => _variables_apply_defaults(
      $schema,
      $operation->{node}{variables} || {},
      $variable_values || {},
    ),
    field_resolver => $field_resolver || \&_default_field_resolver,
    errors => [],
  };
}

fun _variables_apply_defaults(
  (InstanceOf['GraphQL::Schema']) $schema,
  HashRef $operation_variables,
  HashRef $variable_values,
) :ReturnType(HashRef) {
  my %new_values;
  map {
    my $opvar = $operation_variables->{$_};
    my $opvar_type = $schema->name2type->{$opvar->{type}};
    my $parsed_value;
    my $maybe_value = $variable_values->{$_} // $opvar->{default_value};
    eval { $parsed_value = $opvar_type->graphql_to_perl($maybe_value) };
    die "Variable '\$$_' got invalid value @{[$JSON->canonical->encode($maybe_value)]}.\n$@"
      if $@;
    $new_values{$_} = $parsed_value;
  } keys %$operation_variables;
  \%new_values;
}

sub _get_operation {
  my ($operation_name, $operations) = @_;
  my $operation;
  if (!$operation_name) {
    die "Must provide operation name if query contains multiple operations."
      if @$operations > 1;
    return $operations->[0];
  }
  my @matching = grep $_->{name} eq $operation_name, @$operations;
  return $matching[0] if @matching == 1;
  die "No operations matching '$operation_name' found.";
}

fun _execute_operation(
  HashRef $context,
  HashRef $operation,
  Any $root_value,
) :ReturnType(HashRef) {
  my $op_type = $operation->{operationType} || 'query';
  my $type = $context->{schema}->$op_type;
  my $fields = _collect_fields(
    $context,
    $type,
    $operation->{selections},
    {},
    {},
  );
  my $path = [];
  my $execute = $op_type eq 'mutation'
    ? \&_execute_fields_serially : \&_execute_fields;
  my $result = eval {
    $execute->($context, $type, $root_value, $path, $fields);
  };
  if ($@) {
    push @{ $context->{errors} }, GraphQL::Error->coerce($@); # TODO no mutate $context
    return {};
  }
  $result;
}

fun _collect_fields(
  HashRef $context,
  (InstanceOf['GraphQL::Type']) $runtime_type,
  ArrayRef $selections,
  Map[StrNameValid,ArrayRef[HashRef]] $fields_got,
  Map[StrNameValid,Bool] $visited_fragments,
) :ReturnType(Map[StrNameValid,ArrayRef[HashRef]]) {
  for my $selection (@$selections) {
    my $node = $selection->{node};
    next if !_should_include_node($context, $node);
    if ($selection->{kind} eq 'field') {
      # TODO no mutate $fields_got
      my $use_name = $node->{alias} || $node->{name};
      push @{ $fields_got->{$use_name} }, $node;
    } elsif ($selection->{kind} eq 'inline_fragment') {
      next if !_fragment_condition_match($context, $node, $runtime_type);
      _collect_fields(
        $context,
        $runtime_type,
        $node->{selections},
        $fields_got,
        $visited_fragments,
      );
    } elsif ($selection->{kind} eq 'fragment_spread') {
      my $frag_name = $node->{name};
      next if $visited_fragments->{$frag_name};
      $visited_fragments->{$frag_name} = 1;
      my $fragment = $context->{fragments}{$frag_name};
      next if !$fragment;
      next if !_fragment_condition_match($context, $fragment, $runtime_type);
      _collect_fields(
        $context,
        $runtime_type,
        $node->{selections},
        $fields_got,
        $visited_fragments,
      );
    }
  }
  $fields_got;
}

fun _should_include_node(
  HashRef $context,
  HashRef $node,
) :ReturnType(Bool) {
  # TODO implement
  1;
}

fun _fragment_condition_match(
  HashRef $context,
  HashRef $node,
  (InstanceOf['GraphQL::Type']) $runtime_type,
) :ReturnType(Bool) {
  # TODO implement
  1;
}

fun _execute_fields(
  HashRef $context,
  (InstanceOf['GraphQL::Type']) $parent_type,
  Any $root_value,
  ArrayRef $path,
  Map[StrNameValid,ArrayRef[HashRef]] $fields,
) :ReturnType(Map[StrNameValid,Any]){
  my %results;
  map {
    my $result_name = $_;
    my $result = _resolve_field(
      $context,
      $parent_type,
      $root_value,
      [ @$path, $result_name ],
      $fields->{$_},
    );
    $results{$result_name} = $result;
    # TODO promise stuff
  } keys %$fields; # TODO ordering of fields
  \%results;
}

fun _execute_fields_serially(
  HashRef $context,
  (InstanceOf['GraphQL::Type']) $parent_type,
  Any $root_value,
  ArrayRef $path,
  Map[StrNameValid,ArrayRef[HashRef]] $fields,
) {
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
  my $field_def = _get_field_def($context->{schema}, $parent_type, $field_name);
  return if !$field_def;
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

fun _get_field_def(
  (InstanceOf['GraphQL::Schema']) $schema,
  (InstanceOf['GraphQL::Type']) $parent_type,
  StrNameValid $field_name,
) :ReturnType(HashRef) {
  # TODO __schema and __typename and __type
  $parent_type->fields->{$field_name};
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
  my $result = eval {
    my $args = _get_argument_values($field_def, $nodes->[0], $context->{variable_values});
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
    my $completed = _complete_value_with_located_error(@_);
    # TODO promise stuff
    $completed;
  };
  if ($@) {
    push @{ $context->{errors} }, GraphQL::Error->coerce($@);
    return undef; # null value
  }
  $result;
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
    my $completed = _complete_value(@_);
    # TODO promise stuff
    $completed;
  };
  if ($@) {
    die _located_error($@, $nodes, $path);
  }
  $result;
}

fun _complete_value(
  HashRef $context,
  (InstanceOf['GraphQL::Type']) $return_type,
  ArrayRef[HashRef] $nodes,
  HashRef $info,
  ArrayRef $path,
  Any $result,
) {
  # TODO promise stuff
  die $result if GraphQL::Error->is($result);
  return $result if !defined $result;
  # TODO handle list
  # TODO handle leaf
  # TODO handle abstract
  # TODO handle object
  if ($return_type->isa('GraphQL::Type::NonNull')) {
  }
  $result;
}

fun _located_error(
  Any $error,
  ArrayRef[HashRef] $nodes,
  ArrayRef $path,
) {
  # TODO implement
  GraphQL::Error->coerce($error);
}

fun _get_argument_values(
  HashRef $def,
  HashRef $node,
  Maybe[HashRef] $variable_values = {},
) {
  my $arg_defs = $def->{args};
  my $arg_nodes = $node->{arguments};
  return {} if !$arg_defs or !$arg_nodes;
  my @bad = grep !exists $arg_nodes->{$_} and !defined $arg_defs->{$_}{default_value} and $arg_defs->{$_}{type}->isa('GraphQL::Type::NonNull'), keys %$arg_defs;
  die GraphQL::Error->new(
    message => "Argument '$bad[0]' of type ".
      "'@{[$arg_defs->{$bad[0]}{type}->to_string]}' not given.",
    nodes => [ $node ],
  ) if @bad;
  my @novar = grep
    ref($arg_nodes->{$_}||'') eq 'SCALAR' and
    (!$variable_values or !exists $variable_values->{${$arg_nodes->{$_}}}) and
    !defined $arg_defs->{$_}{default_value} and
    $arg_defs->{$_}{type}->isa('GraphQL::Type::NonNull'), keys %$arg_defs;
  die GraphQL::Error->new(
    message => "Argument '$novar[0]' of type ".
      "'@{[$arg_defs->{$bad[0]}{type}->to_string]}'".
      " was given variable '\$${$arg_nodes->{$novar[0]}}' but no runtime value.",
    nodes => [ $node ],
  ) if @novar;
  my %coerced_values;
  for my $name (keys %$arg_defs) {
    my $arg_def = $arg_defs->{$name};
    my $arg_type = $arg_def->{type};
    my $argument_node = $arg_nodes->{$name};
    my $default_value = $arg_def->{default_value};
    if (!exists $arg_nodes->{$name}) {
      $coerced_values{$name} = $default_value if exists $arg_def->{default_value};
    } elsif (ref($argument_node) eq 'SCALAR') {
      # scalar ref means it's a variable
      $coerced_values{$name} =
        ($variable_values && $variable_values->{$$argument_node})
        // $default_value;
    } else {
      $coerced_values{$name} = $argument_node;
    }
    next if !exists $coerced_values{$name};
    eval { $coerced_values{$name} = $arg_type->graphql_to_perl($coerced_values{$name}) };
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

# $root_value is either a hash with fieldnames as keys and either data
#   or coderefs as values
# OR it's just a coderef itself
# OR it's an object which gets tried for fieldname as method
# any code gets called with obvious args
fun _default_field_resolver(
  CodeLike | HashRef | InstanceOf $root_value,
  HashRef $args,
  Maybe[HashRef] $context,
  HashRef $info,
) {
  my $field_name = $info->{field_name};
  my $property = is_HashRef($root_value)
    ? $root_value->{$field_name}
    : $root_value;
  if (eval { CodeLike->($property); 1 }) {
    return $property->($args, $context, $info);
  }
  if (is_InstanceOf($root_value) and $root_value->can($field_name)) {
    return $root_value->$field_name($args, $context, $info);
  }
  $property;
}

1;
