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

my $implementingType;
my $interfaceType = GraphQL::Type::Interface->new(
  name => 'Interface',
  fields => { fieldName => { type => 'GraphQLString' } },
  resolveType => sub {
    return $implementingType;
  },
);

$implementingType = GraphQL::Type::Object->new(
  name => 'Object',
  interfaces => [ $interfaceType ],
  fields => { fieldName => { type => 'GraphQLString', resolve => sub { '' } }},
);

my $schema = GraphQL::Schema->new(
  query => GraphQL::Type::Object->new(
    name => 'Query',
    fields => {
      getObject => {
        type => $interfaceType,
        resolve => sub {
          return {};
        }
      }
    }
  )
);

done_testing;
