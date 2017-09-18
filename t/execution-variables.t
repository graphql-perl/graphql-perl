#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS;
use Data::Dumper;

BEGIN {
  use_ok( 'GraphQL::Type::Scalar', qw($String) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::InputObject' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::List' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution' ) || print "Bail out!\n";
}

$Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
my $JSON = JSON::MaybeXS->new->allow_nonref->canonical;

my $TestComplexScalar = GraphQL::Type::Scalar->new(
  name => 'ComplexScalar',
  serialize => sub {
    return 'SerializedValue' if $_[0]//'' eq 'DeserializedValue';
    return;
  },
  parse_value => sub {
    return 'DeserializedValue' if $_[0]//'' eq 'SerializedValue';
    return;
  },
);

my $TestInputObject = GraphQL::Type::InputObject->new(
  name => 'TestInputObject',
  fields => {
    a => { type => $String },
    b => { type => GraphQL::Type::List->new(of => $String) },
    c => { type => $String->non_null },
    d => { type => $TestComplexScalar },
  },
);

my $TestNestedInputObject = GraphQL::Type::InputObject->new(
  name => 'Author',
  fields => {
    na => { type => $TestInputObject->non_null },
    nb => { type => $String->non_null },
  },
);

my $TestType = GraphQL::Type::Object->new(
  name => 'TestType',
  fields => {
    fieldWithObjectInput => {
      type => $String,
      args => { input => { type => $TestInputObject } },
      resolve => sub { $JSON->encode($_[1]->{input}) },
    },
    fieldWithNullableStringInput => {
      type => $String,
      args => { input => { type => $TestInputObject } },
      resolve => sub { $JSON->encode($_[1]->{input}) },
    },
    fieldWithNonNullableStringInput => {
      type => $String,
      args => { input => { type => $String->non_null } },
      resolve => sub { $JSON->encode($_[1]->{input}) },
    },
    fieldWithDefaultArgumentValue => {
      type => $String,
      args => { input => { type => $String->non_null, default_value => 'Hello World' } },
      resolve => sub { $JSON->encode($_[1]->{input}) },
    },
# XXX this looks like an error in execution/variables-test.js
#    fieldWithNestedInputObject => {
#      type => $String,
#      args => { input => { type => $TestNestedInputObject, default_value => 'Hello World' } },
#      resolve => sub { $JSON->encode($_[1]->{input}) },
#    },
    list => {
      type => $String,
      args => { input => { type => $String } },
      resolve => sub { $JSON->encode($_[1]->{input}) },
    },
    nnList => {
      type => $String,
      args => { input => { type => GraphQL::Type::List->new(of => $String)->non_null } },
      resolve => sub { $JSON->encode($_[1]->{input}) },
    },
    listNN => {
      type => $String,
      args => { input => { type => GraphQL::Type::List->new(of => $String->non_null) } },
      resolve => sub { $JSON->encode($_[1]->{input}) },
    },
    nnListNN => {
      type => $String,
      args => { input => { type => GraphQL::Type::List->new(of => $String->non_null)->non_null } },
      resolve => sub { $JSON->encode($_[1]->{input}) },
    },
  },
);

my $schema = GraphQL::Schema->new(query => $TestType);

subtest 'Handles objects and nullability', sub {
  subtest 'using inline structs', sub {
    subtest 'executes with complex input', sub {
      my $doc = '{
        fieldWithObjectInput(input: {a: "foo", b: ["bar"], c: "baz"})
      }';
      run_test(
        [$schema, $doc],
        { data => { fieldWithObjectInput => '{"a":"foo","b":["bar"],"c":"baz"}' } },
      );
    };

    subtest 'properly parses single value to list', sub {
      my $doc = '{
        fieldWithObjectInput(input: {a: "foo", b: "bar", c: "baz"})
      }';
      run_test(
        [$schema, $doc],
        { data => { fieldWithObjectInput => '{"a":"foo","b":["bar"],"c":"baz"}' } },
      );
    };

    subtest 'properly parses null value to null', sub {
      my $doc = '{
        fieldWithObjectInput(input: {a: null, b: null, c: "C", d: null})
      }';
      run_test(
        [$schema, $doc],
        { data => { fieldWithObjectInput => '{"a":null,"b":null,"c":"C","d":null}' } },
      );
    };
    done_testing;
  };
  done_testing;
};

done_testing;

sub run_test {
  my ($args, $expected) = @_;
  my $got = GraphQL::Execution->execute(@$args);
  is_deeply $got, $expected or diag Dumper $got;
}
