use lib 't/lib';
use GQLTest;

my $JSON = JSON::MaybeXS->new->allow_nonref->canonical;

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution', qw(execute) ) || print "Bail out!\n";
}

subtest 'DateTime->now as resolve' => sub {
  require DateTime;
  my $schema = GraphQL::Schema->from_doc(<<'EOF');
type DateTimeObj { ymd: String }
type Query { dateTimeNow: DateTimeObj }
EOF
  my $now = DateTime->now;
  my $root_value = { dateTimeNow => sub { $now } };
  run_test([
    $schema, "{ dateTimeNow { ymd } }", $root_value, (undef) x 3, sub {
      my ($root_value, $args, $context, $info) = @_;
      my $field_name = $info->{field_name};
      my $property = ref($root_value) eq 'HASH'
        ? $root_value->{$field_name} 
        : $root_value;
      return $property->($args, $context, $info) if ref $property eq 'CODE';
      return $root_value->$field_name if ref $property; # no args
      $property;
    }
  ],
    { data => { dateTimeNow => { ymd => scalar $now->ymd } } },
  );
};

subtest 'DateTime type' => sub {
  require DateTime;
  my $schema = GraphQL::Schema->from_doc(<<'EOF');
type Query { dateTimeNow: DateTime }
EOF
  my $now = DateTime->now;
  my $root_value = { dateTimeNow => sub { $now } };
  run_test([ $schema, "{ dateTimeNow }", $root_value, (undef) x 3 ],
    { data => { dateTimeNow => $now.'' } },
  );
};

subtest 'nice errors Schema.from_ast' => sub {
  eval { GraphQL::Schema->from_ast([
    {
      'fields' => {
        'subtitle' => { 'type' => undef },
      },
      'kind' => 'type',
      'name' => 'Blog'
    },
    {
      'fields' => {
        'blog' => { 'type' => [ 'list', { 'type' => 'Blog' } ] },
      },
      'kind' => 'type',
      'name' => 'Query'
    },
  ]) };
  is $@, "Error in field 'subtitle': Undefined type given\n";
};

subtest 'test convert plugin' => sub {
  require_ok 'GraphQL::Plugin::Convert::Test';
  my $converted = GraphQL::Plugin::Convert::Test->to_graphql;
  run_test([
    $converted->{schema}, '{helloWorld}', $converted->{root_value}
  ],
    { data => { helloWorld => 'Hello, world!' } },
  );
};

subtest 'multi-line description' => sub {
  my $doc = <<'EOF';
type Query {
  # first line
  #
  # second bit
  hello: String
}
EOF
  my $got = eval { GraphQL::Schema->from_doc($doc)->to_doc };
  SKIP: {
    if ($@) {
      is ref($@) ? $@->message : $@, '';
      skip 1;
    }
    is $got, $doc;
  }
};

subtest 'list of enum as arg' => sub {
  my $schema = GraphQL::Schema->from_doc(<<'EOF');
enum E {
  available
  pending
}

type Query {
  hello(arg: [E]): String
}
EOF
  run_test([
    $schema, '{hello(arg: [available])}', {
      hello => sub { 'Hello, '.shift->{arg}[0] }
    }
  ],
    { data => { hello => 'Hello, available' } },
  );
};

subtest 'arbitrary object as exception' => sub {
  {
    package MyException;
    use overload '""' => sub { join ' ', @{ $_[0] } };
    sub new { my $class = shift; bless [ @_ ], $class; }
  }
  my $schema = GraphQL::Schema->from_doc(<<'EOF');
type Query {
  hello(arg: String): String
}
EOF
  run_test([
    $schema, '{hello(arg: "Hi")}', {
      hello => sub { die MyException->new(qw(oh no)) }
    }
  ], {
    'data' => { 'hello' => undef },
    'errors' => [
      {
        'locations' => [ { 'column' => 18, 'line' => 1 } ],
        'message' => 'oh no',
        'path' => [ 'hello' ],
      },
    ],
  });
};

done_testing;
