#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok( 'GraphQL::Type::Interface' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
}

my $implementing_type;
my $interface_type = GraphQL::Type::Interface->new(
  name => 'Interface',
  fields => { fieldName => { type => 'GraphQLString' } },
  resolve_type => sub {
    return $implementing_type;
  },
);

$implementing_type = GraphQL::Type::Object->new(
  name => 'Object',
  interfaces => [ $interface_type ],
  fields => { fieldName => { type => 'GraphQLString', resolve => sub { '' } }},
);

my $schema = GraphQL::Schema->new(
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

done_testing;
