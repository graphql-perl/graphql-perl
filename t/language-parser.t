#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok( 'GraphQL::Parser' ) || print "Bail out!\n";
}

my $implementingType;
my $interfaceType = GraphQL::Parser->parse(
  '{',
);

done_testing;
