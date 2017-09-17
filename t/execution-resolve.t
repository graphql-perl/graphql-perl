#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON;
use Data::Dumper;

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Scalar', qw($String $Int) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution' ) || print "Bail out!\n";
}

$Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
my $JSON = JSON->new->allow_nonref;

sub make_schema {
  my ($field) = @_;
  GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Query',
      fields => { test => $field },
    ),
  );
}

subtest 'default function accesses properties', sub {
  my $schema = make_schema({ type => $String });
  my $root_value = { test => 'testvalue' };
  my $expected = { %$root_value }; # copy in case of mutations
  my $got = GraphQL::Execution->execute($schema, '{ test }', $root_value);
  is_deeply $got, {
    data => $expected,
  } or diag Dumper $got;
  done_testing;
};

done_testing;
