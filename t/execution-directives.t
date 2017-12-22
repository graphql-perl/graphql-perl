use lib 't/lib';
use GQLTest;

my $JSON = JSON::MaybeXS->new->allow_nonref->canonical;

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Scalar', qw($String $Int $Boolean) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution', qw(execute) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Language::Parser', qw(parse) ) || print "Bail out!\n";
}

my $schema = GraphQL::Schema->new(
  query => GraphQL::Type::Object->new(
    name => 'TestType',
    fields => {
      a => { type => $String },
      b => { type => $String },
    },
  ),
);

my %data = (
  a => sub { 'a' },
  b => sub { 'b' },
);

subtest 'works without directives' => sub {
  run_test([$schema, '{ a, b }', \%data], { data => { a => 'a', b => 'b' } });
};

subtest 'works on scalars' => sub {
  run_test([$schema, '{ a, b @include(if: true) }', \%data],
    { data => { a => 'a', b => 'b' } });

  run_test([$schema, '{ a, b @include(if: false) }', \%data],
    { data => { a => 'a' } });

  run_test([$schema, '{ a, b @skip(if: false) }', \%data],
    { data => { a => 'a', b => 'b' } });

  run_test([$schema, '{ a, b @skip(if: true) }', \%data],
    { data => { a => 'a' } });
};

subtest 'works on fragment spreads' => sub {
  my $q;

  $q = <<'EOQ';
query Q {
  a
  ...Frag @include(if: false)
}
fragment Frag on TestType {
  b
}
EOQ
  run_test([$schema, $q, \%data], { data => { a => 'a' } });

  $q = <<'EOQ';
query Q {
  a
  ...Frag @include(if: true)
}
fragment Frag on TestType {
  b
}
EOQ
  run_test([$schema, $q, \%data], { data => { a => 'a', b => 'b' } });

  $q = <<'EOQ';
query Q {
  a
  ...Frag @skip(if: false)
}
fragment Frag on TestType {
  b
}
EOQ
  run_test([$schema, $q, \%data], { data => { a => 'a', b => 'b' } });

  $q = <<'EOQ';
query Q {
  a
  ...Frag @skip(if: true)
}
fragment Frag on TestType {
  b
}
EOQ
  run_test([$schema, $q, \%data], { data => { a => 'a' } });
};

subtest 'works on inline fragment' => sub {
  my $q;

  $q = <<'EOQ';
query Q {
  a
  ... on TestType @include(if: false) {
    b
  }
}
EOQ
  run_test([$schema, $q, \%data], { data => { a => 'a' } });

  $q = <<'EOQ';
query Q {
  a
  ... on TestType @include(if: true) {
    b
  }
}
EOQ
  run_test([$schema, $q, \%data], { data => { a => 'a', b => 'b' } });

  $q = <<'EOQ';
query Q {
  a
  ... on TestType @skip(if: false) {
    b
  }
}
EOQ
  run_test([$schema, $q, \%data], { data => { a => 'a', b => 'b' } });

  $q = <<'EOQ';
query Q {
  a
  ... on TestType @skip(if: true) {
    b
  }
}
EOQ
  run_test([$schema, $q, \%data], { data => { a => 'a' } });
};

subtest 'works on anonymous inline fragment' => sub {
  my $q;

  $q = <<'EOQ';
query Q {
  a
  ... @include(if: false) {
    b
  }
}
EOQ
  run_test([$schema, $q, \%data], { data => { a => 'a' } });

  $q = <<'EOQ';
query Q {
  a
  ... @include(if: true) {
    b
  }
}
EOQ
  run_test([$schema, $q, \%data], { data => { a => 'a', b => 'b' } });

  $q = <<'EOQ';
query Q {
  a
  ... @skip(if: false) {
    b
  }
}
EOQ
  run_test([$schema, $q, \%data], { data => { a => 'a', b => 'b' } });

  $q = <<'EOQ';
query Q {
  a
  ... @skip(if: true) {
    b
  }
}
EOQ
  run_test([$schema, $q, \%data], { data => { a => 'a' } });
};

subtest 'works with skip and include directives' => sub {
  run_test([$schema, '{ a, b @include(if: true) @skip(if: false) }', \%data],
    { data => { a => 'a', b => 'b' } });

  run_test([$schema, '{ a, b @include(if: true) @skip(if: true) }', \%data],
    { data => { a => 'a' } });

  run_test([$schema, '{ a, b @include(if: false) @skip(if: false) }', \%data],
    { data => { a => 'a' } });
};

done_testing;
