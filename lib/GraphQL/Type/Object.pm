package GraphQL::Type::Object;

use 5.014;
use strict;
use warnings;
use Moo;
use GraphQL::Debug qw(_debug);
use Types::Standard -all;
use GraphQL::Type::Library -all;
use MooX::Thunking;
use GraphQL::MaybeTypeCheck;
extends qw(GraphQL::Type);
with qw(
  GraphQL::Role::Output
  GraphQL::Role::Composite
  GraphQL::Role::Nullable
  GraphQL::Role::Named
  GraphQL::Role::FieldsOutput
  GraphQL::Role::HashMappable
);

our $VERSION = '0.02';
use constant DEBUG => $ENV{GRAPHQL_DEBUG};

=head1 NAME

GraphQL::Type::Object - GraphQL object type

=head1 SYNOPSIS

  use GraphQL::Type::Object;
  my $interface_type;
  my $implementing_type = GraphQL::Type::Object->new(
    name => 'Object',
    interfaces => [ $interface_type ],
    fields => { field_name => { type => $scalar_type, resolve => sub { '' } }},
  );

=head1 ATTRIBUTES

Has C<name>, C<description> from L<GraphQL::Role::Named>.
Has C<fields> from L<GraphQL::Role::FieldsOutput>.

=head2 interfaces

Optional, thunked array-ref of interface type objects implemented.

=cut

has interfaces => (is => 'thunked', isa => ArrayRef[InstanceOf['GraphQL::Type::Interface']]);

=head2 is_type_of

Optional code-ref. Input is a value, an execution context hash-ref,
and resolve-info hash-ref.

=cut

has is_type_of => (is => 'ro', isa => CodeRef);

method graphql_to_perl(Maybe[HashRef] $item) :ReturnType(Maybe[HashRef]) {
  return $item if !defined $item;
  $item = $self->uplift($item);
  my $fields = $self->fields;
  $self->hashmap($item, $fields, sub {
    my ($key, $value) = @_;
    $fields->{$key}{type}->graphql_to_perl(
      $value // $fields->{$key}{default_value}
    );
  });
}

has to_doc => (is => 'lazy', isa => Str);
sub _build_to_doc {
  my ($self) = @_;
  DEBUG and _debug('Object.to_doc', $self);
  my @fieldlines = map {
    my ($main, @description) = @$_;
    (
      @description,
      $main,
    )
  } $self->_make_fieldtuples($self->fields);
  my $implements = join ' & ', map $_->name, @{ $self->interfaces || [] };
  $implements &&= 'implements ' . $implements . ' ';
  join '', map "$_\n",
    $self->_description_doc_lines($self->description),
    "type @{[$self->name]} $implements\{",
      (map length() ? "  $_" : "", @fieldlines),
    "}";
}

method from_ast(
  HashRef $name2type,
  HashRef $ast_node,
) :ReturnType(InstanceOf[__PACKAGE__]) {
  $self->new(
    $self->_from_ast_named($ast_node),
    $self->_from_ast_maptype($name2type, $ast_node, 'interfaces'),
    $self->_from_ast_fields($name2type, $ast_node, 'fields'),
  );
}

method _collect_fields(
  HashRef $context,
  ArrayRef $selections,
  FieldsGot $fields_got,
  Map[StrNameValid,Bool] $visited_fragments,
) {
  DEBUG and _debug('_collect_fields', $self->to_string, $fields_got, $selections);
  for my $selection (@$selections) {
    my $node = $selection;
    next if !_should_include_node($context->{variable_values}, $node);
    if ($selection->{kind} eq 'field') {
      my $use_name = $node->{alias} || $node->{name};
      my ($field_names, $nodes_defs) = @$fields_got;
      $field_names = [ @$field_names, $use_name ] if !exists $nodes_defs->{$use_name};
      $nodes_defs = {
        %$nodes_defs,
        $use_name => [ @{$nodes_defs->{$use_name} || []}, $node ],
      };
      $fields_got = [ $field_names, $nodes_defs ]; # no mutation
    } elsif ($selection->{kind} eq 'inline_fragment') {
      next if !$self->_fragment_condition_match($context, $node);
      ($fields_got, $visited_fragments) = $self->_collect_fields(
        $context,
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
      next if !$self->_fragment_condition_match($context, $fragment);
      DEBUG and _debug('_collect_fields(fragment_spread)', $fragment);
      ($fields_got, $visited_fragments) = $self->_collect_fields(
        $context,
        $fragment->{selections},
        $fields_got,
        $visited_fragments,
      );
    }
  }
  ($fields_got, $visited_fragments);
}

method _fragment_condition_match(
  HashRef $context,
  HashRef $node,
) :ReturnType(Bool) {
  DEBUG and _debug('_fragment_condition_match', $self->to_string, $node);
  return 1 if !$node->{on};
  return 1 if $node->{on} eq $self->name;
  my $condition_type = $context->{schema}->name2type->{$node->{on}} //
    die GraphQL::Error->new(
      message => "Unknown type for fragment condition '$node->{on}'."
    );
  return '' if !$condition_type->DOES('GraphQL::Role::Abstract');
  $context->{schema}->is_possible_type($condition_type, $self);
}

fun _should_include_node(
  HashRef $variables,
  HashRef $node,
) :ReturnType(Bool) {
  DEBUG and _debug('_should_include_node', $variables, $node);
  my $skip = $GraphQL::Directive::SKIP->_get_directive_values($node, $variables);
  return '' if $skip and $skip->{if};
  my $include = $GraphQL::Directive::INCLUDE->_get_directive_values($node, $variables);
  return '' if $include and !$include->{if};
  1;
}

method _complete_value(
  HashRef $context,
  ArrayRef[HashRef] $nodes,
  HashRef $info,
  ArrayRef $path,
  Any $result,
) {
  if ($self->is_type_of) {
    my $is_type_of = $self->is_type_of->($result, $context->{context_value}, $info);
    # TODO promise stuff
    die GraphQL::Error->new(message => "Expected a value of type '@{[$self->to_string]}' but received: '@{[ref($result)||$result]}'.") if !$is_type_of;
  }
  my $subfield_nodes = [[], {}];
  my $visited_fragment_names = {};
  for (grep $_->{selections}, @$nodes) {
    ($subfield_nodes, $visited_fragment_names) = $self->_collect_fields(
      $context,
      $_->{selections},
      $subfield_nodes,
      $visited_fragment_names,
    );
  }
  DEBUG and _debug('Object._complete_value', $self->to_string, $subfield_nodes, $result);
  GraphQL::Execution::_execute_fields($context, $self, $result, $path, $subfield_nodes);
}

__PACKAGE__->meta->make_immutable();

1;
