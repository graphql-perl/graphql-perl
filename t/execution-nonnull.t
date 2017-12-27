use lib 't/lib';
use GQLTest;

my $JSON = JSON::MaybeXS->new->allow_nonref->canonical;

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Scalar', qw($String $Int) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution', qw(execute) ) || print "Bail out!\n";
}

my $throwing_data;
$throwing_data = {
  sync => sub { die "error\n" },
  promise => sub { FakePromise->resolve("error\n")->then(sub { die shift }) },
  syncNonNull => sub { die "nonNullError\n" },
  promiseNonNull => sub { FakePromise->resolve("nonNullError\n")->then(sub { die shift }) },
  syncNest => sub { $throwing_data },
  promiseNest => sub { FakePromise->resolve($throwing_data) },
  syncNonNullNest => sub { $throwing_data },
  promiseNonNullNest => sub { FakePromise->resolve($throwing_data) },
};

my $nulling_data;
$nulling_data = {
  sync => sub { undef },
  promise => sub { FakePromise->resolve(undef) },
  syncNonNull => sub { undef },
  promiseNonNull => sub { FakePromise->resolve(undef) },
  syncNest => sub { $nulling_data },
  promiseNest => sub { FakePromise->resolve($nulling_data) },
  syncNonNullNest => sub { $nulling_data },
  promiseNonNullNest => sub { FakePromise->resolve($nulling_data) },
};

my $data_type;
$data_type = GraphQL::Type::Object->new(
  name => 'DataType',
  fields => sub { +{
    sync => { type => $String },
    promise => { type => $String },
    syncNonNull => { type => $String->non_null },
    promiseNonNull => { type => $String->non_null },
    syncNest => { type => $data_type },
    promiseNest => { type => $data_type },
    syncNonNullNest => { type => $data_type->non_null },
    promiseNonNullNest => { type => $data_type->non_null },
  } },
);
my $schema = GraphQL::Schema->new(query => $data_type);

# sync_only does not touch *Nest
sub check {
  my ($doc, $sync_only, $expected_return, $expected_throw) = @_;
  my @descs = ([
    {
      doc => $doc,
      words => 'returns null',
      data => $nulling_data,
      expected => $expected_return,
      sync => 'synchronously',
    },
    {
      doc => $doc,
      words => 'throws',
      data => $throwing_data,
      expected => +{ %$expected_return, %$expected_throw },
      sync => 'synchronously',
    },
  ]);
  # if (!$sync_only)
  for my $d (@descs) {
    for my $d2 (@$d) {
      subtest "$d2->{words} $d2->{sync}" => sub {
        run_test([$schema, $d2->{doc}, $d2->{data}], $d2->{expected});
      };
    }
  }
}

subtest 'nulls a nullable field' => sub {
  check('query Q { sync }', 0, {
    data => { sync => undef },
  },
  {
    errors => [
      {
        message => "error\n",
        locations => [{ line=>1, column=>16 }],
        path => [qw(sync)],
      }
    ],
  });
};

subtest 'nulls a synchronously returned object that contains a non-nullable field' => sub {
  check('query Q { syncNest { syncNonNull } }', 0, {
    data => { syncNest => undef },
    errors => [
      {
        message =>
          'Cannot return null for non-nullable field DataType.syncNonNull.',
        locations => [{ line => 1, column => 34 }],
        path => [qw(syncNest syncNonNull)],
      },
    ],
  },
  {
    errors => [
      {
        message => "nonNullError\n",
        locations => [{ line=>1, column=>34 }],
        path => [qw(syncNest syncNonNull)],
      }
    ],
  });
};

#subtest 'nulls an object returned in a promise that contains a non-nullable field' => sub {
#  check('query Q { promiseNest { syncNonNull } }', 0, {
#    data => { promiseNest => undef },
#    errors => [
#      {
#        message =>
#          'Cannot return null for non-nullable field DataType.syncNonNull.',
#        locations => [{ line => 8, column => 19 }],
#        path => [qw(syncNest syncNonNullNest promiseNonNullNest
#          syncNonNullNest promiseNonNullNest syncNonNull)],
#      },
#    },
#  },
#  {
#    errors => [
#      {
#        message => "nonNullError\n",
#        locations => [{ line=>1, column=>23 }],
#        path => [qw(promiseNest syncNonNull)],
#      }
#    ],
#  });
#};

subtest 'nulls a complex tree of nullable fields' => sub {
  my $doc = <<'EOF';
query Q {
  syncNest {
    sync
#    promise
    syncNest {
      sync
#      promise
    }
#    promiseNest {
#      sync
#      promise
#    }
  }
#  promiseNest {
#    sync
#    promise
#    syncNest {
#      sync
#      promise
#    }
#    promiseNest {
#      sync
#      promise
#    }
#  }
}
EOF
  check($doc, 1, {
    data => {
      syncNest => {
        sync => undef,
#        promise => undef,
        syncNest => {
          sync => undef,
#          promise => undef,
        },
#        promiseNest => {
#          sync => undef,
#          promise => undef,
#        },
      },
#      promiseNest => {
#        sync => undef,
#        promise => undef,
#        syncNest => {
#          sync => undef,
#          promise => undef,
#        },
#        promiseNest => {
#          sync => undef,
#          promise => undef,
#        },
#      },
    },
  },
  {
    errors => bag(
      {
        message => "error\n",
        locations => [{ line => 5, column => 5 }],
        path => [qw(syncNest sync)],
      },
#      {
#        message => "error\n",
#        locations => [{ line => 7, column => 13 }],
#      },
      {
        message => "error\n",
        locations => [{ line => 8, column => 5 }],
        path => [qw(syncNest syncNest sync)],
      },
#      {
#        message => "error\n",
#        locations => [{ line => 16, column => 11 }],
#      },
#      {
#        message => "error\n",
#        locations => [{ line => 19, column => 13 }],
#      },
#      {
#        message => "error\n",
#        locations => [{ line => 23, column => 13 }],
#      },
#      {
#        message => "error\n",
#        locations => [{ line => 5, column => 11 }],
#      },
#      {
#        message => "error\n",
#        locations => [{ line => 8, column => 13 }],
#      },
#      {
#        message => "error\n",
#        locations => [{ line => 12, column => 13 }],
#      },
#      {
#        message => "error\n",
#        locations => [{ line => 17, column => 11 }],
#      },
#      {
#        message => "error\n",
#        locations => [{ line => 20, column => 13 }],
#      },
#      {
#        message => "error\n",
#        locations => [{ line => 24, column => 13 }],
#      },
    ),
  });
};

subtest 'nulls the first nullable object after a field in a long chain of non-null fields' => sub {
  my $doc = <<'EOF';
query Q {
  syncNest {
    syncNonNullNest {
#      promiseNonNullNest {
        syncNonNullNest {
#          promiseNonNullNest {
            syncNonNull
#          }
        }
#      }
    }
  }
#  promiseNest {
#    syncNonNullNest {
#      promiseNonNullNest {
#        syncNonNullNest {
#          promiseNonNullNest {
#            syncNonNull
#          }
#        }
#      }
#    }
#  }
#  anotherNest: syncNest {
#    syncNonNullNest {
#      promiseNonNullNest {
#        syncNonNullNest {
#          promiseNonNullNest {
#            promiseNonNull
#          }
#        }
#      }
#    }
#  }
#  anotherPromiseNest: promiseNest {
#    syncNonNullNest {
#      promiseNonNullNest {
#        syncNonNullNest {
#          promiseNonNullNest {
#            promiseNonNull
#          }
#        }
#      }
#    }
#  }
}
EOF
  check($doc, 1, {
    data => {
      syncNest => undef,
#      promiseNest => undef,
#      anotherNest => undef,
#      anotherPromiseNest => undef,
    },
    errors => [
      {
        message =>
            'Cannot return null for non-nullable field DataType.syncNonNull.',
        locations => [{ line=>9, column=>9 }],
        path => [qw(syncNest syncNonNullNest syncNonNullNest syncNonNull)],
      }
    ],
  },
  {
    errors => [
      {
        message => "nonNullError\n",
        locations => [{ line=>9, column=>9 }],
        path => [qw(syncNest syncNonNullNest syncNonNullNest syncNonNull)],
      },
#      {
#        message =>
#          "nonNullError\n",
#        locations => [{ line => 19, column => 19 }],
#      },
#      {
#        message =>
#          "nonNullError\n",
#        locations => [{ line => 30, column => 19 }],
#      },
#      {
#        message =>
#          "nonNullError\n",
#        locations => [{ line => 41, column => 19 }],
#      },
    ],
  });
};

subtest 'nulls the top level if non-nullable field' => sub {
  check('query Q { syncNonNull }', 0, {
    data => undef,
    errors => [
      {
        message =>
            'Cannot return null for non-nullable field DataType.syncNonNull.',
        locations => [{ line=>1, column=>23 }],
        path => [qw(syncNonNull)],
      }
    ],
  }, +{
    errors => [
      {
        message => "nonNullError\n",
        locations => [{ line=>1, column=>23 }],
        path => [qw(syncNonNull)],
      },
    ],
  });
};

done_testing;
