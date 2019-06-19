#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use GraphQL::Schema;
use GraphQL::Execution 'execute';
use GraphQL::Debug '_debug';

ok my $doc = q<
  directive @length(max: Int) on FIELD_DEFINITION | INPUT_FIELD_DEFINITION
  directive @note(msg: Str) on SCHEMA | SCALAR | OBJECT | FIELD_DEFINITION 
    | ARGUMENT_DEFINITION | INTERFACE | UNION | ENUM | ENUM_VALUE
    | INPUT_OBJECT | INPUT_FIELD_DEFINITION

  type Todo {
    task: String! @length(max: 15)
  }

  type Query {
    todos: [Todo]
  }

  type Mutation @length(max: 15) {
    add_todo(task: String! @length(max: 15)): Todo
  }

  schema @note(msg: "Test") {
    query: Query
    mutation: Mutation
  }

>;

ok my $schema = GraphQL::Schema->from_doc($doc);

my @data = (
  {task => 'Exercise!'},
  {task => 'Bulk Milk'},
  {task => 'Walk Dogs'},
);

my %root_value = (
  todos => sub {
    return \@data;
  },
  add_todo => sub {
    _debug "adasdasdsdasdasdasdasd" x 10;
    my ($args, $context, $info) = @_;
    push @data, $args;
    return $args;
  }
);

my $q = q<
  mutation {
    add_todo(task: "milk1") { task }
  }
>;

ok execute($schema, $q, \%root_value);

done_testing;
