#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok( 'GraphQL::Type::Interface' ) || print "Bail out!\n";
}

my $implementingType;
my $interfaceType = GraphQL::Type::Interface->new(
  name => 'Interface',
  fields => { fieldName => { type => 'GraphQLString' } },
  resolveType => sub {
    return $implementingType;
  },
);

done_testing;
