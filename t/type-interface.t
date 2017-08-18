#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  use_ok( 'GraphQL::Type::Interface' ) || print "Bail out!\n";
}

my $implementingType;
my $interfaceType = GraphQL::Type::Interface->new(
  name => 'Interface',
  fields => { fieldName => { type => 'GraphQLString' } },
  resolve_type => sub {
    return $implementingType;
  },
);

throws_ok {
  GraphQL::Type::Interface->new(
    name => '@Interface',
    fields => { fieldName => { type => 'GraphQLString' } },
  )
} qr/did not pass type constraint/, 'name validation';

done_testing;
