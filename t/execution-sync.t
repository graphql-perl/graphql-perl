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
