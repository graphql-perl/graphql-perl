#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;

BEGIN {
plan skip_all => 'work in progress';
  use_ok( 'GraphQL::Type' ) || print "Bail out!\n";
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

my $schema = new GraphQL::Schema(
  query => new GraphQLObjectType(
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
