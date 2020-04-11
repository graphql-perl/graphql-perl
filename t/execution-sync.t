use lib 't/lib';
use strict;
use warnings;
use GQLTest;

my $JSON = JSON::MaybeXS->new->allow_nonref->canonical;

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution', qw(execute) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Scalar', qw($String) ) || print "Bail out!\n";
}

my $schema = GraphQL::Schema->new(
  query => GraphQL::Type::Object->new(
    name => 'Query',
    fields => {
      syncField => {
        type => $String,
        resolve => sub {
          $_[0];
        }
      },
      asyncField => {
        type => $String,
        resolve => sub {
          my ($root_value, $args, $context, $info) = @_;
          $info->{promise_code}{resolve}->($root_value);
        }
      },
    }
  ),
);

subtest 'test the tests' => sub {
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
  is !!$p->settled, '';
  $p->resolve('hi');
  promise_test($p, ["hi"], "");
};

subtest 'does not return a Promise for initial errors' => sub {
  run_test([
    $schema, "fragment Example on Query { syncField }", 'rootValue',
  ], +{ errors => [ {
    message => "No operations supplied.\n",
  } ] }, 0);
};

subtest 'does not return a Promise if fields are all synchronous' => sub {
  run_test([
    $schema, "query Example { syncField }", 'rootValue',
  ], +{ data => { syncField => 'rootValue' } }, 0);
};

subtest 'returns a Promise if any field is asynchronous' => sub {
  run_test([
    $schema, "query Example { asyncField }", 'rootValue',
  ], +{ data => { asyncField => 'rootValue' } }, 1);
};

done_testing;
