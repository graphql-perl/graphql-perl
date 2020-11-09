use strict;
use warnings;
use lib 't/lib';
use GQLTest;

my $JSON = JSON::MaybeXS->new->allow_nonref->canonical;

use GraphQL::Schema;
use GraphQL::Execution qw(execute);
use GraphQL::Subscription qw(subscribe);
use GraphQL::Type::Scalar qw($Int $Float $String $Boolean);
use GraphQL::Type::InputObject;
use GraphQL::Type::Object;
use GraphQL::Type::Interface;

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
  my $converted = GraphQL::Plugin::Convert::Test->to_graphql(
    sub {
      my $text = $_[1]->{s};
      my $ai = fake_promise_iterator();
      $ai->publish({ timedEcho => $text });
      $ai;
    },
  );
  run_test([
    $converted->{schema}, '{helloWorld}', $converted->{root_value}
  ],
    { data => { helloWorld => 'Hello, world!' } },
  );
  run_test([
    $converted->{schema},
    'mutation m($s: String = "yo") { echo(s: $s) }',
    $converted->{root_value},
    undef,
    { s => "hi" },
  ],
    { data => { echo => 'hi' } },
  );
  my $ai = subscribe(
    $converted->{schema},
    'subscription s { timedEcho(s: "argh") }',
    $converted->{root_value},
    (undef) x 4, fake_promise_code(),
    $converted->{subscribe_resolver},
  );
  $ai = $ai->get;
  promise_test($ai->next_p, [{ data => { timedEcho => 'argh' } }], '');
};

subtest 'multi-line description' => sub {
  my $doc = <<'EOF';
type Query {
  """
  first line

  second bit
  """
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

subtest 'non-nullable enum as arg' => sub {
  my $schema = GraphQL::Schema->from_doc(<<'EOF');
enum E {
  available
  pending
}

type Query {
  hello(arg: E!): String
}
EOF
  run_test([
    $schema, '{hello(arg: available)}', {
      hello => sub { 'Hello, '.shift->{arg} }
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

subtest 'mutations in order' => sub {
  my $schema = GraphQL::Schema->from_doc(<<'EOF');
type Query { q: String }
type Mutation {
  hello(arg: String): String
}
EOF
  my @m;
  run_test([
    $schema, <<'EOF',
mutation m {
  h1: hello(arg: "Hi")
  h2: hello(arg: "Hi2")
}
EOF
    { hello => sub { push @m, $_[0]{arg}; $_[0]{arg} } }
  ], {
    'data' => { h1 => "Hi", h2 => "Hi2" },
  });
  is_deeply \@m, [ qw(Hi Hi2) ];
};

subtest 'list in query params' => sub {
  my $stringlist = GraphQL::Type::List->new(of => $String);
  is $stringlist->is_valid([ 'string' ]), 1, 'is_valid works';
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Query',
      fields => {
        hello => {
          type => $String,
          args => { arg => { type => $stringlist } }
        },
      }
    ),
  );
  run_test([
    $schema, 'query q($a: [String]) {hello(arg: $a)}', { hello => "yo" },
    undef, { a => [ 'there' ] },
  ], {
    'data' => { 'hello' => "yo" },
  });
};

subtest 'list/inputobject default value in Perl' => sub {
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Query',
      fields => {
        hello => {
          type => $String,
          args => { arg => { type => $String->list, default_value => ["yo"] } }
        },
        field2 => {
          type => $String,
          args => {
            f2arg => {
              type => GraphQL::Type::InputObject->new(
                name => 'TestInputObject',
                fields => {
                  b => { type => $String->list },
                },
              ),
              default_value => { b => 'b' },
            },
          },
        },
      }
    ),
  );
  lives_ok { $schema->to_doc } 'can get SDL ok';
  run_test([
    $schema, 'query q($a: [String]) {hello(arg: $a)}',
    { hello => sub { $_[0]->{arg}[0] } },
  ], {
    'data' => { 'hello' => "yo" },
  });
};

subtest 'input object with null value' => sub {
  my $schema = GraphQL::Schema->from_doc(<<'EOF');
enum E1 { A, B }
enum E2 { C, D }
input TestInput { f1: E1, f2: E2 }
type Query { hello(arg: TestInput): String }
EOF
  run_test([
    $schema, 'query q($a: TestInput) {hello(arg: $a)}', { hello => "yo" },
    undef, { a => { f1 => 'A' } },
  ], {
    'data' => { 'hello' => "yo" },
  });
};

subtest 'errors on incorrect query input', sub {
  my $doc = '
    query q($id: String) {
      fieldWithObjectInput(input: { id: $id })
    }';
  my $TestInputObject = GraphQL::Type::InputObject->new(
    name => 'TestInputObject',
    fields => {
      a => { type => $String },
      b => { type => $String->list },
      c => { type => $String->non_null },
    },
  );
  my $TestType = GraphQL::Type::Object->new(
    name => 'TestType',
    fields => {
      fieldWithObjectInput => {
        type => $String,
        args => { input => { type => $TestInputObject } },
        resolve => sub { $_[1]->{input} && $JSON->encode($_[1]->{input}) },
      },
    },
  );
  my $schema = GraphQL::Schema->new(query => $TestType);
  run_test(
    [$schema, $doc],
    {
      data => { fieldWithObjectInput => undef },
      errors => [ { message =>
      q{Argument 'input' got invalid value {"id":null}.}
      ."\n"."Expected 'TestInputObject'.\nIn field \"id\": Unknown field.\n",
      locations => [{ column => 5, line => 4 }],
      path => ['fieldWithObjectInput'],
    } ] },
  );
};

subtest 'test _debug', sub {
  require GraphQL::Debug;
  my @diags;
  {
    no warnings 'redefine';
    local *Test::More::diag = sub { push @diags, @_ };
    GraphQL::Debug::_debug('message', +{ key => 1 });
  }
  is_deeply \@diags, ['message: ', <<EOF], 'debug output correct' or diag explain \@diags;
{
  'key' => 1
}
EOF
};

subtest 'test String.is_valid' => sub {
  is $String->is_valid('string'), 1, 'is_valid works';
};

subtest 'test Scalar methods' => sub {
  my $scalar = GraphQL::Type::Scalar->from_ast({}, { name => 's', description => 'd' });
  throws_ok { $scalar->serialize->('string') } qr{Fake}, 'fake serialize';
  throws_ok { $scalar->parse_value->('string') } qr{Fake}, 'fake parse_value';
  is $scalar->to_doc, qq{"d"\nscalar s\n}, 'to_doc';
  is $Boolean->serialize->(1), 1, 'Boolean serialize';
  is $Boolean->serialize->(JSON->true), 1, 'Boolean serialize blessed';
  is $Boolean->parse_value->(JSON->true), 1, 'Boolean parse_value';
  for my $type ($Int, $Float, $String, $Boolean) {
    is $type->$_->(undef), undef, join(' ', $type->name, $_, 'null')
      for qw(serialize parse_value);
  }
};

subtest 'exercise __type root field more'=> sub {
  my $TestType = GraphQL::Type::Object->new(
    name => 'TestType',
    fields => {
      testField => {
        type => $String,
      }
    }
  );
  my $abstract = GraphQL::Type::Interface->new(
    name => 'i',
    fields => {
      testField => {
        type => $String,
      }
    }
  );

  my $schema = GraphQL::Schema->new(query => $TestType, types => [$abstract]);
  my $request = <<'EOQ';
{
  __type(name: "TestType") {
    name
    kind
    fields {
      name
    }
    interfaces
  }
  i: __type(name: "i") {
    name
    possibleTypes
  }
}
EOQ

  run_test([$schema, $request], {
    data => {
      __type => {
        fields => [
          {
            name => 'testField'
          },
        ],
        interfaces => [],
        kind => 'OBJECT',
        name => 'TestType',
      },
      i => {
        name => 'i',
        possibleTypes => [],
      }
    }
  });
};

subtest 'test List->name' => sub {
  my $stringlist = GraphQL::Type::List->new(of => $String);
  is $stringlist->name, 'String';
};

subtest 'test multi selection with same name' => sub {
  require DateTime;
  my $schema = GraphQL::Schema->from_doc(<<'EOF');
type DateTimeObj { ymd: String dmy: String }
type Query { dateTimeNow: DateTimeObj }
EOF
  my $now = DateTime->now;
  my $root_value = { dateTimeNow => sub { $now } };
  run_test([
    $schema, "{ dateTimeNow { ymd } dateTimeNow { dmy } }", $root_value, (undef) x 3, sub {
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
    { data => { dateTimeNow => {
      ymd => scalar $now->ymd,
      dmy => scalar $now->dmy,
    } } },
  );
};

subtest 'literal input object with $var as value' => sub {
  my $schema = GraphQL::Schema->from_doc(<<'EOF');
input AuditFilter {
  resource: String
  resource_id: String
}

type Query {
  allAudits(filter: AuditFilter): String
}
EOF
  my $now = DateTime->now;
  my $root_value = { allAudits => 'yo' };
  run_test([
    $schema,
    'query q($device: String!) { allAudits(filter: {resource: "device", resource_id: $device}) }',
    $root_value, undef,
    { device => 'e0c05156-c623-459d-9535-f645fdd04f3c' },
  ],
    { data => $root_value },
  );
};

subtest 'error objects stringify' => sub {
  my $msg = 'Something is not right...';
  my $error = GraphQL::Error->new(message => $msg);
  is $error.'', $msg;
};

subtest 'fake promises' => sub {
  my $p = FakePromise->resolve('yo');
  promise_test($p, ['yo'], '');
  $p = FakePromise->resolve('yo')->then(sub { shift . 'ga' });
  is $p->get, 'yoga';
  is $p->get, 'yoga'; # check can re-get
  $p = FakePromise->reject("yo\n");
  promise_test($p, [], "yo\n");
  $p = FakePromise->reject("f\n")->catch(sub { shift });
  promise_test($p, ["f\n"], "");
  $p = FakePromise->resolve("yo\n")->then(sub { die shift });
  promise_test($p, [], "yo\n");
  $p = FakePromise->reject("f\n")->catch(sub { shift })->then(sub { die shift });
  promise_test($p, [], "f\n");
  $p = FakePromise->resolve("yo\n")->then(sub { die shift })->catch(sub { shift });
  promise_test($p, ["yo\n"], "");
  $p = FakePromise->resolve('yo')->then(sub { FakePromise->resolve('y2') });
  promise_test($p, ["y2"], "");
  $p = FakePromise->resolve("s\n")->then(sub { FakePromise->reject(shift) });
  promise_test($p, [], "s\n");
  $p = FakePromise->resolve("s\n")->then(sub { FakePromise->reject(shift) })->catch(sub { shift });
  promise_test($p, ["s\n"], "");
  $p = FakePromise->all(FakePromise->reject("s\n"))->catch(sub { shift });
  promise_test($p, ["s\n"], "");
  $p = FakePromise->all('hi', FakePromise->resolve("yo"))->then(sub {
    map @$_, @_
  });
  promise_test($p, [qw(hi yo)], "");
  $p = FakePromise->all(
    'hi',
    FakePromise->resolve("yo")->then(sub { "$_[0]!" }),
  )->then(sub { map ucfirst $_->[0], @_ }),;
  promise_test($p, [qw(Hi Yo!)], "");
  $p = FakePromise->all(
    FakePromise->resolve("hi")->then(sub { "$_[0]!" }),
    FakePromise->resolve("yo")->then(sub { "$_[0]!" }),
  )->then(sub { map ucfirst $_->[0], @_ }),;
  promise_test($p, [qw(Hi! Yo!)], "");
  $p = FakePromise->all(
    FakePromise->all(
      FakePromise->reject("yo\n")->then(
        # simulates rejection that will skip first "then"
        sub { "$_[0]/" }
      )->then(
        # first catch
        undef,
        sub { die "$_[0]!\n" },
      )->then(
        # second catch
        undef,
        sub { die ">$_[0]" },
      ),
    ),
  )->then(undef, sub { map "^$_", @_ }),;
  promise_test($p, ["^>yo\n!\n"], "");
  $p = FakePromise->new;
  is $p->status, undef;
  $p->resolve('hi');
  promise_test($p, ["hi"], "");
  $p = FakePromise->new;
  my $flag;
  my $p2 = $p->then(sub { $flag = $_[0].'!' });
  $p->resolve('hi');
  is $flag, "hi!", 'appended then gets run on settling, not get';
  promise_test($p2, ["hi!"], "");
  $p2 = FakePromise->new;
  $p = FakePromise->all($p2);
  $p2->resolve('hi');
  promise_test($p, [["hi"]], "");
  $p2 = FakePromise->new;
  $p = FakePromise->all($p2);
  $p2->reject("hi\n");
  promise_test($p, [], "hi\n");
  $p = FakePromise->resolve(FakePromise->reject("yo\n"))->then(
    sub { "replaced by then" },
    sub { "replaced by catch" },
  );
  promise_test($p, ["replaced by catch"], "");
  $p = FakePromise->all(FakePromise->resolve("hi"), 'there');
  promise_test($p, [map [$_], qw(hi there)], "");
};

subtest 'pubsub' => sub {
  require GraphQL::PubSub;
  my $pubsub = GraphQL::PubSub->new;
  my ($flag1, @flag2);
  my $cb1 = sub { $flag1 = $_[0] };
  my $cb2 = sub { @flag2 = @_ };
  $pubsub->subscribe('channel1', $cb1);
  $pubsub->subscribe('channel1', $cb2);
  $pubsub->publish('channel1', 1);
  is $flag1, 1, 'cb1 received first publish';
  is_deeply \@flag2, [ 1 ], 'cb2 received first publish';
  $pubsub->unsubscribe('channel1', $cb1);
  $pubsub->publish('channel1', 2);
  is $flag1, 1, 'cb1 did not receive second publish';
  is_deeply \@flag2, [ 2 ], 'cb2 still received second publish';
  $pubsub->subscribe('channel2', $cb1);
  $pubsub->publish('channel1', 3);
  is $flag1, 1, 'cb1 did not receive third publish';
  is_deeply \@flag2, [ 3 ], 'cb2 still received third publish';
  my $normal_cb_counter = 0;
  my $normal_cb = sub { $normal_cb_counter++; die "aiiee" if $_[0] eq 'die' };
  $pubsub->subscribe('errors', $normal_cb);
  is_deeply [ $normal_cb_counter ], [ 0 ], 'init state';
  $pubsub->publish('errors', 'live');
  is_deeply [ $normal_cb_counter ], [ 1 ], 'normal';
  $pubsub->publish('errors', 'die');
  is_deeply [ $normal_cb_counter ], [ 2 ], 'call with an exception';
  $pubsub->publish('errors', 'live');
  is_deeply [ $normal_cb_counter ], [ 2 ], 'got unsubscribed so normal not run';
  $normal_cb_counter = 0;
  my $error_cb_called;
  my $error_cb = sub { $error_cb_called = 1 };
  $pubsub->subscribe('errors', $normal_cb, $error_cb);
  is_deeply [ $normal_cb_counter, $error_cb_called ], [ 0, undef ], 'init state';
  $pubsub->publish('errors', 'live');
  is_deeply [ $normal_cb_counter, $error_cb_called ], [ 1, undef ], 'normal';
  $pubsub->publish('errors', 'die');
  is_deeply [ $normal_cb_counter, $error_cb_called ], [ 2, 1 ], 'error_cb called';
};

subtest 'asynciterator' => sub {
  my $ai = fake_promise_iterator();
  my $promised_value = $ai->next_p;
  $ai->publish('hi');
  promise_test($promised_value, ["hi"], "");
  $ai->publish('yo');
  promise_test($ai->next_p, ["yo"], "");
  $ai->publish(1);
  $ai->publish(2);
  promise_test($ai->next_p, [1], "");
  promise_test($ai->next_p, [2], "");
  $ai->publish(3);
  $ai->error("9\n");
  $ai->publish(4);
  promise_test($ai->next_p, [3], "");
  promise_test($ai->next_p, [], "9\n");
  my ($callcount1, $callcount2) = (0, 0);
  $ai->map_then(sub { $callcount1++; $_[0] + 100 });
  promise_test($ai->next_p, [104], "");
  is_deeply [ $callcount1, $callcount2 ], [ 1, 0 ];
  $promised_value = $ai->next_p;
  $ai->map_then(sub { $callcount2++; $_[0] * 2 });
  $ai->publish(5);
  is_deeply [ $callcount1, $callcount2 ], [ 2, 0 ];
  promise_test($promised_value, [105], "");
  $ai->publish(6);
  promise_test($ai->next_p, [212], "");
  is_deeply [ $callcount1, $callcount2 ], [ 3, 1 ];
  $ai->publish(7);
  promise_test($ai->next_p, [214], "");
  is_deeply [ $callcount1, $callcount2 ], [ 4, 2 ];
  $ai->close_tap;
  is $ai->next_p, undef;
  throws_ok { $ai->publish(6) } qr{closed}, 'publish to closed off';
};

done_testing;
