package GraphQL::Parser;

use 5.014;
use strict;
use warnings;
use base 'Pegex::Receiver';
use Return::Type;
use Types::Standard -all;
use Function::Parameters;
use JSON::MaybeXS;

require Pegex::Parser;
require GraphQL::Grammar;

my $JSON = JSON::MaybeXS->new->allow_nonref->canonical;

=head1 NAME

GraphQL::Parser - GraphQL language parser

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use GraphQL::Parser;
  my $parsed = GraphQL::Parser->parse(
    $source
  );

=head1 DESCRIPTION

Provides both an outside-accessible point of entry into the GraphQL
parser (see above), and a subclass of L<Pegex::Receiver> to turn Pegex
parsing events into data usable by GraphQL.

=head1 METHODS

=head2 parse

  GraphQL::Parser->parse($source, $noLocation);

=cut

method parse(Str $source, Bool $noLocation = undef) :ReturnType(ArrayRef) {
  my $parser = Pegex::Parser->new(
    grammar => GraphQL::Grammar->new,
    receiver => __PACKAGE__->new,
  );
  my $input = Pegex::Input->new(string => $source);
  return $parser->parse($input);
}

method gotrule (Any $param = undef) {
  return unless defined $param;
  return {$self->{parser}{rule} => $param};
}

method final (Any $param = undef) {
  return $param if defined $param;
  return {$self->{parser}{rule} => []};
}

fun _merge_hash (Any $param = undef) {
  my %def = map %$_, grep ref eq 'HASH', @$param;
  \%def;
}

method got_arguments (Any $param = undef) {
  return unless defined $param;
  $param = $param->[0]; # zap first useless layer
  my %args;
  for my $arg (@$param) {
    ($arg) = values %$arg; # zap useless layer
    my $name = shift(@$arg)->{name};
    $args{$name} = shift @$arg;
  }
  return {$self->{parser}{rule} => \%args};
}

method got_objectField (Any $param = undef) {
  return unless defined $param;
  my $name = shift(@$param)->{name};
  my $value = shift @$param;
  return {$name => $value};
}

method got_objectValue (Any $param = undef) {
  return unless defined $param;
  $param = $param->[0]; # zap first useless layer
  _merge_hash($param);
}

method got_objectField_const (Any $param = undef) {
  unshift @_, $self; goto &got_objectField;
}

method got_objectValue_const (Any $param = undef) {
  unshift @_, $self; goto &got_objectValue;
}

method got_listValue (Any $param = undef) {
  return unless defined $param;
  $param = $param->[0]; # zap first useless layer
  return $param;
}

method got_listValue_const (Any $param = undef) {
  unshift @_, $self; goto &got_listValue;
}

method got_directive (Any $param = undef) {
  return unless defined $param;
  return {$self->{parser}{rule} => _merge_hash($param) };
}

method got_inputValueDefinition (Any $param = undef) {
  return unless defined $param;
  my $def = _merge_hash($param);
  my $name = delete $def->{name};
  return { $name => $def };
}

method got_directiveLocations (Any $param = undef) {
  return unless defined $param;
  return {locations => [ map $_->{name}, @$param ]};
}

method got_namedType (Any $param = undef) {
  return unless defined $param;
  return $param->{name};
}

method got_scalarTypeDefinition (Any $param = undef) {
  return unless defined $param;
  return {kind => 'scalar', node => _merge_hash($param)};
}

method got_enumValueDefinition (Any $param = undef) {
  return unless defined $param;
  my %def;
  my $arg = shift @$param;
  $def{value} = $arg;
  while ($arg = shift @$param) {
    %def = (%def, %$arg);
  }
  return \%def;
}

method got_defaultValue (Any $param = undef) {
  return unless defined $param;
  return { default_value => $param->[0] };
}

method got_implementsInterfaces (Any $param = undef) {
  return unless defined $param;
  $param = $param->[0]; # zap first useless layer
  return { interfaces => $param };
}

method got_argumentsDefinition (Any $param = undef) {
  return unless defined $param;
  $param = $param->[0]; # zap first useless layer
  return { args => _merge_hash($param)};
}

method got_objectTypeDefinition (Any $param = undef) {
  return unless defined $param;
  my %def;
  %def = (%def, %{shift @$param}) while ref($param->[0]) eq 'HASH';
  my %fields = map %$_, @{shift @$param};
  $def{fields} = \%fields;
  return {kind => 'type', node => \%def};
}

method got_fieldDefinition (Any $param = undef) {
  return unless defined $param;
  my $def = _merge_hash($param);
  my $name = delete $def->{name};
  return { $name => $def };
}

method got_typeExtensionDefinition (Any $param = undef) {
  return unless defined $param;
  my $node = shift @$param;
  $node->{kind} = 'extend';
  return $node;
}

method got_inputObjectTypeDefinition (Any $param = undef) {
  return unless defined $param;
  my %def;
  %def = (%def, %{shift @$param}) while ref($param->[0]) eq 'HASH';
  my %fields = map %$_, @{shift @$param};
  $def{fields} = \%fields;
  return {kind => 'input', node => \%def};
}

method got_enumTypeDefinition (Any $param = undef) {
  return unless defined $param;
  my %def;
  %def = (%def, %{shift @$param}) while ref($param->[0]) eq 'HASH';
  my %values;
  map {
    my $name = ${${delete $_->{value}}};
    $values{$name} = $_;
  } @{shift @$param};
  $def{values} = \%values;
  return {kind => 'enum', node => \%def};
}

method got_interfaceTypeDefinition (Any $param = undef) {
  return unless defined $param;
  my %def;
  %def = (%def, %{shift @$param}) while ref($param->[0]) eq 'HASH';
  my %fields = map %$_, @{shift @$param};
  $def{fields} = \%fields;
  return {kind => 'interface', node => \%def};
}

method got_unionTypeDefinition (Any $param = undef) {
  return unless defined $param;
  return {kind => 'union', node => _merge_hash($param)};
}

method got_unionMembers (Any $param = undef) {
  return unless defined $param;
  return { types => $param };
}

method got_boolean (Any $param = undef) {
  return unless defined $param;
  return $param eq 'true' ? JSON->true : JSON->false;
}

method got_null (Any $param = undef) {
  return unless defined $param;
  return undef;
}

method got_string (Any $param = undef) {
  return unless defined $param;
  return $param;
}

method got_int (Any $param = undef) {
  $_[0] += 0; # numify. if modify $param gets dropped as is local copy
  unshift @_, $self; goto &got_string;
}

method got_float (Any $param = undef) {
  $_[0] += 0; # numify. if modify $param gets dropped as is local copy
  unshift @_, $self; goto &got_string;
}

method got_enumValue (Any $param = undef) {
  return unless defined $param;
  my $varname = $param->{name};
  return \\$varname;
}

# not returning empty list if undef
method got_value_const (Any $param = undef) {
  return $param;
}

method got_value (Any $param = undef) {
  unshift @_, $self; goto &got_value_const;
}

method got_variableDefinitions (Any $param = undef) {
  return unless defined $param;
  $param = $param->[0]; # zap first useless layer
  my %def;
  map {
    my $name = ${ shift @$_ };
    $def{$name} = { map %$_, @$_ }; # merge
  } map $_->{variableDefinition}, @$param;
  return {variables => \%def};
}

method got_selection (Any $param = undef) {
  unshift @_, $self; goto &got_value_const;
}

method got_type (Any $param = undef) {
  return unless defined $param;
  $param = $param->{name} if ref($param) eq 'HASH';
  return {$self->{parser}{rule} => $param};
}

method got_alias (Any $param = undef) {
  return unless defined $param;
  return {$self->{parser}{rule} => $param->[0]{name}};
}

method got_typeCondition (Any $param = undef) {
  return unless defined $param;
  return {on => $param->[0]};
}

method got_fragmentName (Any $param = undef) {
  return unless defined $param;
  return $param;
}

method got_field (Any $param = undef) {
  return unless defined $param;
  return {kind => 'field', node => _merge_hash($param)};
}

method got_inlineFragment (Any $param = undef) {
  return unless defined $param;
  return {kind => 'inline_fragment', node => _merge_hash($param)};
}

method got_fragment_spread (Any $param = undef) {
  return unless defined $param;
  return {kind => $self->{parser}{rule}, node => _merge_hash($param)};
}

method got_selectionSet (Any $param = undef) {
  return unless defined $param;
  $param = $param->[0]; # zap first useless layer
  return {selections => $param};
}

method got_fragmentDefinition (Any $param = undef) {
  return unless defined $param;
  return {kind => 'fragment', node => _merge_hash($param)};
}

method got_operationDefinition (Any $param = undef) {
  return unless defined $param;
  $param = [ $param ] unless ref $param eq 'ARRAY'; # bare selectionSet
  return {kind => 'operation', node => _merge_hash($param)};
}

method got_directiveDefinition (Any $param = undef) {
  return unless defined $param;
  return {kind => 'directive', node => _merge_hash($param)};
}

method got_directives (Any $param = undef) {
  return unless defined $param;
  return {$self->{parser}{rule} => [ map $_->{directive}, @$param ]};
}

method got_graphql (Any $param = undef) {
  return unless defined $param;
  return @$param;
}

method got_definition (Any $param = undef) {
  return unless defined $param;
  return @$param;
}

method got_operationTypeDefinition (Any $param = undef) {
  return unless defined $param;
  return { map { ref($_) ? values %$_ : $_ } @$param };
}

method got_schemaDefinition (Any $param = undef) {
  return unless defined $param;
  $param = $param->[0]; # zap first useless layer
  return {kind => 'schema', node => _merge_hash($param)};
}

method got_typeSystemDefinition (Any $param = undef) {
  return unless defined $param;
  return @$param;
}

method got_typeDefinition (Any $param = undef) {
  return unless defined $param;
  return $param;
}

method got_variable (Any $param = undef) {
  return unless defined $param;
  my $varname = $param->[0]{name};
  return \$varname;
}

method got_nonNullType (Any $param = undef) {
  return unless defined $param;
  $param = $param->[0]; # zap first useless layer
  $param = { type => $param } if ref $param ne 'HASH';
  return [ 'non_null', $param ];
}

method got_listType (Any $param = undef) {
  return unless defined $param;
  $param = $param->[0]; # zap first useless layer
  $param = { type => $param } if ref $param ne 'HASH';
  return [ 'list', $param ];
}

1;
