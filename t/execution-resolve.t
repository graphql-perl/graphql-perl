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

subtest 'default function calls methods', sub {
  my $schema = make_schema({ type => $String });
  use constant SECRETVAL => 'secretValue';
  {
    package MyTest1;
    sub new { bless { _secret => ::SECRETVAL }, shift; }
    sub test { shift->{_secret} }
  }
  my $root_value = MyTest1->new;
  is $root_value->test, SECRETVAL; # fingers and toes
  my $got = GraphQL::Execution->execute($schema, '{ test }', $root_value);
  is_deeply $got, {
    data => { test => SECRETVAL },
  } or diag Dumper $got;
  done_testing;
};

subtest 'default function passes args and context', sub {
  my $schema = make_schema({
    type => $Int,
    args => { addend1 => { type => $Int } },
  });
  {
    package Adder;
    sub new { bless { _num => $_[1] }, $_[0]; }
    sub test { shift->{_num} + shift->{addend1} + shift->{addend2} }
  }
  my $root_value = Adder->new(700);
  is $root_value->test({ addend1 => 80 }, { addend2 => 9 }), 789;
  my $got = GraphQL::Execution->execute(
    $schema, '{ test(addend1: 80) }', $root_value, { addend2 => 9 },
  );
  is_deeply $got, {
    data => { test => 789 },
  } or diag Dumper $got;
  done_testing;
};

done_testing;
