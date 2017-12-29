use lib 't/lib';
use GQLTest;

my $JSON = JSON::MaybeXS->new->allow_nonref->canonical;

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Scalar', qw($String $Int) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution', qw(execute) ) || print "Bail out!\n";
}

sub check {
  my ($test_type, $test_data, $expected) = @_;
  my $data = +{ test => $test_data };
  my $data_type;
  $data_type = GraphQL::Type::Object->new(
    name => 'DataType',
    fields => sub { +{
      test => { type => $test_type },
      nest => { type => $data_type, resolve => sub { $data } },
    } },
  );
  my $schema = GraphQL::Schema->new(query => $data_type);
  run_test([$schema, '{ nest { test } }', $data], $expected);
}

sub rsv { FakePromise->resolve(@_) }
sub rj { FakePromise->reject(@_) }

sub all_checks {
  my ($type, $expected) = @_;
  my %expected = %$expected;
  subtest 'Array<T>' => sub {
    subtest 'Contains values' => sub {
      check($type, [1, 2], $expected{contains_values});
    };
    subtest 'Contains null' => sub {
      check($type, [1, undef, 2], $expected{contains_null});
    };
    subtest 'Returns null' => sub {
      check($type, undef, $expected{returns_null});
    };
  };

  subtest 'Promise<Array<T>>' => sub {
    subtest 'Contains values' => sub {
      check($type, rsv([1, 2]), $expected{contains_values});
    };
    subtest 'Contains null' => sub {
      check($type, rsv([1, undef, 2]), $expected{contains_null});
    };
    subtest 'Returns null' => sub {
      check($type, rsv(undef), $expected{returns_null});
    };
    subtest 'Rejected' => sub {
      check($type, rj('bad'), $expected{rejected});
    };
  };

  subtest 'Array<Promise<T>>' => sub {
    subtest 'Contains values' => sub {
      check($type, [rsv(1), rsv(2)], $expected{contains_values});
    };
    subtest 'Contains null' => sub {
      check($type, [map rsv($_), 1, undef, 2], $expected{contains_null});
    };
    subtest 'Contains rejected' => sub {
      check($type, [rsv(1), rj('bad'), rsv(2)], $expected{contains_rejected});
    };
  };
}

my $data_ok = { nest => { test => [1, 2] } };
my $data_null_ok = { nest => { test => [1, undef, 2] } };
my $data_null0 = { nest => undef };
my $data_null1 = { nest => { test => undef } };
my $errors_null0 = [
  {
    message => 'Cannot return null for non-nullable field DataType.test.',
    locations => [{line=>1, column=>15}],
    path => [qw(nest test)],
  },
];
my $errors_null1 = [
  {
    message => 'Cannot return null for non-nullable field DataType.test.',
    locations => [{line=>1, column=>15}],
    path => [qw(nest test 1)],
  },
];
my $errors_bad0 = [
  { message => 'bad', locations => [{line=>1, column=>15}], path => [qw(nest test)] },
];
my $errors_bad1 = [
  { message => 'bad', locations => [{line=>1, column=>15}], path => [qw(nest test 1)] },
];

subtest '[T]' => sub {
  all_checks(
    $Int->list,
    {
      contains_values => { data => $data_ok },
      contains_null => { data => $data_null_ok },
      returns_null => { data => $data_null1 },
      rejected => { data => $data_null1, errors => $errors_bad0 },
      contains_rejected => { data => $data_null_ok, errors => $errors_bad1 },
    },
  );
};

subtest '[T]!' => sub {
  all_checks(
    $Int->list->non_null,
    {
      contains_values => { data => $data_ok },
      contains_null => { data => $data_null_ok },
      returns_null => { data => $data_null0, errors => $errors_null0 },
      rejected => { data => $data_null0, errors => $errors_bad0 },
      contains_rejected => { data => $data_null_ok, errors => $errors_bad1 },
    },
  );
};

subtest '[T!]' => sub {
  all_checks(
    $Int->non_null->list,
    {
      contains_values => { data => $data_ok },
      contains_null => { data => $data_null1, errors => $errors_null1 },
      returns_null => { data => $data_null1 },
      rejected => { data => $data_null1, errors => $errors_bad0 },
      contains_rejected => { data => $data_null1, errors => $errors_bad1 },
    },
  );
};

subtest '[T!]!' => sub {
  all_checks(
    $Int->non_null->list->non_null,
    {
      contains_values => { data => $data_ok },
      contains_null => { data => $data_null0, errors => $errors_null1 },
      returns_null => { data => $data_null0, errors => $errors_null0 },
      rejected => { data => $data_null0, errors => $errors_bad0 },
      contains_rejected => { data => $data_null0, errors => $errors_bad1 },
    },
  );
};

done_testing;
