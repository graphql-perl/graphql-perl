use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  use_ok( 'GraphQL::Type::Interface' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Scalar', qw($String) ) || print "Bail out!\n";
}

my $implementing_type;
my $interface_type = GraphQL::Type::Interface->new(
  name => 'Interface',
  fields => { field_name => { type => $String } },
  resolve_type => sub {
    return $implementing_type;
  },
);

$implementing_type = GraphQL::Type::Object->new(
  name => 'Object',
  interfaces => [ $interface_type ],
  fields => { field_name => { type => $String, resolve => sub { '' } }},
);

my @schema_args = (
  query => GraphQL::Type::Object->new(
    name => 'Query',
    fields => {
      getObject => {
        type => $interface_type,
        resolve => sub {
          return {};
        }
      }
    }
  )
);
my $schema = GraphQL::Schema->new(@schema_args);
throws_ok {
  $schema->is_possible_type($interface_type, $implementing_type)
} qr/not find possible implementing/, 'readable error if no types given';

$schema = GraphQL::Schema->new(@schema_args, types => [ $implementing_type ]);
lives_and {
  ok $schema->is_possible_type($interface_type, $implementing_type)
} 'no error if types given';

done_testing;
